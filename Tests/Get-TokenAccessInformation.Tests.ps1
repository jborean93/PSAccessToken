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

        It 'Gets the token access information for current process' {
            $actual = Get-TokenAccessInformation

            $group_count = (Get-TokenGroups).Length
            $privilege_count = (Get-TokenPrivileges).Length

            # Assert the structure
            $actual.GetType().FullName | Should -Be 'System.Management.Automation.PSCustomObject'
            $actual.PSObject.TypeNames[0] | Should -Be 'PSAccessToken.TokenAccessInformation'
            $actual.PSObject.Properties.Name | Should -Be @(
                'SidHash',
                'RestrictedSidHash',
                'Privileges'
                'AuthenticationId',
                'ImpersonationLevel'
                'MandatoryPolicy',
                'AppContainerNumber',
                'PackageSid'
                'CapabilitiesHash',
                'TrustLevelSid'
            )

            # Assert the values
            $actual.SidHash.PSObject.TypeNames[0] | Should -Be 'PSAccessToken.SidAndAttributesHash'
            $actual.RestrictedSidHash.PSObject.TypeNames[0] | Should -Be 'PSAccessToken.SidAndAttributesHash'
            $actual.Privileges[0].PSObject.TypeNames[0] | Should -Be 'PSAccessToken.PrivilegeAndAttributes'
            $actual.AuthenticationId.GetType() | Should -Be ([PSAccessToken.LUID])
            $actual.ImpersonationLevel | Should -Be ([System.Security.Principal.TokenImpersonationLevel]::None)
            $actual.MandatoryPolicy | Should -Be ([PSAccessToken.TokenMandatoryPolicy]::NoWriteUp)
            $actual.AppContainerNumber | Should -Be 0
            $actual.PackageSid | Should -Be $null
            $actual.CapabilitiesHash.PSObject.TypeNames[0] | Should -Be 'PSAccessToken.SidAndAttributesHash'
            $actual.TrustLevelSid | Should -Be $null

            $actual.SidHash.Sids.Length | Should -Be ($group_count + 1)  # Include the current user as well
            $actual.RestrictedSidHash.Sids | Should -Be $null
            $actual.Privileges.Length | Should -Be $privilege_count
        }

        It 'Gets the token statistics based on a PID' {
            $actual = Get-TokenAccessInformation -ProcessId $PID

            $group_count = (Get-TokenGroups).Length
            $privilege_count = (Get-TokenPrivileges).Length

            # Assert the structure
            $actual.GetType().FullName | Should -Be 'System.Management.Automation.PSCustomObject'
            $actual.PSObject.TypeNames[0] | Should -Be 'PSAccessToken.TokenAccessInformation'
            $actual.PSObject.Properties.Name | Should -Be @(
                'SidHash',
                'RestrictedSidHash',
                'Privileges'
                'AuthenticationId',
                'ImpersonationLevel'
                'MandatoryPolicy',
                'AppContainerNumber',
                'PackageSid'
                'CapabilitiesHash',
                'TrustLevelSid'
            )

            # Assert the values
            $actual.SidHash.PSObject.TypeNames[0] | Should -Be 'PSAccessToken.SidAndAttributesHash'
            $actual.RestrictedSidHash.PSObject.TypeNames[0] | Should -Be 'PSAccessToken.SidAndAttributesHash'
            $actual.Privileges[0].PSObject.TypeNames[0] | Should -Be 'PSAccessToken.PrivilegeAndAttributes'
            $actual.AuthenticationId.GetType() | Should -Be ([PSAccessToken.LUID])
            $actual.ImpersonationLevel | Should -Be ([System.Security.Principal.TokenImpersonationLevel]::None)
            $actual.MandatoryPolicy | Should -Be ([PSAccessToken.TokenMandatoryPolicy]::NoWriteUp)
            $actual.AppContainerNumber | Should -Be 0
            $actual.PackageSid | Should -Be $null
            $actual.CapabilitiesHash.PSObject.TypeNames[0] | Should -Be 'PSAccessToken.SidAndAttributesHash'
            $actual.TrustLevelSid | Should -Be $null

            $actual.SidHash.Sids.Length | Should -Be ($group_count + 1)  # Include the current user as well
            $actual.RestrictedSidHash.Sids | Should -Be $null
            $actual.Privileges.Length | Should -Be $privilege_count
        }

        It 'Gets the token based on an explicit token' {
            $h_token = Open-ProcessToken
            try {
                $actual = Get-TokenAccessInformation -Token $h_token
                $group_count = (Get-TokenGroups).Length
                $privilege_count = (Get-TokenPrivileges).Length
            } finally {
                $h_token.Dispose()
            }

            # Assert the structure
            $actual.GetType().FullName | Should -Be 'System.Management.Automation.PSCustomObject'
            $actual.PSObject.TypeNames[0] | Should -Be 'PSAccessToken.TokenAccessInformation'
            $actual.PSObject.Properties.Name | Should -Be @(
                'SidHash',
                'RestrictedSidHash',
                'Privileges'
                'AuthenticationId',
                'ImpersonationLevel'
                'MandatoryPolicy',
                'AppContainerNumber',
                'PackageSid'
                'CapabilitiesHash',
                'TrustLevelSid'
            )

            # Assert the values
            $actual.SidHash.PSObject.TypeNames[0] | Should -Be 'PSAccessToken.SidAndAttributesHash'
            $actual.RestrictedSidHash.PSObject.TypeNames[0] | Should -Be 'PSAccessToken.SidAndAttributesHash'
            $actual.Privileges[0].PSObject.TypeNames[0] | Should -Be 'PSAccessToken.PrivilegeAndAttributes'
            $actual.AuthenticationId.GetType() | Should -Be ([PSAccessToken.LUID])
            $actual.ImpersonationLevel | Should -Be ([System.Security.Principal.TokenImpersonationLevel]::None)
            $actual.MandatoryPolicy | Should -Be ([PSAccessToken.TokenMandatoryPolicy]::NoWriteUp)
            $actual.AppContainerNumber | Should -Be 0
            $actual.PackageSid | Should -Be $null
            $actual.CapabilitiesHash.PSObject.TypeNames[0] | Should -Be 'PSAccessToken.SidAndAttributesHash'
            $actual.TrustLevelSid | Should -Be $null

            $actual.SidHash.Sids.Length | Should -Be ($group_count + 1)  # Include the current user as well
            $actual.RestrictedSidHash.Sids | Should -Be $null
            $actual.Privileges.Length | Should -Be $privilege_count
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
                $actual = Get-TokenAccessInformation -Token $h_token

                $actual.ImpersonationLevel | Should -Be $Level
            } finally {
                $h_token.Dispose()
            }
        }
    }
}