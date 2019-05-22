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

Describe "$cmdlet_name PS$ps_version tests" {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It 'Gets the token statistics for current process' {
            $actual = Get-TokenStatistics
            $group_count = (Get-TokenGroups).Length
            $privilege_count = (Get-TokenPrivileges).Length

            # Assert the structure
            $actual.GetType().FullName | Should -Be 'System.Management.Automation.PSCustomObject'
            $actual.PSObject.TypeNames[0] | Should -Be 'PSAccessToken.TokenStatistics'
            ($actual.PSObject.Properties.Name | Sort-Object) | Should -Be @(
                'AuthenticationId',
                'DynamicAvailable',
                'DynamicCharged'
                'ExpirationTime',
                'GroupCount'
                'ImpersonationLevel',
                'ModifiedId',
                'PrivilegeCount'
                'TokenId'
            )

            # Assert the values
            $actual.TokenId.GetType() | Should -Be ([PSAccessToken.LUID])
            $actual.AuthenticationId.GetType() | Should -Be ([PSAccessToken.LUID])
            $actual.ExpirationTime.GetType() | Should -Be ([System.Int64])
            $actual.ImpersonationLevel | Should -Be ([System.Security.Principal.TokenImpersonationLevel]::None)
            $actual.DynamicCharged.GetType() | Should -Be ([System.UInt32])
            $actual.DynamicAvailable.GetType() | Should -Be ([System.UInt32])
            $actual.GroupCount | Should -Be $group_count
            $actual.PrivilegeCount | Should -Be $privilege_count
            $actual.ModifiedId.GetType() | Should -Be ([PSAccessToken.LUID])
        }

        It 'Gets the token statistics based on a PID' {
            $actual = Get-TokenStatistics -ProcessId $PID
            $group_count = (Get-TokenGroups).Length
            $privilege_count = (Get-TokenPrivileges).Length

            # Assert the structure
            $actual.GetType().FullName | Should -Be 'System.Management.Automation.PSCustomObject'
            $actual.PSObject.TypeNames[0] | Should -Be 'PSAccessToken.TokenStatistics'
            ($actual.PSObject.Properties.Name | Sort-Object) | Should -Be @(
                'AuthenticationId',
                'DynamicAvailable',
                'DynamicCharged'
                'ExpirationTime',
                'GroupCount'
                'ImpersonationLevel',
                'ModifiedId',
                'PrivilegeCount'
                'TokenId'
            )

            # Assert the values
            $actual.TokenId.GetType() | Should -Be ([PSAccessToken.LUID])
            $actual.AuthenticationId.GetType() | Should -Be ([PSAccessToken.LUID])
            $actual.ExpirationTime.GetType() | Should -Be ([System.Int64])
            $actual.ImpersonationLevel | Should -Be ([System.Security.Principal.TokenImpersonationLevel]::None)
            $actual.DynamicCharged.GetType() | Should -Be ([System.UInt32])
            $actual.DynamicAvailable.GetType() | Should -Be ([System.UInt32])
            $actual.GroupCount | Should -Be $group_count
            $actual.PrivilegeCount | Should -Be $privilege_count
            $actual.ModifiedId.GetType() | Should -Be ([PSAccessToken.LUID])
        }

        It 'Gets the token based on an explicit token' {
            $h_token = Open-ProcessToken
            try {
                $actual = Get-TokenStatistics -Token $h_token
                $group_count = (Get-TokenGroups).Length
                $privilege_count = (Get-TokenPrivileges).Length
            } finally {
                $h_token.Dispose()
            }

            # Assert the structure
            $actual.GetType().FullName | Should -Be 'System.Management.Automation.PSCustomObject'
            $actual.PSObject.TypeNames[0] | Should -Be 'PSAccessToken.TokenStatistics'
            ($actual.PSObject.Properties.Name | Sort-Object) | Should -Be @(
                'AuthenticationId',
                'DynamicAvailable',
                'DynamicCharged'
                'ExpirationTime',
                'GroupCount'
                'ImpersonationLevel',
                'ModifiedId',
                'PrivilegeCount'
                'TokenId'
            )

            # Assert the values
            $actual.TokenId.GetType() | Should -Be ([PSAccessToken.LUID])
            $actual.AuthenticationId.GetType() | Should -Be ([PSAccessToken.LUID])
            $actual.ExpirationTime.GetType() | Should -Be ([System.Int64])
            $actual.ImpersonationLevel | Should -Be ([System.Security.Principal.TokenImpersonationLevel]::None)
            $actual.DynamicCharged.GetType() | Should -Be ([System.UInt32])
            $actual.DynamicAvailable.GetType() | Should -Be ([System.UInt32])
            $actual.GroupCount | Should -Be $group_count
            $actual.PrivilegeCount | Should -Be $privilege_count
            $actual.ModifiedId.GetType() | Should -Be ([PSAccessToken.LUID])
        }

        It 'Gets the token statistics for impersonation <Level> token' -TestCases @(
            @{ Level = [System.Security.Principal.TokenImpersonationLevel]::Anonymous },
            @{ Level = [System.Security.Principal.TokenImpersonationLevel]::Identification },
            @{ Level = [System.Security.Principal.TokenImpersonationLevel]::Impersonation },
            @{ Level = [System.Security.Principal.TokenImpersonationLevel]::Delegation }
        ) {
            Param ($Level)

            $h_token = Copy-AccessToken -ImpersonationLevel $Level
            try {
                $actual = Get-TokenStatistics -Token $h_token

                $actual.ImpersonationLevel | Should -Be $Level
            } finally {
                $h_token.Dispose()
            }
        }
    }
}