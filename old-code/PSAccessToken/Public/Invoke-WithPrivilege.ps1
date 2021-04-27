# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Invoke-WithPrivilege {
    <#
    .SYNOPSIS
    Invokes the scriptblock with the privileges required.

    .DESCRIPTION
    Invokes a scriptblock as the current user but with extra or just specific privileges. This can run with privileges
    that are not currently assigned to the current user.

    .PARAMETER Privilege
    A privilege or list of privileges to run the scriptblock with. These privileges will be Enabled automatically when
    the scriptblock is run.

    .PARAMETER ScriptBlock
    Specifies the commands to run. Enclose the commands in braces ( { } ) to create a script block. This parameter is
    required.

    .PARAMETER InputObject
    Specifies input to the command. Enter a variable that contains the objects or type a command or expression that
    gets the objects.

    .PARAMETER ArgumentList
    Supplies the values of local variables in the command as supplied by scriptblock params.

    .PARAMETER ClearExistingPrivileges
    Will run the scriptblock with only the privileges specified, this will not have any of the existing privileges of
    the current access token unless they are set in the -Privilege parameter.

    .EXAMPLE Call New-AccessToken with the required privilege
    $token = Invoke-WithPrivilege -Privilege SeCreateTokenPrivilege -ScriptBlock {
        New-AccessToken -User 'Administrator' -Groups 'Administrators' -Privileges 'SeTcbPrivilege'
    }
    Get-TokenGroups -Token $token
    $token.Dispose()

    .EXAMPLE Logon a user without a password with the required privilege
    $logon = Invoke-WithPrivilege -Privilege SeTcbPrivilege -ScriptBlock {
        Invoke-LogonUser -Username 'Administrator' -Password $null
    }
    Get-TokenUser -Token $logon.Token
    $logon.Token.Dispose()

    .EXAMPLE Get the linked token of a primary type
    $linked_token = Invoke-WithPrivilege -Privilege SeTcbPrivilege -ScriptBlock {
        Get-TokenLinkedToken -UseProcessToken
    }
    Get-TokenElevationType -Token $linked_token
    $linked_token.Dispose()

    .NOTES
    This cmdlet works by creating a temporary admin account with the SeCreateTokenPrivilege. This account is then
    logged on and used to create a copy of the existing access token with the privileges specified. Finally the new
    account is impersonated and the scriptblock is run.

    This cmdlet is mostly a way to easily run a PowerShell script with privileges that may not already be assigned to
    the current user. This allows us to do things like enable the SeTcbPrivilege, or SeCreateTokenPrivilege which isn't
    typically given out to any user. These privileges are quite useful in this library as it allows you to create your
    own tokens, or log users on without passwords.
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSAvoidUsingConvertToSecureStringWithPlainText", "",
        Justification="The password is a temp password for a local user"
    )]
    Param (
        [Parameter(Mandatory=$true, Position=0)]
        [System.String[]]
        $Privilege,

        [Parameter(Mandatory=$true, Position=1)]
        [ScriptBlock]
        $ScriptBlock,

        [PSObject]
        $InputObject,

        [Object[]]
        $ArgumentList,

        [Switch]
        $ClearExistingPrivileges
    )

    # Create a new admin account, add a random suffix to pad the account name to 20 chars (0-9, A-Z, a-z)
    $acct_suffix = ((48..57) + (65..90) + (97..122) | Get-Random -Count 6 | ForEach-Object -Process { [Char]$_ }) -join ""

    Add-Type -AssemblyName System.Web
    $temp_password = [System.Web.Security.Membership]::GeneratePassword(127, (Get-Random -Minimum 1 -Maximum 120))

    $adsi = [ADSI]"WinNT://$env:COMPUTERNAME"
    $user_obj = $adsi.Create('User', "PSAccessToken-$acct_suffix")
    $user_obj.UserFlags = 64 -bor 65536  # ADS_UF_PASSWORD_CANT_CHANGE, ADS_UF_DONT_EXPIRE_PASSWD
    $user_obj.SetPassword($temp_password) > $null
    $user_obj.SetInfo() > $null

    try {
        $temp_sid_bytes = $user_obj.InvokeGet('objectSID')
        $temp_sid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList @(
            $temp_sid_bytes, 0
        )

        # Add to the Administrators group
        $admin_sid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList @(
            [System.Security.Principal.WellKnownSidType]::BuiltinAdministratorsSid,
            $null
        )
        $grp_obj = $adsi.Children | Where-Object {
            if ($_.SchemaClassName -ne 'Group') {
                return $false
            }
            $grp_sid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList @(
                $_.InvokeGet('objectSID'), 0
            )
            $grp_sid -eq $admin_sid
        }
        $grp_obj.Add($user_obj.Path) > $null

        # So .Dispose() doesn't explode on us on failure conditions, temporary set it to an invalid handle
        $priv_token = New-Object -TypeName PInvokeHelper.SafeNativeHandle
        try {
            try {
                $priv_token = Use-LsaPolicy -Access CreateAccount, LookupNames -Process {
                    Param ([System.IntPtr]$LsaHandle)

                    # Add the SeCreateTokenPrivilege to the temp account
                    Add-WindowsRight -LsaHandle $LsaHandle -SidBytes $temp_sid_bytes -Name SeCreateTokenPrivilege

                    try {
                        # Log on the account and get a handle to its access token.
                        $temp_password_ss = ConvertTo-SecureString -String $temp_password -AsPlainText -Force
                        $logon = Invoke-LogonUser -Username $temp_sid -Password $temp_password_ss -LogonType Batch

                        try {
                            # Build the new access token for the current user with the privileges required.
                            if ($ClearExistingPrivileges) {
                                $privileges = $Privilege
                            } else {
                                $privileges = @(Get-TokenPrivileges) + $Privilege
                            }
                            $new_token_params = @{
                                User = (Get-TokenUser)
                                Groups = (Get-TokenGroups)
                                Privileges = $privileges
                                Owner = (Get-TokenOwner)
                                PrimaryGroup = (Get-TokenPrimaryGroup)
                                DefaultDacl = (Get-TokenDefaultDacl)
                                ImpersonationLevel = [System.Security.Principal.TokenImpersonationLevel]::None
                                LogonId = (Get-TokenStatistics).AuthenticationId
                            }

                            # Creates the access token with our temporary privileged account. This will output the
                            # token and because this is running in a scriptblock will be set to $priv_token further up.
                            Invoke-WithImpersonation -Token $logon.Token -ScriptBlock {
                                New-AccessToken @new_token_params
                            }
                        } finally {
                            $logon.Token.Dispose()
                        }
                    } finally {
                        Remove-WindowsRight -LsaHandle $LsaHandle -SidBytes $temp_sid_bytes
                    }
                }
            } finally {
                $grp_obj.Remove($user_obj.Path) > $null
            }
        } finally {
            $adsi.Delete('User', $user_obj.Name.Value) > $null
        }

        # Finally invoke the scriptblock with the newly created token.
        $PSBoundParameters.Remove('Privilege') > $null
        $PSBoundParameters.Remove('ClearExistingPrivileges') > $null
        Invoke-WithImpersonation -Token $priv_token @PSBoundParameters
    } finally {
        $priv_token.Dispose()
    }
}