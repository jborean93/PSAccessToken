# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

$verbose = @{}
if ($env:APPVEYOR_REPO_BRANCH -and $env:APPVEYOR_REPO_BRANCH -notlike "master") {
    $verbose.Add("Verbose", $true)
}

$ps_version = $PSVersionTable.PSVersion.Major
$cmdlet_name = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
$module_name = (Get-ChildItem -Path $PSScriptRoot\.. -Directory -Exclude @("Build", "Docs", "Tests")).Name
Import-Module -Name $PSScriptRoot\..\$module_name -Force
. $PSScriptRoot\..\$module_name\Private\ConvertTo-SecurityIdentifier.ps1
.$PSScriptRoot\TestUtils.ps1

$user_sid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User
$none_sid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList @(
    [System.Security.Principal.WellKnownSidType]::AccountDomainUsersSid,
    $user_sid.AccountDomainSid.Value
)
$system_sid = ConvertTo-SecurityIdentifier -InputObject 'S-1-5-18'
$admin_sid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList 'S-1-5-32-544'

Describe "$cmdlet_name PS$ps_version tests" {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        # The tests require the SeCreateTokenPrivilege which we don't have. This function will get a token with this
        # privilege which we use to impersonate each test with.
        $elevated_token = Get-TokenWithPrivilege -Privileges 'SeCreateTokenPrivilege'

        BeforeEach {
            $res = [PSAccessToken.NativeMethods]::ImpersonateLoggedOnUser(
                $elevated_token
            ); $err = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()

            if (-not $res) {
                $msg = Get-Win32ErrorMessage -ErrorCode $err
                throw "Failed to impersonate token with SeCreateTokenPrivilege required for New-AccessToken tests: $msg"
            }
        }

        AfterEach {
            [PSAccessToken.NativeMethods]::RevertToSelf() > $null
        }

        AfterAll {
            $elevated_token.Dispose()
        }

        It 'Creates an access token with defaults' {
            $token_stats = Get-TokenStatistics

            $h_token = New-AccessToken `
                -User 'SYSTEM' `
                -Groups 'Administrators', 'Everyone' `
                -Privileges 'SeTcbPrivilege', 'SeRestorePrivilege'

            try {
                $h_token.IsClosed | Should -Be $false
                $h_token.IsInvalid | Should -Be $false

                $actual_user = Get-TokenUser -Token $h_token
                $actual_groups = Get-TokenGroups -Token $h_token | Sort-Object -Property Sid
                $actual_privileges = Get-TokenPrivileges -Token $h_token | Sort-Object -Property Name
                $actual_owner = Get-TokenOwner -Token $h_token
                $actual_primary_group = Get-TokenPrimaryGroup -Token $h_token
                $actual_default_dacl = Get-TokenDefaultDacl -Token $h_token
                $actual_source = Get-TokenSource -Token $h_token
                $actual_type = Get-TokenType -Token $h_token
                $actual_impersonation = Get-TokenImpersonationLevel -Token $h_token
                $actual_statistics = Get-TokenStatistics -Token $h_token

                $actual_user | Should -Be $system_sid
                $actual_groups.Length | Should -Be 3
                $actual_groups[0].Sid | Should -Be 'S-1-1-0'
                $actual_groups[0].Attributes | Should -Be 'Mandatory, EnabledByDefault, Enabled'
                $actual_groups[1].Sid | Should -Be 'S-1-16-12288'
                $actual_groups[1].Attributes | Should -Be 'Integrity, IntegrityEnabled'
                $actual_groups[2].Sid | Should -Be 'S-1-5-32-544'
                $actual_groups[2].Attributes | Should -Be 'Mandatory, EnabledByDefault, Enabled, Owner'
                $actual_privileges.Length | Should -Be 2
                $actual_privileges[0].Name | Should -Be 'SeRestorePrivilege'
                $actual_privileges[0].Attributes | Should -Be 'EnabledByDefault, Enabled'
                $actual_privileges[1].Name | Should -Be 'SeTcbPrivilege'
                $actual_privileges[1].Attributes | Should -Be 'EnabledByDefault, Enabled'
                $actual_owner | Should -Be $admin_sid
                $actual_primary_group | Should -Be $system_sid
                $actual_default_dacl.Revision | Should -Be 2
                $actual_default_dacl.Count | Should -Be 2
                $actual_default_dacl.Item(0).AccessMask | Should -Be 0x10000000
                $actual_default_dacl.Item(0).AceFlags | Should -Be 'None'
                $actual_default_dacl.Item(0).AceType | Should -Be 'AccessAllowed'
                $actual_default_dacl.Item(0).SecurityIdentifier | Should -Be $admin_sid
                $actual_default_dacl.Item(1).AccessMask | Should -Be 0x10000000
                $actual_default_dacl.Item(1).AceFlags | Should -Be 'None'
                $actual_default_dacl.Item(1).AceType | Should -Be 'AccessAllowed'
                $actual_default_dacl.Item(1).SecurityIdentifier | Should -Be $system_sid
                $actual_source.Name | Should -Be 'PSAccTok'
                $actual_type | Should -be 'Primary'
                $actual_impersonation | Should -Be 'None'

                $actual_statistics.AuthenticationId.LowPart | Should -Be $token_stats.AuthenticationId.LowPart
                $actual_statistics.AuthenticationId.HighPart | Should -Be $token_stats.AuthenticationId.HighPart
                $actual_statistics.ExpirationTime | Should -Be 0
            } finally {
                $h_token.Dispose()
            }
            $h_token.IsClosed | Should -Be $true
        }

        It 'Creates an access token for the current user with admin group' {
            $h_token = New-AccessToken `
                -User $user_sid `
                -Groups 'Administrators' `
                -Privileges 'SeBackupPrivilege', 'SeRestorePrivilege'

            try {
                $actual_user = Get-TokenUser -Token $h_token
                $actual_groups = Get-TokenGroups -Token $h_token | Sort-Object -Property Sid
                $actual_privileges = Get-TokenPrivileges -Token $h_token | Sort-Object -Property Name
                $actual_owner = Get-TokenOwner -Token $h_token
                $actual_primary_group = Get-TokenPrimaryGroup -Token $h_token
                $actual_default_dacl = Get-TokenDefaultDacl -Token $h_token

                $actual_user | Should -Be $user_sid
                $actual_groups.Length | Should -Be 3
                $actual_groups[0].Sid | Should -Be 'S-1-16-12288'
                $actual_groups[0].Attributes | Should -Be 'Integrity, IntegrityEnabled'
                $actual_groups[1].Sid | Should -Be $none_sid
                $actual_groups[1].Attributes | Should -Be 'Mandatory, EnabledByDefault, Enabled'
                $actual_groups[2].Sid | Should -Be 'S-1-5-32-544'
                $actual_groups[2].Attributes | Should -Be 'Mandatory, EnabledByDefault, Enabled, Owner'
                $actual_privileges.Length | Should -Be 2
                $actual_privileges[0].Name | Should -Be 'SeBackupPrivilege'
                $actual_privileges[0].Attributes | Should -Be 'EnabledByDefault, Enabled'
                $actual_privileges[1].Name | Should -Be 'SeRestorePrivilege'
                $actual_privileges[1].Attributes | Should -Be 'EnabledByDefault, Enabled'
                $actual_owner | Should -Be $admin_sid
                $actual_primary_group | Should -Be $none_sid
                $actual_default_dacl.Revision | Should -Be 2
                $actual_default_dacl.Count | Should -Be 2
                $actual_default_dacl.Item(0).AccessMask | Should -Be 0x10000000
                $actual_default_dacl.Item(0).AceFlags | Should -Be 'None'
                $actual_default_dacl.Item(0).AceType | Should -Be 'AccessAllowed'
                $actual_default_dacl.Item(0).SecurityIdentifier | Should -Be $admin_sid
                $actual_default_dacl.Item(1).AccessMask | Should -Be 0x10000000
                $actual_default_dacl.Item(1).AceFlags | Should -Be 'None'
                $actual_default_dacl.Item(1).AceType | Should -Be 'AccessAllowed'
                $actual_default_dacl.Item(1).SecurityIdentifier | Should -Be $system_sid
            } finally {
                $h_token.Dispose()
            }
        }

        It 'Creates an access token for current user without admin group' {
            $h_token = New-AccessToken `
                -User $user_sid `
                -Groups 'Users', 'Everyone' `
                -Privileges 'SeChangeNotifyPrivilege'

            try {
                $actual_user = Get-TokenUser -Token $h_token
                $actual_groups = Get-TokenGroups -Token $h_token | Sort-Object -Property Sid
                $actual_privileges = Get-TokenPrivileges -Token $h_token | Sort-Object -Property Name
                $actual_owner = Get-TokenOwner -Token $h_token
                $actual_primary_group = Get-TokenPrimaryGroup -Token $h_token
                $actual_default_dacl = Get-TokenDefaultDacl -Token $h_token

                $actual_user | Should -Be $user_sid
                $actual_groups.Length | Should -Be 4
                $actual_groups[0].Sid | Should -Be 'S-1-1-0'
                $actual_groups[0].Attributes | Should -Be 'Mandatory, EnabledByDefault, Enabled'
                $actual_groups[1].Sid | Should -Be 'S-1-16-12288'
                $actual_groups[1].Attributes | Should -Be 'Integrity, IntegrityEnabled'
                $actual_groups[2].Sid | Should -Be $none_sid
                $actual_groups[2].Attributes | Should -Be 'Mandatory, EnabledByDefault, Enabled'
                $actual_groups[3].Sid | Should -Be 'S-1-5-32-545'
                $actual_groups[3].Attributes | Should -Be 'Mandatory, EnabledByDefault, Enabled'
                $actual_privileges.Name | Should -Be 'SeChangeNotifyPrivilege'
                $actual_privileges.Attributes | Should -Be 'EnabledByDefault, Enabled'
                $actual_owner | Should -Be $user_sid
                $actual_primary_group | Should -Be $none_sid
                $actual_default_dacl.Revision | Should -Be 2
                $actual_default_dacl.Count | Should -Be 2
                $actual_default_dacl.Item(0).AccessMask | Should -Be 0x10000000
                $actual_default_dacl.Item(0).AceFlags | Should -Be 'None'
                $actual_default_dacl.Item(0).AceType | Should -Be 'AccessAllowed'
                $actual_default_dacl.Item(0).SecurityIdentifier | Should -Be $user_sid
                $actual_default_dacl.Item(1).AccessMask | Should -Be 0x10000000
                $actual_default_dacl.Item(1).AceFlags | Should -Be 'None'
                $actual_default_dacl.Item(1).AceType | Should -Be 'AccessAllowed'
                $actual_default_dacl.Item(1).SecurityIdentifier | Should -Be $system_sid
            } finally {
                $h_token.Dispose()
            }
        }

        It 'Creates an access token with Administrators in deny only group' {
            $h_token = New-AccessToken `
                -User $user_sid `
                -Groups @{Sid = 'Administrators'; Attributes = 'UseForDenyOnly' }, 'Users', 'Everyone' `
                -Privileges 'SeChangeNotifyPrivilege'

            try {
                $actual_user = Get-TokenUser -Token $h_token
                $actual_groups = Get-TokenGroups -Token $h_token | Sort-Object -Property Sid
                $actual_privileges = Get-TokenPrivileges -Token $h_token | Sort-Object -Property Name
                $actual_owner = Get-TokenOwner -Token $h_token
                $actual_primary_group = Get-TokenPrimaryGroup -Token $h_token
                $actual_default_dacl = Get-TokenDefaultDacl -Token $h_token

                $actual_user | Should -Be $user_sid
                $actual_groups.Length | Should -Be 5
                $actual_groups[0].Sid | Should -Be 'S-1-1-0'
                $actual_groups[0].Attributes | Should -Be 'Mandatory, EnabledByDefault, Enabled'
                $actual_groups[1].Sid | Should -Be 'S-1-16-12288'
                $actual_groups[1].Attributes | Should -Be 'Integrity, IntegrityEnabled'
                $actual_groups[2].Sid | Should -Be $none_sid
                $actual_groups[2].Attributes | Should -Be 'Mandatory, EnabledByDefault, Enabled'
                $actual_groups[3].Sid | Should -Be 'S-1-5-32-544'
                $actual_groups[3].Attributes | Should -Be 'UseForDenyOnly'
                $actual_groups[4].Sid | Should -Be 'S-1-5-32-545'
                $actual_groups[4].Attributes | Should -Be 'Mandatory, EnabledByDefault, Enabled'
                $actual_privileges.Name | Should -Be 'SeChangeNotifyPrivilege'
                $actual_privileges.Attributes | Should -Be 'EnabledByDefault, Enabled'
                $actual_owner | Should -Be $user_sid
                $actual_primary_group | Should -Be $none_sid
                $actual_default_dacl.Revision | Should -Be 2
                $actual_default_dacl.Count | Should -Be 2
                $actual_default_dacl.Item(0).AccessMask | Should -Be 0x10000000
                $actual_default_dacl.Item(0).AceFlags | Should -Be 'None'
                $actual_default_dacl.Item(0).AceType | Should -Be 'AccessAllowed'
                $actual_default_dacl.Item(0).SecurityIdentifier | Should -Be $user_sid
                $actual_default_dacl.Item(1).AccessMask | Should -Be 0x10000000
                $actual_default_dacl.Item(1).AceFlags | Should -Be 'None'
                $actual_default_dacl.Item(1).AceType | Should -Be 'AccessAllowed'
                $actual_default_dacl.Item(1).SecurityIdentifier | Should -Be $system_sid
            } finally {
                $h_token.Dispose()
            }
        }

        It 'Creates an access token which we can impersonate' {
            $h_token = New-AccessToken `
                -User 'SYSTEM' `
                -Groups 'Administrators', 'Everyone' `
                -Privileges 'SeTcbPrivilege', 'SeRestorePrivilege'

            try {
                Invoke-WithImpersonation -Token $h_token -ScriptBlock {
                    $actual_user = Get-TokenUser
                    $actual_groups = Get-TokenGroups | Sort-Object -Property Sid
                    $actual_privileges = Get-TokenPrivileges | Sort-Object -Property Name

                    $actual_user | Should -Be $system_sid
                    $actual_groups.Length | Should -Be 3
                    $actual_groups[0].Sid | Should -Be 'S-1-1-0'
                    $actual_groups[0].Attributes | Should -Be 'Mandatory, EnabledByDefault, Enabled'
                    $actual_groups[1].Sid | Should -Be 'S-1-16-12288'
                    $actual_groups[1].Attributes | Should -Be 'Integrity, IntegrityEnabled'
                    $actual_groups[2].Sid | Should -Be 'S-1-5-32-544'
                    $actual_groups[2].Attributes | Should -Be 'Mandatory, EnabledByDefault, Enabled, Owner'
                    $actual_privileges.Length | Should -Be 2
                    $actual_privileges[0].Name | Should -Be 'SeRestorePrivilege'
                    $actual_privileges[0].Attributes | Should -Be 'EnabledByDefault, Enabled'
                    $actual_privileges[1].Name | Should -Be 'SeTcbPrivilege'
                    $actual_privileges[1].Attributes | Should -Be 'EnabledByDefault, Enabled'
                }
            } finally {
                $h_token.Dispose()
            }
        }

        It 'Creates an access token with no groups or privileges' {
            $h_token = New-AccessToken `
                -User 'SYSTEM' `
                -Groups @() `
                -Privileges @()

            try {
                $actual_user = Get-TokenUser -Token $h_token
                $actual_groups = Get-TokenGroups -Token $h_token | Sort-Object -Property Sid
                $actual_privileges = Get-TokenPrivileges -Token $h_token | Sort-Object -Property Name

                $actual_user | Should -Be $system_sid
                $actual_groups.Sid | Should -Be 'S-1-16-12288'
                $actual_groups.Attributes | Should -Be 'Integrity, IntegrityEnabled'
                $actual_privileges | Should -Be $null
            } finally {
                $h_token.Dispose()
            }
        }

        It 'Creates an access token with -WhatIf' {
            $h_token = New-AccessToken `
                -User 'SYSTEM' `
                -Groups @() `
                -Privileges @() `
                -WhatIf

            $h_token | Should -Be $null
        }

        It 'Creates an access token with custom group and privilege attributes' {
            $h_token = New-AccessToken `
                -User $user_sid `
                -Groups @{Sid = 'Administrators'; Attributes = 'Resource, Enabled' } `
                -Privileges @()

            try {
                $actual_user = Get-TokenUser -Token $h_token
                $actual_groups = Get-TokenGroups -Token $h_token | Sort-Object -Property Sid

                $actual_user | Should -Be $user_sid
                $actual_groups.Length | Should -Be 3
                $actual_groups[0].Sid | Should -Be 'S-1-16-12288'
                $actual_groups[0].Attributes | Should -Be 'Integrity, IntegrityEnabled'
                $actual_groups[1].Sid | Should -Be $none_sid
                $actual_groups[1].Attributes | Should -Be 'Mandatory, EnabledByDefault, Enabled'
                $actual_groups[2].Sid | Should -Be 'S-1-5-32-544'
                $actual_groups[2].Attributes | Should -Be 'Mandatory, EnabledByDefault, Enabled, Owner, Resource'
            } finally {
                $h_token.Dispose()
            }
        }

        It 'Creates an access token with custom group but no SID' {
            $expected = 'Groups entry does not contain key ''Sid'''
            { New-AccessToken `
                -User $user_sid `
                -Groups @{Group = 'Administrators'} `
                -Privileges @()
            } | Should -Throw $expected
        }

        It 'Creates an access token with invalid custom group attributes' {
            $expected = 'Cannot convert value "Fake" to type "PSAccessToken.TokenGroupAttributes". '
            $expected += 'Error: "Unable to match the identifier name Fake to a valid enumerator name. '
            $expected += 'Specify one of the following enumerator names and try again:'
            $expected += ([System.Environment]::NewLine)
            $expected += 'Mandatory, EnabledByDefault, Enabled, Owner, UseForDenyOnly, Integrity, IntegrityEnabled, Resource, LogonId"'

            { New-AccessToken `
                -User $user_sid `
                -Groups @{Sid = 'Administrators'; Attributes = 'Fake' } `
                -Privileges @()
            } | Should -Throw $expected
        }

        It 'Creates an access token with custom privilege but no name' {
            $expected = 'Privileges entry does not contain key ''Name'''
            { New-AccessToken `
                -User $user_sid `
                -Groups 'Administrators' `
                -Privileges @{Privilege = 'SeFakePrivilege'}
            } | Should -Throw $expected
        }

        It 'Creates an access token with invalid custom privilege attributes' {
            $expected = 'Cannot convert value "Fake" to type "PSAccessToken.TokenPrivilegeAttributes". '
            $expected += 'Error: "Unable to match the identifier name Fake to a valid enumerator name. '
            $expected += 'Specify one of the following enumerator names and try again:'
            $expected += ([System.Environment]::NewLine)
            $expected += 'Disabled, EnabledByDefault, Enabled, Removed, UsedForAccess"'

            { New-AccessToken `
                -User $user_sid `
                -Groups @() `
                -Privileges @{Name = 'SeCreateTokenPrivilege'; Attributes = 'Fake'}
            } | Should -Throw $expected
        }

        It 'Creates an access token with custom owner' {
            $h_token = New-AccessToken `
                -User $user_sid `
                -Groups 'Administrators', 'Everyone' `
                -Privileges 'SeChangeNotifyPrivilege', 'SeTimeZonePrivilege' `
                -Owner $user_sid

            try {
                $actual_groups = Get-TokenGroups -Token $h_token | Sort-Object -Property Sid
                $actual_owner = Get-TokenOwner -Token $h_token

                $actual_groups.Length | Should -Be 4
                $actual_groups[0].Sid | Should -Be 'S-1-1-0'
                $actual_groups[0].Attributes | Should -Be 'Mandatory, EnabledByDefault, Enabled'
                $actual_groups[1].Sid | Should -Be 'S-1-16-12288'
                $actual_groups[1].Attributes | Should -Be 'Integrity, IntegrityEnabled'
                $actual_groups[2].Sid | Should -Be $none_sid
                $actual_groups[2].Attributes | Should -Be 'Mandatory, EnabledByDefault, Enabled'
                $actual_groups[3].Sid | Should -Be 'S-1-5-32-544'
                $actual_groups[3].Attributes | Should -Be 'Mandatory, EnabledByDefault, Enabled'
                $actual_owner | Should -Be $user_sid
            } finally {
                $h_token.Dispose()
            }
        }

        It 'Creates an access token with custom primary group' {
            $h_token = New-AccessToken `
                -User $user_sid `
                -Groups 'Administrators', 'Everyone' `
                -Privileges 'SeChangeNotifyPrivilege', 'SeTimeZonePrivilege' `
                -PrimaryGroup $system_sid

            try {
                $actual_groups = Get-TokenGroups -Token $h_token | Sort-Object -Property Sid
                $actual_primary_group = Get-TokenPrimaryGroup -Token $h_token

                $actual_groups.Length | Should -Be 4
                $actual_groups[0].Sid | Should -Be 'S-1-1-0'
                $actual_groups[0].Attributes | Should -Be 'Mandatory, EnabledByDefault, Enabled'
                $actual_groups[1].Sid | Should -Be 'S-1-16-12288'
                $actual_groups[1].Attributes | Should -Be 'Integrity, IntegrityEnabled'
                $actual_groups[2].Sid | Should -Be 'S-1-5-18'
                $actual_groups[2].Attributes | Should -Be 'Mandatory, EnabledByDefault, Enabled'
                $actual_groups[3].Sid | Should -Be 'S-1-5-32-544'
                $actual_groups[3].Attributes | Should -Be 'Mandatory, EnabledByDefault, Enabled, Owner'
                $actual_primary_group | Should -Be $system_sid
            } finally {
                $h_token.Dispose()
            }
        }

        It 'Creates an access token with custom default dacl' {
            $default_dacl = New-Object -TypeName System.Security.AccessControl.RawAcl -ArgumentList 2, 2

            $users = [System.Collections.Generic.List[System.Security.Principal.SecurityIdentifier]]@()
            $users.Add($none_sid)
            $users.Add($user_sid)

            foreach ($user in $users) {
                $ace = New-Object -TypeName System.Security.AccessControl.CommonAce -ArgumentList @(
                    'None',
                    'AccessAllowed',
                    0x80000000,
                    $user,
                    $false,
                    $null
                )
                $default_dacl.InsertAce($default_dacl.Count, $ace)
            }

            $h_token = New-AccessToken `
                -User $user_sid `
                -Groups 'Administrators', 'Everyone' `
                -Privileges 'SeChangeNotifyPrivilege', 'SeTimeZonePrivilege' `
                -DefaultDacl $default_dacl

            try {
                $actual_default_dacl = Get-TokenDefaultDacl -Token $h_token

                $actual_default_dacl.Revision | Should -Be 2
                $actual_default_dacl.Count | Should -Be 2
                $actual_default_dacl.Item(0).AccessMask | Should -Be 0x80000000
                $actual_default_dacl.Item(0).AceFlags | Should -Be 'None'
                $actual_default_dacl.Item(0).AceType | Should -Be 'AccessAllowed'
                $actual_default_dacl.Item(0).SecurityIdentifier | Should -Be $none_sid
                $actual_default_dacl.Item(1).AccessMask | Should -Be 0x80000000
                $actual_default_dacl.Item(1).AceFlags | Should -Be 'None'
                $actual_default_dacl.Item(1).AceType | Should -Be 'AccessAllowed'
                $actual_default_dacl.Item(1).SecurityIdentifier | Should -Be $user_sid
            } finally {
                $h_token.Dispose()
            }
        }

        It 'Creates an access token with null default dacl' {
            $h_token = New-AccessToken `
                -User $user_sid `
                -Groups 'Administrators', 'Everyone' `
                -Privileges 'SeChangeNotifyPrivilege', 'SeTimeZonePrivilege' `
                -DefaultDacl $null

            try {
                $actual_default_dacl = Get-TokenDefaultDacl -Token $h_token

                $actual_default_dacl | Should -Be $null
            } finally {
                $h_token.Dispose()
            }
        }

        It 'Creates an access token with explicit label <Label>' -TestCases @(
            @{ Label = 'Untrusted'; Expected = 'S-1-16-0' },
            @{ Label = 'Low'; Expected = 'S-1-16-4096' },
            @{ Label = 'Medium'; Expected = 'S-1-16-8192' },
            @{ Label = 'High'; Expected = 'S-1-16-12288' },
            @{ Label = 'System'; Expected = 'S-1-16-16384' }
        ) {
            Param ([System.String]$Label, [System.String]$Expected)

            $h_token = New-AccessToken `
                -User $user_sid `
                -Groups 'Administrators', 'Everyone' `
                -Privileges 'SeChangeNotifyPrivilege', 'SeTimeZonePrivilege' `
                -IntegrityLabel $Label

            try {
                $actual_groups = Get-TokenGroups -Token $h_token | Sort-Object -Property Sid

                $actual_groups.Length | Should -Be 4
                $actual_groups[0].Sid | Should -Be 'S-1-1-0'
                $actual_groups[0].Attributes | Should -Be 'Mandatory, EnabledByDefault, Enabled'
                $actual_groups[1].Sid | Should -Be $Expected
                $actual_groups[1].Attributes | Should -Be 'Integrity, IntegrityEnabled'
                $actual_groups[2].Sid | Should -Be $none_sid
                $actual_groups[2].Attributes | Should -Be 'Mandatory, EnabledByDefault, Enabled'
                $actual_groups[3].Sid | Should -Be 'S-1-5-32-544'
                $actual_groups[3].Attributes | Should -Be 'Mandatory, EnabledByDefault, Enabled, Owner'
            } finally {
                $h_token.Dispose()
            }
        }

        It 'Fails to create an access token with invalid explicit label' {
            $expected = 'Cannot validate argument on parameter ''IntegrityLabel''. '
            $expected += 'The argument "Fake" does not belong to the set "Untrusted,Low,Medium,High,System" '
            $expected += 'specified by the ValidateSet attribute. Supply an argument that is in the '
            $expected += 'set and then try the command again.'
            { New-AccessToken `
                -User $user_sid `
                -Groups 'Administrators', 'Everyone' `
                -Privileges 'SeChangeNotifyPrivilege', 'SeTimeZonePrivilege' `
                -IntegrityLabel 'Fake'
            } | Should -Throw $expected
        }

        It 'Creates an access token with explicit authentication id' {
            # SYSTEM token always has a LUID of 0x3e7
            $auth_id = New-Object -TypeName PSAccessToken.LUID
            $auth_id.LowPart = 999

            $h_token = New-AccessToken `
                -User $user_sid `
                -Groups 'Administrators', 'Everyone' `
                -Privileges 'SeChangeNotifyPrivilege', 'SeTimeZonePrivilege' `
                -AuthenticationId $auth_id

            try {
                $actual_stats = Get-TokenStatistics -Token $h_token

                $actual_stats.AuthenticationId.LowPart | Should -Be $auth_id.LowPart
                $actual_stats.AuthenticationId.HighPart | Should -Be $auth_id.HighPart
            } finally {
                $h_token.Dispose()
            }
        }

        It 'Fails to run with custom authentication id' {
            $expected = 'NtCreateToken() failed: A specified logon session does not exist. It may already have been terminated (Win32 ErrorCode 1312 - 0x00000520)'

            $auth_id = New-Object -TypeName PSAccessToken.LUID
            $auth_id.LowPart = 1234

            { New-AccessToken `
                -User $user_sid `
                -Groups 'Administrators', 'Everyone' `
                -Privileges 'SeChangeNotifyPrivilege', 'SeTimeZonePrivilege' `
                -AuthenticationId $auth_id
            } | Should -Throw $expected
        }

        It 'Creates an access token with explicit expirationtime' {
            $h_token = New-AccessToken `
                -User $user_sid `
                -Groups 'Administrators', 'Everyone' `
                -Privileges 'SeChangeNotifyPrivilege', 'SeTimeZonePrivilege' `
                -ExpirationTime 10

            try {
                $actual_stats = Get-TokenStatistics -Token $h_token

                $actual_stats.ExpirationTime | Should -Be 10
            } finally {
                $h_token.Dispose()
            }
        }

        It 'Creates an impersonation level <Level> token' -TestCases @(
            @{ Level = [System.Security.Principal.TokenImpersonationLevel]::Anonymous },
            @{ Level = [System.Security.Principal.TokenImpersonationLevel]::Identification },
            @{ Level = [System.Security.Principal.TokenImpersonationLevel]::Impersonation },
            @{ Level = [System.Security.Principal.TokenImpersonationLevel]::Delegation }
        ) {
            Param ([System.Security.Principal.TokenImpersonationLevel]$Level)

            $h_token = New-AccessToken `
                -User $user_sid `
                -Groups 'Administrators', 'Everyone' `
                -Privileges 'SeChangeNotifyPrivilege', 'SeTimeZonePrivilege' `
                -ImpersonationLevel $Level

            try {
                $token_type = Get-TokenType -Token $h_token
                $token_impersonation_level = Get-TokenImpersonationLevel -Token $h_token

                $token_type | Should -Be ([PSAccessToken.TokenType]::Impersonation)
                $token_impersonation_level | Should -Be $Level
            } finally {
                $h_token.Dispose()
            }
        }

        It 'Fails to create with source greater than 8 chars' {
            $expected = 'Cannot validate argument on parameter ''Source''. '
            $expected += 'The character length of the 10 argument is too long. '
            $expected += 'Shorten the character length of the argument so it is fewer than or equal to "8" characters,'
            $expected += ' and then try the command again.'
            { New-AccessToken `
                -User $user_sid `
                -Groups 'Administrators', 'Everyone' `
                -Privileges 'SeChangeNotifyPrivilege', 'SeTimeZonePrivilege' `
                -Source 'ABC123Long'
            } | Should -Throw $expected
        }

        It 'Fails to create token without required privilege' {
            $expected = 'AdjustTokenPrivileges(SeCreateTokenPrivilege) failed: Not all privileges or groups referenced are '
            $expected += 'assigned to the caller (Win32 ErrorCode 1300 - 0x00000514)'

            $h_token = New-AccessToken `
                -User $system_sid `
                -Groups 'Administrators', 'Everyone' `
                -Privileges 'SeTcbPrivilege', 'SeSecurityPrivilege'

            try {
                Invoke-WithImpersonation -Token $h_token -ScriptBlock {
                    { New-AccessToken `
                        -User $user_sid `
                        -Groups @() `
                        -Privileges @()
                    } | Should -Throw $expected
                }
            } finally {
                $h_token.Dispose()
            }
        }
    }
}