# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    "PSAvoidUsingConvertToSecureStringWithPlainText", "",
    Justification="Cmdlet expects a SecureString so we need to test with them"
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    "PSUseDeclaredVarsMoreThanAssignments", "",
    Justification="Bug in PSScriptAnalyzer detecting Pester scope, the vars are being used"
)]
Param ()

$verbose = @{}
if ($env:APPVEYOR_REPO_BRANCH -and $env:APPVEYOR_REPO_BRANCH -notlike "master") {
    $verbose.Add("Verbose", $true)
}

$ps_version = $PSVersionTable.PSVersion.Major
$cmdlet_name = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
$module_name = (Get-ChildItem -Path $PSScriptRoot\.. -Directory -Exclude @("Build", "Docs", "Tests")).Name
. $PSScriptRoot\TestUtils.ps1
. $PSScriptRoot\..\$module_name\Private\ConvertTo-SecurityIdentifier.ps1

Describe "$cmdlet_name PS$ps_version tests" {

    Context 'Fails during profile buffer parsing' {
        Set-StrictMode -Version latest

        Import-Module -Name $PSScriptRoot\..\$module_name -Force
        Mock -ModuleName PSAccessToken -CommandName ConvertTo-LogonInfo -MockWith { throw "custom exception" }

        It 'Should raise exception and cleanly dispose token when failing to parse profile buffer' {
            $expected = 'custom exception'

            $system_token = Get-SystemToken
            try {
                Invoke-WithImpersonation -Token $system_token -ScriptBlock {
                    { Invoke-LogonUser -Username 'SYSTEM' -Password $null } | Should -Throw $expected
                }
            } finally {
                $system_token.Dispose()
            }
        }
    }

    $standard_account = 'standard-user'
    $standard_password = ConvertTo-SecureString -String ([System.Guid]::NewGuid()).ToString() -AsPlainText -Force

    $admin_account = 'admin-user'
    $admin_password = ConvertTo-SecureString -String ([System.Guid]::NewGuid()).ToString() -AsPlainText -Force

    Context 'Strict mode' {
        Set-StrictMode -Version latest

        Import-Module -Name $PSScriptRoot\..\$module_name -Force

        BeforeAll {
            $standard_account_sid = New-LocalAccount -Username $standard_account -Password $standard_password
            Set-LocalAccountMembership -Username $standard_account -Groups 'Users'

            $admin_account_sid = New-LocalAccount -Username $admin_account -Password $admin_password
            Set-LocalAccountMembership -Username $admin_account -Groups 'Administrators', 'Users'
        }

        AfterAll {
            Remove-LocalAccount -Username $standard_account
            Remove-LocalAccount -Username $admin_account
        }

        It 'Should log on <Account> account with username and password' -TestCases @(
            @{ Account = $admin_account; AccountSid = $admin_account_sid; Password = $admin_password },
            @{ Account = $standard_account; AccountSid = $standard_account_sid; Password = $standard_password }
        ) {
            Param ($Account, $AccountSid, [SecureString]$Password)
            $actual = Invoke-LogonUser -Username $Account -Password $Password

            try {
                $actual.GetType() | Should -Be ([System.Management.Automation.PSCustomObject])
                $actual[0].PSObject.TypeNames[0] | Should -Be 'PSAccessToken.LogonInfo'
                $entry_properties = $actual[0].PSObject.Properties
                $entry_properties.Value.Count | Should -Be 12
                $entry_properties.Name[0] | Should -Be 'Token'
                $entry_properties.TypeNameOfValue[0] | Should -Be 'PInvokeHelper.SafeNativeHandle'
                $entry_properties.Name[1] | Should -Be 'Username'
                $entry_properties.TypeNameOfValue[1] | Should -Be 'System.String'
                $entry_properties.Name[2] | Should -Be 'Domain'
                $entry_properties.TypeNameOfValue[2] | Should -Be 'System.String'
                $entry_properties.Name[3] | Should -Be 'LogonType'
                $entry_properties.TypeNameOfValue[3] | Should -Be 'PSAccessToken.LogonType'
                $entry_properties.Name[4] | Should -Be 'LogonId'
                $entry_properties.TypeNameOfValue[4] | Should -Be 'PSAccessToken.LUID'
                $entry_properties.Name[5] | Should -Be 'Profile'
                $entry_properties.TypeNameOfValue[5] | Should -Be 'PSAccessToken.InteractiveProfile'
                $entry_properties.Name[6] | Should -Be 'PagedPoolLimit'
                $entry_properties.TypeNameOfValue[6] | Should -Be 'System.UInt64'
                $entry_properties.Name[7] | Should -Be 'NonPagedPoolLimit'
                $entry_properties.TypeNameOfValue[7] | Should -Be 'System.UInt64'
                $entry_properties.Name[8] | Should -Be 'MinimumWorkingSetSize'
                $entry_properties.TypeNameOfValue[8] | Should -Be 'System.UInt64'
                $entry_properties.Name[9] | Should -Be 'MaximumWorkingSetSize'
                $entry_properties.TypeNameOfValue[9] | Should -Be 'System.UInt64'
                $entry_properties.Name[10] | Should -Be 'PagefileLimit'
                $entry_properties.TypeNameOfValue[10] | Should -Be 'System.UInt64'
                $entry_properties.Name[11] | Should -Be 'TimeLimit'
                $entry_properties.TypeNameOfValue[11] | Should -Be 'System.Int64'

                $profile_properties = $actual.Profile.PSObject.Properties
                $profile_properties.Value.Count | Should -Be 16
                $profile_properties.Name[0] | Should -Be 'MessageType'
                $profile_properties.TypeNameOfValue[0] | Should -Be 'PSAccessToken.ProfileBufferType'
                $profile_properties.Name[1] | Should -Be 'LogonCount'
                $profile_properties.TypeNameOfValue[1] | Should -Be 'System.UInt16'
                $profile_properties.Name[2] | Should -Be 'BadPasswordCount'
                $profile_properties.TypeNameOfValue[2] | Should -Be 'System.UInt16'
                $profile_properties.Name[3] | Should -Be 'UserFlags'
                $profile_properties.TypeNameOfValue[3] | Should -Be 'PSAccessToken.ProfileUserFlags'
                $profile_properties.Name[4] | Should -Be 'LogonTime'  # May not be set, cannot check type
                $profile_properties.Name[5] | Should -Be 'LogoffTime'  # May not be set, cannot check type
                $profile_properties.Name[6] | Should -Be 'KickOffTime'  # May not be set, cannot check type
                $profile_properties.Name[7] | Should -Be 'PasswordLastSet'
                $profile_properties.TypeNameOfValue[7] | Should -Be 'System.DateTime'
                $profile_properties.Name[8] | Should -Be 'PasswordCanChange'
                $profile_properties.TypeNameOfValue[8] | Should -Be 'System.DateTime'
                $profile_properties.Name[9] | Should -Be 'PasswordMustChange'  # May not be set, cannot check type

                # Cannot rely on these being set, just check the property name
                $profile_properties.Name[10] | Should -Be 'LogonScript'
                $profile_properties.Name[11] | Should -Be 'HomeDirectory'
                $profile_properties.Name[12] | Should -Be 'FullName'
                $profile_properties.Name[13] | Should -Be 'ProfilePath'
                $profile_properties.Name[14] | Should -Be 'HomeDirectoryDrive'
                $profile_properties.Name[15] | Should -Be 'LogonServer'

                $actual.Token.IsClosed | Should -Be $false
                $actual.Token.IsInvalid | Should -Be $false
                $actual.Username | Should -Be $Account
                $actual.LogonType | Should -Be 'Interactive'

                $actual_sess_data = Get-LogonSessionData -Token $actual.Token
                $actual_sess_data.LogonType | Should -Be 'Interactive'

                $actual_user = Get-TokenUser -Token $actual.Token
                $actual_user | Should -Be $AccountSid.Translate([System.Security.Principal.NTAccount])

                $actual_elevation_type = Get-TokenElevationType -Token $actual.Token
                $actual_elevation = Get-TokenElevation -Token $actual.Token
                if ($Account -eq $standard_account) {
                    $actual_elevation_type | Should -Be ([PSAccessToken.TokenElevationType]::Default)
                    $actual_elevation | Should -Be $false
                } else {
                    $actual_elevation_type | Should -Be ([PSAccessToken.TokenElevationType]::Limited)
                    $actual_elevation | Should -Be $false

                    $linked_token = Get-TokenLinkedToken -Token $actual.Token
                    try {
                        Get-TokenElevationType -Token $linked_token | Should -Be ([PSAccessToken.TokenElevationType]::Full)
                        Get-TokenElevation -Token $linked_token | Should -Be $true
                    } finally {
                        $linked_token.Dispose()
                    }
                }
            } finally {
                $actual.Token.Dispose()
            }
            $actual.Token.IsClosed | Should -Be $true
        }

        It 'Should log on with SID' {
            $actual = Invoke-LogonUser -Username $standard_account_sid -Password $standard_password
            try {
                $actual.Username | Should -Be $standard_account
            } finally {
                $actual.Token.Dispose()
            }
        }

        It 'Should log on with DOMAIN\Username form' {
            $account_name = $standard_account_sid.Translate([System.Security.Principal.NTAccount])
            $actual = Invoke-LogonUser -Username $account_name.Value -Password $standard_password
            try {
                $actual.Username | Should -Be $standard_account
                $actual.Domain | Should -Be $account_name.Value.Split('\')[0]
            } finally {
                $actual.Token.Dispose()
            }
        }

        It 'Should log on with <Type> logon type' -TestCases @(
            @{ Type = 'Interactive' },
            @{ Type = 'Batch' },
            @{ Type = 'Network' },
            @{ Type = 'NetworkCleartext' },
            @{ Type = 'NewCredentials' }
        ) {
            Param ($Type)

            $actual = Invoke-LogonUser -Username $admin_account -Password $admin_password -LogonType $Type
            try {
                $actual.LogonType | Should -Be $Type

                $session_data = Get-LogonSessionData -Token $actual.Token
                $session_data.LogonType | Should -Be $Type
            } finally {
                $actual.Token.Dispose()
            }
        }

        It 'Should log on a user with credential' {
            $cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $admin_account, $admin_password
            $actual = Invoke-LogonUser -Credential $cred
            try {
                $actual.Username | Should -Be $admin_account
                $actual.LogonType | Should -Be 'Interactive'
            } finally {
                $actual.Token.Dispose()
            }
        }

        It 'Should fail with invalid password' {
            $expected = "Failed to logon user '$standard_account': The user name or password is incorrect (Win32 ErrorCode 1326 - 0x0000052E) (LSA Sub Status: 0)"
            $ss_pass = ConvertTo-SecureString -String 'wrongpass' -AsPlainText -Force
            { Invoke-LogonUser -Username $standard_account -Password $ss_pass } | Should -Throw $expected
        }

        It 'Should log on to <Account> without a password' -TestCases @(
            @{ Account = $standard_account; LogonType = 'Network' },
            @{ Account = $admin_account; LogonType = 'Batch' }
        ) {
            Param ($Account, $LogonType)

            $system_token = Get-SystemToken
            try {
                Invoke-WithImpersonation -Token $system_token -ScriptBlock {
                    $param = @{
                        WarningAction = 'SilentlyContinue'
                        WarningVariable = 'warn'
                    }
                    if ($LogonType -ne 'Batch') {  # Verify that the default logon is Batch by not passing it in.
                        $param.LogonType = $LogonType
                    }

                    $warn = $null
                    $actual = Invoke-LogonUser -Username $Account -Password $null @param
                    try {
                        $warn | Should -Be $null  # Make sure we haven't raised a warning about the logon type.
                        $actual.Username | Should -Be $Account
                        $actual.LogonType | Should -Be $LogonType
                    } finally {
                        $actual.Token.Dispose()
                    }
                }
            } finally {
                $system_token.Dispose()
            }
        }

        It 'Should warn with invalid LogonType for passwordless logon' {
            $system_token = Get-SystemToken
            try {
                Invoke-WithImpersonation -Token $system_token -ScriptBlock {
                    $expected = 'Logon without a password does not support the logon type ''Interactive'', '
                    $expected += 'using Batch instead. Supported logon types: Batch, Network.'
                    $warn = $null
                    $actual = Invoke-LogonUser -Username $admin_account -Password $null -LogonType Interactive `
                        -WarningAction SilentlyContinue -WarningVariable warn
                    try {
                        $warn | Should -Be $expected
                        $actual.LogonType | Should -Be 'Batch'
                    } finally {
                        $actual.Token.Dispose()
                    }
                }
            } finally {
                $system_token.Dispose()
            }
        }

        It 'Should log on user with Network logon type' {
            $actual = Invoke-LogonUser -Username $standard_account -Password $standard_password -LogonType Network
            try {
                $actual.Profile.PSObject.TypeNames[0] | Should -Be 'PSAccessToken.Lm20Profile'
                $profile_properties = $actual.Profile.PSObject.Properties
                $profile_properties.Name[0] | Should -Be 'MessageType'
                $profile_properties.TypeNameOfValue[0] | Should -Be 'PSAccessToken.ProfileBufferType'
                $profile_properties.Name[1] | Should -Be 'UserFlags'
                $profile_properties.TypeNameOfValue[1] | Should -Be 'PSAccessToken.ProfileUserFlags'
                $profile_properties.Name[2] | Should -Be 'UserSessionKey'
                $profile_properties.TypeNameOfValue[2] | Should -Be 'System.Byte[]'
                $profile_properties.Name[3] | Should -Be 'LanmanSessionKey'
                $profile_properties.TypeNameOfValue[3] | Should -Be 'System.Byte[]'
                $profile_properties.Name[4] | Should -Be 'KickOffTime'  # May not be set, cannot check type
                $profile_properties.Name[5] | Should -Be 'LogoffTime'  # May not be set, cannot check type
                $profile_properties.Name[6] | Should -Be 'LogonDomainName'
                $profile_properties.TypeNameOfValue[6] | Should -Be 'System.String'
                $profile_properties.Name[7] | Should -Be 'LogonServer'
                $profile_properties.TypeNameOfValue[7] | Should -Be 'System.String'
                $profile_properties.Name[8] | Should -Be 'UserParameters'

                $actual.LogonType | Should -Be 'Network'
                (Get-LogonSessionData -Token $actual.Token).LogonType | Should -Be 'Network'
            } finally {
                $actual.Token.Dispose()
            }
        }

        It 'Should log on <Account> with custom groups' -TestCases @(
            @{ Account = $standard_account; Password = $standard_password; Groups = 'Replicator' },
            @{ Account = $admin_account; Password = $admin_password; Groups = @{ Sid = 'Replicator'; Attributes = 'UseForDenyOnly' } }
        ) {
            Param ($Account, [SecureString]$Password, $Groups)
            $system_token = Get-SystemToken

            try {
                Invoke-WithImpersonation -Token $system_token -ScriptBlock {
                    $actual = Invoke-LogonUser -Username $Account -Password $Password -Groups $Groups
                    try {
                        $token_groups = Get-TokenGroups -Token $actual.Token

                        if ($Groups -is [System.Collections.IDictionary]) {
                            $group_name = $Groups.Sid
                            $attributes = $Groups.Attributes
                        } else {
                            $group_name = $Groups
                            $attributes = 'Mandatory, EnabledByDefault, Enabled'
                        }
                        $group_sid = ConvertTo-SecurityIdentifier -InputObject $group_name

                        $found_group = $token_groups | Where-Object { $_.Sid -eq $group_sid }
                        $found_group | Should -Not -Be $null
                        $found_group.Attributes | Should -Be ([PSAccessToken.TokenGroupAttributes]$attributes)
                    } finally {
                        $actual.Token.Dispose()
                    }
                }
            } finally {
                $system_token.Dispose()
            }
        }

        It 'Should log onto well known SID account <Account>' -TestCases @(
            @{ Account = 'System'; Sid = 'S-1-5-18' },
            @{ Account = 'Local Service'; Sid = 'S-1-5-19' },
            @{ Account = 'Network Service'; Sid = 'S-1-5-20' }
        ) {
            Param ($Account, $Sid)

            $system_token = Get-SystemToken

            try {
                Invoke-WithImpersonation -Token $system_token -ScriptBlock {
                    $warn = $null
                    $actual = Invoke-LogonUser -Username $Account -Password $null -WarningAction SilentlyContinue -WarningVariable warn
                    try {
                        $warn | Should -Be $null  # Make sure we don't raise a warning when not specifying the logon type

                        $token_user = Get-TokenUser -Token $actual.Token

                        $actual.Profile | Should -Be $null
                        $actual.LogonType | Should -Be 'Service'
                        $token_user.Translate([System.Security.Principal.SecurityIdentifier]) | Should -Be $Sid
                    } finally {
                        $actual.Token.Dispose()
                    }
                }
            } finally {
                $system_token.Dispose()
            }
        }

        It 'Should should warn on invalid logon type for a well known SID account' {
            $system_token = Get-SystemToken

            try {
                Invoke-WithImpersonation -Token $system_token -ScriptBlock {
                    $expected = 'Logon as a service account does not support the logon type ''Interactive'', using Service instead.'
                    $warn = $null
                    $actual = Invoke-LogonUser -Username 'SYSTEM' -Password $null -LogonType Interactive `
                        -WarningAction SilentlyContinue -WarningVariable warn
                    try {
                        $warn | Should -Be $expected
                        $actual.LogonType | Should -Be 'Service'
                    } finally {
                        $actual.Token.Dispose()
                    }
                }
            } finally {
                $system_token.Dispose()
            }
        }

        It 'Should fail when SeTcbPrivilege is not present with passwordless logon' {
            $expected = 'Cannot open a trusted LSA connection as the caller does not have the SeTcbPrivilege'
            { Invoke-LogonUser -Username 'SYSTEM' -Password $null } | Should -Throw $expected
        }

        It 'Should fail when SeTcbPrivilege is not present with the -Groups option' {
            $expected = 'Cannot open a trusted LSA connection as the caller does not have the SeTcbPrivilege'
            { Invoke-LogonUser -Username $standard_account -Password $standard_password -Groups @('Administrators') } | Should -Throw $expected
        }

        It 'Should fail with invalid authentication package' {
            $expected = 'Failed to get LSA authentication package ID for ''Fake'': '
            $expected += 'A specified authentication package is unknown (Win32 ErrorCode 1364 - 0x00000554)'
            { Invoke-LogonUser -Username $standard_account -Password $standard_password -AuthenticationPackage 'Fake' } | Should -Throw $expected
        }
    }
}
