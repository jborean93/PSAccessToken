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

Describe "$cmdlet_name PS$ps_version tests" {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It 'Gets the token groups and privileges for current process' {
            $actual = Get-TokenGroupsAndPrivileges

            $actual_groups = Get-TokenGroups
            $actual_privileges = Get-TokenPrivileges
            $actual_restricted_sids = Get-TokenRestrictedSids

            $actual.GetType().FullName | Should -Be 'System.Management.Automation.PSCustomObject'
            $actual.PSObject.TypeNames[0] | Should -Be 'PSAccessToken.TokenGroupsAndPrivileges'
            ($actual.PSObject.Properties.Name | Sort-Object) | Should -Be @(
                'AuthenticationId',
                'Groups',
                'Privileges',
                'RestrictedSids'
            )

            $actual.AuthenticationId.GetType() | Should -Be ([PSAccessToken.LUID])

            foreach ($group in $actual.Groups) {
                if ($group.Attributes -eq 0) {
                    # This group is not part of the Get-TokenGroups result
                    continue
                }
                $found = $actual_groups | Where-Object { $_.Sid -eq $group.Sid }
                $found | Should -Not -Be $null
                $found.Attributes | Should -Be $group.Attributes
            }

            foreach ($privilege in $actual.Privileges) {
                $found = $actual_privileges | Where-Object { $_.Name -eq $privilege.Name }
                $found | Should -Not -Be $null
                $found.Attributes | Should -Be $privilege.Attributes
            }

            foreach ($rsid in $actual.RestrictedSids) {
                $found = $actual_restricted_sids | Where-Object { $_.Sid -eq $group.Sid }
                $found | Should -Not -Be $null
                $found.Attributes | Should -Be $group.Attributes
            }
        }

        It 'Gets the token groups and privileges based on a PID' {
            $actual = Get-TokenGroupsAndPrivileges -ProcessId $PID

            $actual_groups = Get-TokenGroups -ProcessId $PID
            $actual_privileges = Get-TokenPrivileges -ProcessId $PID
            $actual_restricted_sids = Get-TokenRestrictedSids -ProcessId $PID

            $actual.GetType().FullName | Should -Be 'System.Management.Automation.PSCustomObject'
            $actual.PSObject.TypeNames[0] | Should -Be 'PSAccessToken.TokenGroupsAndPrivileges'
            ($actual.PSObject.Properties.Name | Sort-Object) | Should -Be @(
                'AuthenticationId',
                'Groups',
                'Privileges',
                'RestrictedSids'
            )

            $actual.AuthenticationId.GetType() | Should -Be ([PSAccessToken.LUID])

            foreach ($group in $actual.Groups) {
                if ($group.Attributes -eq 0) {
                    # This group is not part of the Get-TokenGroups result
                    continue
                }
                $found = $actual_groups | Where-Object { $_.Sid -eq $group.Sid }
                $found | Should -Not -Be $null
                $found.Attributes | Should -Be $group.Attributes
            }

            foreach ($privilege in $actual.Privileges) {
                $found = $actual_privileges | Where-Object { $_.Name -eq $privilege.Name }
                $found | Should -Not -Be $null
                $found.Attributes | Should -Be $privilege.Attributes
            }

            foreach ($rsid in $actual.RestrictedSids) {
                $found = $actual_restricted_sids | Where-Object { $_.Sid -eq $group.Sid }
                $found | Should -Not -Be $null
                $found.Attributes | Should -Be $group.Attributes
            }
        }

        It 'Gets the token based on an explicit token' {
            $h_token = New-RestrictedToken -RestrictedSids 'Users', 'Everyone'
            try {
                $actual = Get-TokenGroupsAndPrivileges -Token $h_token
            } finally {
                $h_token.Dispose()
            }

            $actual.GetType().FullName | Should -Be 'System.Management.Automation.PSCustomObject'
            $actual.PSObject.TypeNames[0] | Should -Be 'PSAccessToken.TokenGroupsAndPrivileges'
            ($actual.PSObject.Properties.Name | Sort-Object) | Should -Be @(
                'AuthenticationId',
                'Groups',
                'Privileges',
                'RestrictedSids'
            )

            $actual.RestrictedSids.Length | Should -Be 2
            'Users', 'Everyone' | ConvertTo-SecurityIdentifier | ForEach-Object -Process {
                $_ -in $actual.RestrictedSids.Sid | Should -Be $true
            }
        }
    }
}