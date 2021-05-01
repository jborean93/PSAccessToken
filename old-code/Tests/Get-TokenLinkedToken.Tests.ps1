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

        It 'Gets the Identification linked token for the current process' {
            $actual = Get-TokenLinkedToken
            try {
                $actual.IsClosed | Should -Be $false
                $actual.IsInvalid | Should -Be $false

                $actual_elevation_type = Get-TokenElevationType -Token $actual
                $actual_imp_level = Get-TokenImpersonationLevel -Token $actual

                $actual_elevation_type | Should -Be ([PSAccessToken.TokenElevationType]::Limited)
                $actual_imp_level | Should -Be ([System.Security.Principal.TokenImpersonationLevel]::Identification)
            } finally {
                $actual.Dispose()
            }
            $actual.IsClosed | Should -Be $true
        }

        It 'Gets a primary limited linked token' {
            Invoke-WithPrivilege -Privilege SeTcbPrivilege -ScriptBlock {
                # Checks that the privilege is enabled inside the cmdlet.
                Set-TokenPrivileges -Name SeTcbPrivilege -Attributes Disabled

                $actual = Get-TokenLinkedToken -UseProcessToken
                try {
                    $actual_privileges = Get-TokenPrivileges
                    $actual_elevation_type = Get-TokenElevationType -Token $actual
                    $actual_imp_level = Get-TokenImpersonationLevel -Token $actual

                    # Verifies the privilege was not kept as enabled
                    ($actual_privileges | Where-Object { $_.Name -eq 'SeTcbPrivilege' }).Attributes | Should -Be 'EnabledByDefault'
                    $actual_elevation_type | Should -Be ([PSAccessToken.TokenElevationType]::Limited)
                    $actual_imp_level | Should -Be ([System.Security.Principal.TokenImpersonationLevel]::None)
                } finally {
                    $actual.Dispose()
                }
            }
        }

        It 'Gets the elevation type based on a PID' {
            $actual = Get-TokenLinkedToken -ProcessId $PID
            try {
                $actual.IsClosed | Should -Be $false
                $actual.IsInvalid | Should -Be $false

                $actual_elevation_type = Get-TokenElevationType -Token $actual
                $actual_imp_level = Get-TokenImpersonationLevel -Token $actual

                $actual_elevation_type | Should -Be ([PSAccessToken.TokenElevationType]::Limited)
                $actual_imp_level | Should -Be ([System.Security.Principal.TokenImpersonationLevel]::Identification)
            } finally {
                $actual.Dispose()
            }
            $actual.IsClosed | Should -Be $true
        }

        It 'Gets the elevation based on an explicit token' {
            $h_token = Open-ProcessToken
            try {
                $actual = Get-TokenLinkedToken -Token $h_token
                try {
                    $actual.IsClosed | Should -Be $false
                    $actual.IsInvalid | Should -Be $false

                    $actual_elevation_type = Get-TokenElevationType -Token $actual
                    $actual_imp_level = Get-TokenImpersonationLevel -Token $actual

                    $actual_elevation_type | Should -Be ([PSAccessToken.TokenElevationType]::Limited)
                    $actual_imp_level | Should -Be ([System.Security.Principal.TokenImpersonationLevel]::Identification)
                } finally {
                    $actual.Dispose()
                }
            } finally {
                $h_token.Dispose()
            }
        }
    }
}
