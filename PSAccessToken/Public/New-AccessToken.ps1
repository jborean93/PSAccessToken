# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function New-AccessToken {
    <#
    .SYNOPSIS
    Create a new access token from scratch.

    .DESCRIPTION
    Create a new access token using the NtCreateToken function. This function allows you to create an access token
    with any combination of groups, privileges, and other values that is desired. This is a very low level process and
    requires a lot of input parameters to get a useful token.

    .PARAMETER User
    The user of the new token.

    .PARAMETER Groups
    A list of groups to set on the new token. This can either be a list of group/account names or a list of hashtables
    with the following keys;
        Sid - The name, or SecurityIdentifier of the account.
        Attributes - [PSAccessToken.TokenGroupAttributes] Explicit attributes for the group in the hashtable entry.

    If the entry is a string, or no Attributes is specified, the default Attributes are 'Enabled', 'EnabledByDefault',
    and 'Mandatory'. Other attributes that can be set are;
        Mandatory - Cannot disable the group using AdjustTokenGroups
        EnabledByDefault - The group is enabled by default
        Enabled - The group is enabled
        Owner - Required to set the owner of an object to this group without the SeRestorePrivilege
        UseForDenyOnly - Used in access-denied ACE checks by Windows but is ignored for access-allowed ACEs
        Integrity - Use the -IntegrityLabel parameter instead
        IntegrityEnabled - Use the -IntegrityLabel parameter instead
        Resource - A domain-local group
        LogonId - Identifies a logon session associated with an access token

    .PARAMETER Privileges
    A list of privileges to set on the new token. This can either be a list of privileges or a list of hashtables with
    the following keys;
        Name - The name of the privilege.
        Attributes - [PSAccessToken.TokenPrivilegeAttributes] Explicit attributes for the privilege in the hashtable entry.

    If the entry is a string, or no Attributes is specified, the default Attributes are 'Enabled', and
    'EnabledByDefault'. Other attributes that can be set are;
        Disabled - The privilege is on the token but not enabled.
        EnabledByDefault - Used with Enabled to set the privilege as enabled by default.
        Enabled - The privilege is enabled

    .PARAMETER Owner
    The owner of the token, this is used to set the Owner of a securable object when no explicit Owner is set. If
    omitted then the Owner is the Administrators group if it was set in -Groups, otherwise it is the same as the
    -User parameters.

    .PARAMETER PrimaryGroup
    The primary group of the token, this is used to set the PrimaryGroup of a securable object when no explicit
    PrimaryGroup is set. The default value is the 'None' for local account, and 'Domain Users' for domain accounts.
    If the User is not part of a domain or local account, then 'S-1-5-18' (System) is used.

    .PARAMETER DefaultDacl
    The default DACL of the token, this is used to set the DefaultDacl of a new securable object when no explicit
    DefaultDacl is set. The default value is a DACL with the following ACEs.

        1. Owner - GENERIC_ALL
        2. SYSTEM - GENERIC_ALL

    This parameter can be explicitly set to $null to have no DefaultDacl applied to new objects.

    .PARAMETER Source
    Set a 8 character string to identify the source of the token. This defaults to 'PSAccTok' but can be any string.

    .PARAMETER ImpersonationLevel
    The impersonation level of the token. Set to None for a primary token, otherwise it will be an impersonation token.

    .PARAMETER IntegrityLabel
    The integrity label for the token. This is automatically added as a group with the 'Integrity' and
    'IntegrityEnabled' attributes. The default is 'High'.

    .PARAMETER AuthenticationId
    Set the AuthenticationId of the token. This must be a valid AuthenticationId already created by Windows. Defaults
    to the AuthenticationId of the current process token.

    .PARAMETER ExpirationTime
    Sets the expiration time of the token. This is not currently supported by Windows.

    .OUTPUTS
    [PInvokeHelper.SafeNativeHandle] - A handle to the newly created token.

    .EXAMPLE Create an access token for the SYSTEM account
    $auth_id = New-Object -TypeName PSAccessToken.LUID
    $auth_id.LowPart = 999

    New-AccessToken -User 'SYSTEM' `
        -Groups 'Administrators' `
        -Privileges 'SeTcbPrivilege', 'SeRestorePrivilege', 'SeBackupPrivilege' `
        -AuthenticationId $auth_id  # This isn't necessary but here for posterities sake

    .EXAMPLE Create a token with explicit owner and DACL
    New-AccessToken -User 'Guest' `
        -Groups 'Everyone', 'Users' `
        -Privileges 'SeChangeNotifyPrivilege', 'SeIncreaseWorkingSetPrivilege' `
        -Owner 'Everyone' `
        -IntegrityLabel Low

    .EXAMPLE Add a group and privilege with custom attributes
    New-AccessToken -User 'Administrator' `
        -Groups @{ Sid = 'Administrators'; Attributes = 'Enabled, EnabledByDefault' } `
        -Privileges @{ Name = 'SeRestorePrivilege' = 'Disabled' }, @{ Name = 'SeBackupPrivilege' = 'Enabled' }

    .NOTES
    This cmdlet requires the user to have the SeCreateTokenPrivilege. This is a very powerful privilege that is not
    given to any account by default.
    #>
    [OutputType([PInvokeHelper.SafeNativeHandle])]
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param (
        [Parameter(Mandatory=$true)]
        [Object]
        $User,

        [Parameter(Mandatory=$true)]
        [AllowEmptyCollection()]
        [Object[]]
        $Groups,

        [Parameter(Mandatory=$true)]
        [AllowEmptyCollection()]
        [Object[]]
        $Privileges,

        [Object]
        $Owner,

        [Object]
        $PrimaryGroup,

        [AllowNull()]
        [System.Security.AccessControl.RawAcl]
        $DefaultDacl,

        [ValidateLength(0, 8)]
        [System.String]
        $Source = "PSAccTok",

        [System.Security.Principal.TokenImpersonationLevel]
        $ImpersonationLevel = [System.Security.Principal.TokenImpersonationLevel]::None,

        [ValidateSet('Untrusted', 'Low', 'Medium', 'High', 'System')]
        [System.String]
        $IntegrityLabel = 'High',

        [PSAccessToken.LUID]
        $AuthenticationId,

        [System.Int64]
        $ExpirationTime = 0
    )

    # Store commonly used SIDs
    $system_sid = ConvertTo-SecurityIdentifier -InputObject 'S-1-5-18'
    $admin_sid = ConvertTo-SecurityIdentifier -InputObject 'S-1-5-32-544'

    # Store required variables in an array as this will run in nested scriptblock invocations and won't have access
    # to the PSBoundParameters.
    $variables = @{
        user = ConvertTo-SecurityIdentifier -InputObject $User
        expiration_time = $ExpirationTime
    }

    # Parse the input groups, handle whether the group is a string, or has the optional Attributes added.
    # The default attributes are for the group to be mandatory and enabled by default
    $default_group_attributes = [PSAccessToken.TokenGroupAttributes]'Enabled, EnabledByDefault, Mandatory'
    $variables.groups = @($Groups | ForEach-Object -Process {
        $attributes = $default_group_attributes

        if ($_ -is [System.Collections.IDictionary]) {
            if (-not $_.ContainsKey('Sid')) {
                throw "Groups entry does not contain key 'Sid'"
            }
            $sid = $_.Sid

            if ($_.ContainsKey('Attributes')) {
                $attributes = $_.Attributes
            }
        } else {
            $sid = $_
        }

        @{
            Sid = (ConvertTo-SecurityIdentifier -InputObject $sid)
            Attributes = [PSAccessToken.TokenGroupAttributes]$attributes
        }
    })

    # Common function to add groups to the existing group list
    Function Add-SidToGroup {
        Param (
            [System.Security.Principal.SecurityIdentifier]$Sid,
            [PSAccessToken.TokenGroupAttributes]$Attributes
        )

        $existing_group = $variables.groups | Where-Object { $_.Sid -eq $Sid }
        if ($null -ne $existing_group) {
            $existing_group.Attributes = $existing_group.Attributes -bor $Attributes
        } else {
            $variables.groups += @{
                Sid = $Sid
                Attributes = $Attributes
            }
        }
    }

    # Parse the input privileges, handle whether privileges is a string, or has the optional Attributes added.
    # The default attributes are for the privilege to be enabled by default.
    $default_token_attributes = [PSAccessToken.TokenPrivilegeAttributes]'Enabled, EnabledByDefault'
    $variables.privileges = @($Privileges | ForEach-Object -Process {
        $attributes = $default_token_attributes

        if ($_ -is [System.Collections.IDictionary]) {
            if (-not $_.ContainsKey('Name')) {
                throw "Privileges entry does not contain key 'Name'"
            }
            $name = $_.Name

            if ($_.ContainsKey('Attributes')) {
                $attributes = $_.Attributes
            }
        } else {
            $name = $_.ToString()
        }

        @{
            Name = $name
            Attributes = [PSAccessToken.TokenPrivilegeAttributes]$attributes
        }
    })

    # Set the default of Owner to the User specified.
    if ($null -eq $Owner) {
        # Set the Administrators if the Administrators group is part of the Groups and is not used for deny only.
        $admin_group = $variables.groups | Where-Object { $_.Sid -eq $admin_sid }
        if ($null -ne $admin_group -and -not $admin_group.Attributes.HasFlag([PSAccessToken.TokenGroupAttributes]::UseForDenyOnly)) {
            $Owner = $admin_sid
        } else {
            $Owner = $variables.user
        }
    }
    $variables.owner = ConvertTo-SecurityIdentifier -InputObject $Owner

    # Add the Owner SID to the groups if the Owner is not the current user.
    if ($variables.owner -ne $variables.User -and $variables.owner -notin $variables.Groups) {
        $owner_group_attributes = $default_group_attributes -bor [PSAccessToken.TokenGroupAttributes]::Owner
        Add-SidToGroup -Sid $variables.owner -Attributes $owner_group_attributes
    }

    # Set the default of PrimaryGroup. Default to the None for local accounts, and Domain Users for domain accounts.
    # If the account is not a part of any AccountDomain, use the SYSTEM account.
    if ($null -eq $PrimaryGroup) {
        if ($variables.User.AccountDomainSid) {
            # Even though it says AccountDomainUsersSid, this will be the COMPUTERNAME\None SID for local accounts.
            $PrimaryGroup = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList @(
                [System.Security.Principal.WellKnownSidType]::AccountDomainUsersSid,
                $variables.User.AccountDomainSid.Value
            )
        } else {
            $PrimaryGroup = $system_sid
        }
    }
    $variables.primary_group = ConvertTo-SecurityIdentifier -InputObject $PrimaryGroup
    if ($variables.primary_group -notin $variables.groups.Sid) {
        Add-SidToGroup -Sid $variables.primary_group -Attributes $default_group_attributes
    }

    # If DefaultDacl was not passed in, build our own to ensure the new process does not create unsecured objects.
    if (-not $PSBoundParameters.ContainsKey('DefaultDacl')) {
        $DefaultDacl = New-Object -TypeName System.Security.AccessControl.RawAcl -ArgumentList 2, 2

        $users = [System.Collections.Generic.List[System.Security.Principal.SecurityIdentifier]]@()
        $users.Add($variables.owner)

        if (-not $users.Contains($system_sid)) {
            $users.Add($system_sid)
        }

        foreach ($user in $users) {
            $ace = New-Object -TypeName System.Security.AccessControl.CommonAce -ArgumentList @(
                'None',
                'AccessAllowed',
                0x10000000,  # GENERIC_ALL
                $user,
                $false,
                $null
            )
            $DefaultDacl.InsertAce($DefaultDacl.Count, $ace)
        }
    }
    $variables.default_dacl = $DefaultDacl

    # Determine the correct token type and impersonation level based on the ImpersonationLevel parameter.
    $variables.token_type = [PSAccessToken.TokenType]::Impersonation
    $variables.impersonation_level = switch ($ImpersonationLevel) {
        None {
            $variables.token_type = [PSAccessToken.TokenType]::Primary
            [PSAccessToken.SecurityImpersonationLevel]::Anonymous
        }
        Anonymous { [PSAccessToken.SecurityImpersonationLevel]::Anonymous }
        Identification { [PSAccessToken.SecurityImpersonationLevel]::Identification }
        Impersonation { [PSAccessToken.SecurityImpersonationLevel]::Impersonation }
        Delegation { [PSAccessToken.SecurityImpersonationLevel]::Delegation }
    }

    # Convert the integrity level to a SID
    # TODO: Check TokenIntegrityPolicy of created token
    $integrity_sid = switch($IntegrityLabel) {
        Untrusted { "S-1-16-0" }
        Low { "S-1-16-4096" }
        Medium { "S-1-16-8192" }
        High { "S-1-16-12288" }
        System { "S-1-16-16384" }
    }
    $variables.groups += @{
        Sid = (ConvertTo-SecurityIdentifier -InputObject $integrity_sid)
        Attributes = [PSAccessToken.TokenGroupAttributes]"Integrity, IntegrityEnabled"
    }

    # Get the AuthenticationId for the current logon user.
    if ($null -eq $AuthenticationId) {
        $AuthenticationId = (Get-TokenStatistics).AuthenticationId
    }
    $variables.authentication_id = $AuthenticationId

    # Calculate the size of the TOKEN_GROUPS structure
    $tg_size = [System.Runtime.InteropServices.Marshal]::SizeOf(
        [Type][PSAccessToken.TOKEN_GROUPS]
    )
    $sanda_size = [System.Runtime.InteropServices.Marshal]::SizeOf(
            [Type][PSAccessToken.SID_AND_ATTRIBUTES]
    )
    # TOKEN_GROUPS already contains 1 SID_AND_ATTRIBUTES, remove from count.
    $variables.token_groups_size = $tg_size + ($sanda_size * ($variables.groups.Length - 1))
    $variables.token_groups_sid_offset = $variables.token_groups_size

    foreach ($group in $variables.groups) {
        $variables.token_groups_size += $group.Sid.BinaryLength
    }

    # Calculate the size of the TOKEN_PRIVILEGES structure
    $tp_size = [System.Runtime.InteropServices.Marshal]::SizeOf(
        [Type][PSAccessToken.TOKEN_PRIVILEGES]
    )
    $landa_size = [System.Runtime.InteropServices.Marshal]::SizeOf(
        [Type][PSAccessToken.LUID_AND_ATTRIBUTES]
    )
    if ($variables.privileges.Length -eq 0) {
        # If no privileges are being set on the token, we exclude the LUID_AND_ATTRIBUTES count.
        $variables.token_privileges_size = $tp_size
    } else {
        # TOKEN_PRIVILEGES already contains 1 LUID_AND_ATTRIBUTES, remove from count.
        $variables.token_privileges_size = $tp_size + ($landa_size * ($variables.privileges.Length - 1))
    }

    # TOKEN_SOURCE does not require it's own Ptr, just set first
    $token_source = New-Object -TypeName PSAccessToken.TOKEN_SOURCE
    $token_source.SourceName = $Source.PadRight(8, [char]"`0").ToCharArray()
    $variables.token_source = $token_source

    Use-SafePointer -Size $variables.user.BinaryLength -Variables $variables -Process {
        Param ([System.IntPtr]$Ptr, [Hashtable]$Variables)

        Copy-SidToPointer -Ptr $Ptr -Sid $variables.user > $null

        $sid_and_attributes = New-Object -TypeName PSAccessToken.SID_AND_ATTRIBUTES
        $sid_and_attributes.Sid = $Ptr

        $token_user = New-Object -TypeName PSAccessToken.TOKEN_USER
        $token_user.User = $sid_and_attributes
        $Variables.token_user = $token_user

        Use-SafePointer -Size $Variables.token_groups_size -Variables $Variables -Process {
            Param ([System.IntPtr]$Ptr, [Hashtable]$Variables)

            # Because we are manually building the TOKEN_GROUPS struct, we use the Ptr as our input value
            $Variables.token_groups = $Ptr

            # Track the location of the SIDs at the end of the TOKEN_GROUPS structure
            $sid_ptr = [System.IntPtr]::Add($Ptr, $Variables.token_groups_sid_offset)

            $token_groups = New-Object -TypeName PSAccessToken.TOKEN_GROUPS
            $token_groups.GroupCount = $Variables.groups.Length
            $token_groups.Groups = New-Object -TypeName PSAccessToken.SID_AND_ATTRIBUTES[] -ArgumentList 1

            for ($i = 0; $i -lt $Variables.groups.Length; $i++) {
                $group = $Variables.groups[$i]

                $sanda = New-Object -TypeName PSAccessToken.SID_AND_ATTRIBUTES
                $sanda.Attributes = $group.Attributes
                $sanda.Sid = $sid_ptr

                # Now copy the SID to the unmanaged memory section.
                $sid_ptr = Copy-SidToPointer -Ptr $sid_ptr -Sid $group.Sid

                if ($i -eq 0) {
                    # The 1st SID_AND_ATTRIBUTES should be placed directly on the TOKEN_GROUPS struct, the structure
                    # is copied after this loop.
                    $token_groups.Groups[0] = $sanda
                    $Ptr = [System.IntPtr]::Add($Ptr, [System.Runtime.InteropServices.Marshal]::SizeOf(
                        [Type][PSAccessToken.TOKEN_GROUPS]
                    ))
                } else {
                    # The remaining SID_AND_ATTRIBUTES are copied manually to the end of the TOKEN_GROUPS struct.
                    $Ptr = Copy-StructureToPointer -Ptr $Ptr -Structure $sanda
                }
            }

            # Now copy across the TOKEN_GROUPS structure
            Copy-StructureToPointer -Ptr $Variables.token_groups -Structure $token_groups > $null

            Use-SafePointer -Size $Variables.token_privileges_size -Variables $Variables -Process {
                Param ([System.IntPtr]$Ptr, [Hashtable]$Variables)

                # Because we are manually building the TOKEN_PRIVILEGES struct, we use the Ptr as our input value
                $Variables.token_privileges = $Ptr

                $token_privileges = New-Object -TypeName PSAccessToken.TOKEN_PRIVILEGES
                $token_privileges.PrivilegeCount = $Variables.privileges.Length
                $token_privileges.Privileges = New-Object -TypeName PSAccessToken.LUID_AND_ATTRIBUTES[] -ArgumentList 1

                for ($i = 0; $i -lt $Variables.privileges.Length; $i++) {
                    $privilege = $Variables.privileges[$i]

                    $landa = New-Object -TypeName PSAccessToken.LUID_AND_ATTRIBUTES
                    $landa.Attributes = $privilege.Attributes
                    $landa.Luid = Convert-PrivilegeToLuid -Name $privilege.Name

                    if ($i -eq 0) {
                        # The 1st LUID_AND_ATTRIBUTES should be placed directly on the TOKEN_PRIVILEGES struct, the
                        # structure is copied after this looop.
                        $token_privileges.Privileges[0] = $landa
                        $Ptr = [System.IntPtr]::Add($Ptr, [System.Runtime.InteropServices.Marshal]::SizeOf(
                            [Type][PSAccessToken.TOKEN_PRIVILEGES]
                        ))
                    } else {
                        # The remaining LUID_AND_ATTRIBUTES are copied manually to the end of the TOKEN_PRIVILEGES struct.
                        $Ptr = Copy-StructureToPointer -Ptr $Ptr -Structure $landa
                    }
                }

                # Now copy across the TOKEN_PRIVILEGES structure
                Copy-StructureToPointer -Ptr $Variables.token_privileges -Structure $token_privileges > $null

                Use-SafePointer -Size $Variables.owner.BinaryLength -Variables $Variables -Process {
                    Param ([System.IntPtr]$Ptr, [Hashtable]$Variables)

                    Copy-SidToPointer -Ptr $Ptr -Sid $Variables.owner > $null

                    $token_owner = New-Object -TypeName PSAccessToken.TOKEN_OWNER
                    $token_owner.Owner = $Ptr
                    $Variables.token_owner = $token_owner

                    Use-SafePointer -Size $Variables.primary_group.BinaryLength -Variables $Variables -Process {
                        Param ([System.IntPtr]$Ptr, [Hashtable]$Variables)

                        Copy-SidToPointer -Ptr $Ptr -Sid $Variables.primary_group > $null

                        $token_pg = New-Object -TypeName PSAccessToken.TOKEN_PRIMARY_GROUP
                        $token_pg.PrimaryGroup = $Ptr
                        $Variables.token_primary_group = $token_pg

                        # The DefaultDacl can be empty/null, we check for this
                        if ($null -eq $Variables.default_dacl) {
                            $default_dacl_size = 0
                        } else {
                            $default_dacl_size = $Variables.default_dacl.BinaryLength
                        }

                        Use-SafePointer -Size $default_dacl_size -Variables $Variables -Process {
                            Param ([System.IntPtr]$Ptr, [Hashtable]$Variables)

                            $token_default_dacl = New-Object -TypeName PSAccessToken.TOKEN_DEFAULT_DACL
                            $token_default_dacl.DefaultDacl = $Ptr

                            if ($null -ne $Variables.default_dacl) {
                                $ddacl_bytes = New-Object -TypeName System.Byte[] -ArgumentList $Variables.default_dacl.BinaryLength
                                $Variables.default_dacl.GetBinaryForm($ddacl_bytes, 0)
                                [System.Runtime.InteropServices.Marshal]::Copy($ddacl_bytes, 0, $Ptr, $ddacl_bytes.Length)
                            }

                            $Variables.token_default_dacl = $token_default_dacl

                            $variables.sqos_size = [System.Runtime.InteropServices.Marshal]::SizeOf(
                                [Type][PSAccessToken.SECURITY_QUALITY_OF_SERVICE]
                            )

                            Use-SafePointer -Size $variables.sqos_size -Variables $Variables -Process {
                                Param ([System.IntPtr]$Ptr, [Hashtable]$Variables)

                                $sqos = New-Object -TypeName PSAccessToken.SECURITY_QUALITY_OF_SERVICE
                                $sqos.Length = $Variables.sqos_size
                                $sqos.ImpersonationLevel = $Variables.impersonation_level
                                Copy-StructureToPointer -Ptr $Ptr -Structure $sqos > $null

                                $object_attributes = New-Object -TypeName PSAccessToken.OBJECT_ATTRIBUTES
                                $object_attributes.Length = [System.Runtime.InteropServices.Marshal]::SizeOf(
                                    [Type][PSAccessToken.OBJECT_ATTRIBUTES]
                                )
                                $object_attributes.SecurityQualityOfService = $Ptr

                                # We've built the input params, lets create the token.
                                $old_state = Set-TokenPrivileges -Privileges @{ SeCreateTokenPrivilege = $true } -Strict
                                try {
                                    # Don't actually create the token when in -WhatIf
                                    if (-not $PSCmdlet.ShouldProcess("Access Token", "Create")) {
                                        return
                                    }

                                    $token = New-Object -TypeName PInvokeHelper.SafeNativeHandle
                                    $res = [PSAccessToken.NativeMethods]::NtCreateToken(
                                        [Ref]$token,
                                        [System.Security.Principal.TokenAccessLevels]::MaximumAllowed,
                                        [Ref]$object_attributes,
                                        $Variables.token_type,
                                        [Ref]$Variables.authentication_id,
                                        [Ref]$Variables.expiration_time,
                                        [Ref]$Variables.token_user,
                                        $Variables.token_groups,
                                        $Variables.token_privileges,
                                        [Ref]$Variables.token_owner,
                                        [Ref]$Variables.token_primary_group,
                                        [Ref]$Variables.token_default_dacl,
                                        [Ref]$Variables.token_source
                                    )

                                    if ($res -ne 0) {
                                        $msg = Get-Win32ErrorFromNtStatus -ErrorCode $res
                                        throw "NtCreateToken() failed: $msg"
                                    }

                                    return $token
                                } finally {
                                    Set-TokenPrivileges -Privileges $old_state > $null
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}