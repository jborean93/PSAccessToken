# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Invoke-LogonUser {
    <#
    .SYNOPSIS
    Logs a user through LSA and returns a logon token and other info.

    .DESCRIPTION
    Can be used to log a user onto the Windows box and then return an access token alongside other information for
    further use. Supports the following scenarios;

        * Logon with username and password for local and domain accounts.
        * Logon with just a username for local and domain accounts.
        * Logon to service accounts; 'Network Service', 'Local Service', 'System'

    The last 2 scenarios require the caller to have the SeTcbPrivilege privilege.

    .PARAMETER Username
    The username to log on, this is mutually exclusive with -Credential.

    .PARAMETER Password
    The password to use with the logon, this is mutually exclusive with -Credential. Set to $null to log on the user
    without a password (requires SeTcbPrivilege).

    .PARAMETER Credential
    A credential object that defines the user to log on and the password to use. This is mutually exclusive with
    -Username and -Password.

    .PARAMETER LogonType
    The logon type to use, can be;

        * Interactive (Default with Password): An interactive logon, replicates logging on through the console or RDP.
        * Batch (Default with no Password): A batch logon, replicates logging on as a scheduled task.
        * Network: A network logon, replicates logging on through a network process, e.g. WinRM, SMB.
        * NetworkCleartext: Like Network but the credentials are cached for double hop authentications.
        * Service (Default for service account): A service logon, replicates logging on as a Windows service.
        * NewCredentials: Creates a copy of the existing token but all outbound authentication attempts will use the new credentials.

    When using a service account like 'Network Service', 'Local Service', or 'System'; the Service LogonType will
    automatically be used.

    When logging on without a password, only a Batch or Network logon can be used.

    Each logon type (except NewCredentials) requires the appropriate user right, like SeInteractiveLogonRight to be
    applied to the account that is being logged on.

    .PARAMETER Groups
    Add further groups to the new access token. This requires the caller to have the SeTcbPrivilege set. Each group
    entry can either be the name of the group to add or a Hashtable with the following keys;
        Sid: The name or SID of the group to add (This is mandatory)
        Attributes: The PSAccessToken.TokenGroupAttributes flags to set with the group (Default to 'EnabledByDefault', 'Enabled', and 'Mandatory')

    .PARAMETER OriginName
    Sets the origin name for audit logging. The first 8 chars will also be set as the TOKEN_SOURCE on the access token.

    .PARAMETER AuthenticationPackage
    Override the authentication package that is used, by default it is 'Negotiate'.

    .OUTPUTS
    [PSAccessToken.LogonInfo]
        Token: The access token for the new user, it is recommended to call .Dispose() once this is no longer needed.
        Username: The username used in the logon process.
        Domain: The domain name used in the logon process.
        LogonType: The logon type used in the logon process.
        LogonId: The LSA Logon ID that represents the locally unique identifier of the logon session.
        Profile: An object that returns specific profile info from LSA. The properties returned here are dependent on the type of logon that was performed.
        PagedPoolLimit: Amount of paged pool memory assigned to the user.
        NonPagedPoolLimit: Amount of non paged pool memory assigned to the user.
        MinimumWorkingSetSize: The minimum set size assigned to the user.
        MaximumWorkingSetSize: The maximum set size assigned to the user.
        PagefileLimit: THe maximum size, in bytes, of the paging file.
        TimeLimit: Maximum amount of time a process can run.

    .EXAMPLE Log user on with Credential
    $cred = Get-Credential
    $logon = Invoke-LogonUser -Credential $cred
    $logon.Token.Dispose()

    .EXAMPLE Log user on with username/password
    $logon = Invoke-LogonUser -Username Administrator -Password $secure_string
    $logon.Token.Dispose()

    .EXAMPLE Log on user without password
    $logon = Invoke-LogonUser -Username 'DOMAIN\account'
    $logon.Token.Dispose()

    .EXAMPLE Log on service account
    $logon = Invoke-LogonUser -Username 'Network Service'
    $logon.Token.Dispose()

    .EXAMPLE Logon on user with additional groups applied
    $logon = Invoke-LogonUser -Username 'Administrator' -Password $secure_string -Groups 'Administrator', 'Replicator'
    $logon.Token.Dispose()

    .NOTES
    The user will stay logged on until all handles and processes made from the initial access token are closed.
    #>
    [OutputType('PSAccessToken.LogonInfo')]
    [CmdletBinding(DefaultParameterSetName="Username")]
    Param (
        [Parameter(Mandatory=$true, ParameterSetName="Username")]
        [System.String]
        $Username,

        [Parameter(Mandatory=$true, ParameterSetName="Username")]
        [AllowNull()]  # Can logon a user without a password, requires SeTcbPrivilege
        [System.Security.SecureString]
        $Password,

        [Parameter(Mandatory=$true, ParameterSetName="Credential")]
        [PSCredential]
        $Credential,

        [PSAccessToken.LogonType]
        $LogonType,

        [AllowEmptyCollection()]
        [Object[]]
        $Groups = @(),

        [System.String]
        $OriginName = 'PSAccessToken',

        [System.String]
        $AuthenticationPackage = 'Negotiate'
    )

    # Parse the username based on the input parameters.
    if ($PSCmdlet.ParameterSetName -eq "Credential") {
        $Username = $Credential.UserName
        $Password = $Credential.Password
    }

    # Convert the user to a SID then get the full account name from there. This will resolve the domain name, or local
    # hostname if the user omitted it.
    $user_sid = ConvertTo-SecurityIdentifier -InputObject $Username
    $Username = $user_sid.Translate([System.Security.Principal.NTAccount]).Value

    $domain = ''
    if ($Username.Contains('\')) {
        $user_split = $Username.Split([Char[]]@('\'), 2)
        $domain = $user_split[0]
        $Username = $user_split[1]
    }

    $use_s4u = $false
    $lsa_logon_params = @{}
    if ($null -eq $Password) {
        # Passwordless logons require the SeTcbPrivilege (Trusted connection).
        $lsa_logon_params.Trusted = $true

        if ($Domain -eq 'NT AUTHORITY') {
            if ($null -eq $LogonType) {
                $LogonType = [PSAccessToken.LogonType]::Service
            } elseif ($LogonType -notin @('Service')) {
                $warning = "Logon as a service account does not support the logon type '$LogonType', "
                $warning += "using Service instead."
                Write-Warning -Message $warning
                $LogonType = [PSAccessToken.LogonType]::Service
            }
        } else {
            $use_s4u = $true

            if ($null -eq $LogonType) {
                $LogonType = [PSAccessToken.LogonType]::Batch
            } elseif ($LogonType -notin @('Batch', 'Network')) {
                $warning = "Logon without a password does not support the logon type '$LogonType', "
                $warning += "using Batch instead. Supported logon types: Batch, Network."
                Write-Warning -Message $warning
                $LogonType = [PSAccessToken.LogonType]::Batch
            }
        }
    } elseif ($Groups.Length -gt 0) {
        $lsa_logon_params.Trusted = $true
    }

    if ($null -eq $LogonType) {
        $LogonType = [PSAccessToken.LogonType]::Interactive
    }

    # Combine all this info into 1 dict for easier referencing.
    $variables = @{
        authentication_package = $AuthenticationPackage
        groups = $Groups
        logon_type = $LogonType
        origin_name = $OriginName
        use_s4u = $use_s4u
        user_info = @{
            username = $Username
            domain = $domain
            password = $Password
        }
    }

    Use-LsaLogon -Variables $variables @lsa_logon_params -Process {
        Param ([System.IntPtr]$LsaHandle, [Hashtable]$Variables)

        $Variables.lsa_handle = $LsaHandle

        # Get the size of the AuthenticationPackage struct.
        $username_length = [System.Text.Encoding]::Unicode.GetByteCount($Variables.user_info.username)
        $domain_length = [System.Text.Encoding]::Unicode.GetByteCount($Variables.user_info.domain)
        if ($Variables.use_s4u) {
            $struct_size = [System.Runtime.InteropServices.Marshal]::SizeOf(
                [Type][PSAccessToken.LSA_S4U_LOGON]
            )
            $password_length = 0  # No password is used here.
        } else {
            $struct_size = [System.Runtime.InteropServices.Marshal]::SizeOf(
                [Type][PSAccessToken.LSA_INTERACTIVE_LOGON]
            )
            $password_length = $Variables.user_info.password.Length * 2  # A unicode char takes 2 bytes
        }
        $Variables.auth_package_length = $struct_size + $username_length + $domain_length + $password_length
        $Variables.auth_struct_length = $struct_size
        $Variables.username_length = $username_length
        $Variables.domain_length = $domain_length
        $Variables.password_length = $password_length

        #$auth_package_id = Get-AuthenticationPackageId -Name $Variables.user_info.package_name -LsaHandle $LsaHandle
        $auth_package_id = Get-AuthenticationPackageId -Name $Variables.authentication_package -LsaHandle $LsaHandle
        $Variables.auth_package_id = $auth_package_id

        Use-SafePointer -Size $Variables.auth_package_length -Variables $Variables -Process {
            Param ([System.IntPtr]$Ptr, [Hashtable]$Variables)

            $Variables.auth_package_ptr = $Ptr

            # Build the AuthenticationInformation structure
            $lsa_username = New-Object -TypeName PSAccessToken.LSA_UNICODE_STRING
            $lsa_username.Length = $Variables.username_length
            $lsa_username.MaximumLength = $Variables.username_length

            $lsa_domain = New-Object -TypeName PSAccessToken.LSA_UNICODE_STRING
            $lsa_domain.Length = $Variables.domain_length
            $lsa_domain.MaximumLength = $Variables.domain_length

            if ($Variables.use_s4u) {
                $username_ptr = [System.IntPtr]::Add($Ptr, $Variables.auth_struct_length)
                $domain_ptr = [System.IntPtr]::Add($username_ptr, $Variables.username_length)
                $password_ptr = $null

                $lsa_username.Buffer = $username_ptr
                $lsa_domain.Buffer = $domain_ptr

                $auth_info = New-Object -TypeName PSAccessToken.LSA_S4U_LOGON
                $auth_info.MessageType = 12  # MsV1_0S4ULogon/KerbS4ULogon
                $auth_info.Flags = 0
                $auth_info.UserPrincipalName = $lsa_username
                $auth_info.DomainName = $lsa_domain
            } else {
                $domain_ptr = [System.IntPtr]::Add($Ptr, $Variables.auth_struct_length)
                $username_ptr = [System.IntPtr]::Add($domain_ptr, $Variables.domain_length)
                $password_ptr = [System.IntPtr]::Add($username_ptr, $Variables.username_length)

                $lsa_domain.Buffer = $domain_ptr
                $lsa_username.Buffer = $username_ptr

                $lsa_password = New-Object -TypeName PSAccessToken.LSA_UNICODE_STRING
                $lsa_password.Length = $Variables.password_length
                $lsa_password.MaximumLength = $Variables.password_length
                $lsa_password.Buffer = $password_ptr

                $auth_info = New-Object -TypeName PSAccessToken.LSA_INTERACTIVE_LOGON
                $auth_info.MessageType = 2  # MsV1_0InteractiveLogon/KerbInteractiveLogon
                $auth_info.LogonDomainName = $lsa_domain
                $auth_info.UserName = $lsa_username
                $auth_info.Password = $lsa_password
            }

            # Copy the auth info struct and username/domain to the unmanaged memory buffers.
            Copy-StructureToPointer -Ptr $Ptr -Structure $auth_info > $null
            $username_bytes = [System.Text.Encoding]::Unicode.GetBytes($Variables.user_info.username)
            [System.Runtime.InteropServices.Marshal]::Copy($username_bytes, 0, $username_ptr, $username_bytes.Length)

            $domain_bytes = [System.Text.Encoding]::Unicode.GetBytes($Variables.user_info.domain)
            [System.Runtime.InteropServices.Marshal]::Copy($domain_bytes, 0, $domain_ptr, $domain_bytes.Length)

            # The password is copied across right at the end, just store the pointer in a var.
            $Variables.password_ptr = $password_ptr

            $Variables.groups | Use-TokenGroupsPointer -NullAsEmpty -Variables $Variables -Process {
                Param ([System.IntPtr]$Ptr, [Hashtable]$Variables)

                # Build the rest of the parameters.
                $origin_name = New-Object -TypeName PSAccessToken.LSA_STRING
                $origin_name.Length = $Variables.origin_name.Length
                $origin_name.MaximumLength = $Variables.origin_name.Length + 1
                $origin_name.Buffer = $Variables.origin_name
                $token_source = New-Object -TypeName PSAccessToken.TOKEN_SOURCE
                $token_source.SourceName = $Variables.origin_name.PadRight(8, [char]"`0").Substring(0, 8)
                $profile_buffer_ptr = [System.IntPtr]::Zero
                $profile_buffer_length = 0
                $logon_id = New-Object -TypeName PSAccessToken.LUID
                $token = New-Object -TypeName PInvokeHelper.SafeNativeHandle
                $quotas = New-Object -TypeName PSAccessToken.QUOTA_LIMITS
                $sub_status = 0

                try {
                    # Finally copy the password to the unmanaged memory buffer, do this last as we want to clear the
                    # memory as soon as possible. This first uses SecureStringToGlobalAllocUnicode to copy the plaintext
                    # to an unmanaged memory block then wmemcpy_s to copy the plaintext to the password_ptr defined above.
                    # The 2nd copy must be done as the Password buffer must be contiguous to the AuthenticationInformation
                    # structure and SecureStrings have not way to control the memory address the string is copied to.
                    if ($null -ne $Variables.user_info.password) {
                        $ss_password_ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToGlobalAllocUnicode(
                            $Variables.user_info.password
                        )

                        try {
                            $password_length = New-Object -TypeName System.UIntPtr -ArgumentList $Variables.password_length
                            [PSAccessToken.NativeMethods]::CopyMemory(
                                $password_ptr,
                                $ss_password_ptr,
                                $password_length
                            )
                        } finally {
                            [System.Runtime.InteropServices.Marshal]::ZeroFreeGlobalAllocUnicode($ss_password_ptr)
                        }
                    }

                    $res = [PSAccessToken.NativeMethods]::LsaLogonUser(
                        $Variables.lsa_handle,
                        $origin_name,
                        $Variables.logon_type,
                        $Variables.auth_package_id,
                        $Variables.auth_package_ptr,
                        $Variables.auth_package_length,
                        $Ptr,
                        $token_source,
                        [Ref]$profile_buffer_ptr,
                        [Ref]$profile_buffer_length,
                        [Ref]$logon_id,
                        [Ref]$token,
                        [Ref]$quotas,
                        [Ref]$sub_status
                    )
                } finally {
                    # Finally Zero the memory of the password to ensure it is cleanly deleted. Using SecureZeroMemory is
                    # more ideal but we cannot access this in .NET.
                    if ($null -ne $password_ptr) {
                        $empty_bytes = New-Object -TypeName System.Byte[] -ArgumentList $Variables.password_length
                        [System.Runtime.InteropServices.Marshal]::Copy($empty_bytes, 0, $password_ptr, $empty_bytes.Length)
                    }
                }

                if ($res -ne 0) {
                    $msg = Get-Win32ErrorFromLsaStatus -ErrorCode $res
                    throw "Failed to logon user '$($variables.user_info.username)': $msg (LSA Sub Status: $sub_status)"
                }

                try {
                    $convert_params = @{
                        Token = $token
                        ProfileBuffer = $profile_buffer_ptr
                        Username = $Variables.user_info.username
                        Domain = $Variables.user_info.domain
                        LogonType = $Variables.logon_type
                        LogonId = $logon_id
                        QuotaLimits = $quotas
                    }
                    return ConvertTo-LogonInfo @convert_params
                } catch {
                    # If there are any errors in parsing the profile buffer, make sure we dispose of the token.
                    $token.Dispose()
                    throw $_
                } finally {
                    [PSAccessToken.NativeMethods]::LsaFreeReturnBuffer($profile_buffer_ptr) > $null
                }
            }
        }
    }
}