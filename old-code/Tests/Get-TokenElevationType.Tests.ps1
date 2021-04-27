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
. $PSScriptRoot\TestUtils.ps1

Describe "$cmdlet_name PS$ps_version tests" {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It 'Gets the elevation type for current process' {
            $actual = Get-TokenElevationType

            $actual.GetType() | Should -Be ([PSAccessToken.TokenElevationType])
            $actual | Should -Be ([PSAccessToken.TokenElevationType]::Full)
        }

        It 'Gets the elevation type based on a PID' {
            $actual = Get-TokenElevationType -ProcessId $PID

            $actual.GetType() | Should -Be ([PSAccessToken.TokenElevationType])
            $actual | Should -Be ([PSAccessToken.TokenElevationType]::Full)
        }

        It 'Gets the elevation based on an explicit token' {
            $h_token = Open-ProcessToken
            try {
                $actual = Get-TokenElevationType -Token $h_token
            } finally {
                $h_token.Dispose()
            }

            $actual.GetType() | Should -Be ([PSAccessToken.TokenElevationType])
            $actual | Should -Be ([PSAccessToken.TokenElevationType]::Full)
        }

        It 'Gets the elevation type for a default token' {
            $system_token = Get-SystemToken
            try {
                Invoke-WithImpersonation -Token $system_token -ScriptBlock {
                    $actual = Get-TokenElevationType
                    $actual.GetType() | Should -Be ([PSAccessToken.TokenElevationType])
                    $actual | Should -Be ([PSAccessToken.TokenElevationType]::Default)
                }
            } finally {
                $system_token.Dispose()
            }
        }

        It 'Gets the elevation type for a limited token' {
            $linked_token = Get-TokenLinkedToken
            try {
                $actual = Get-TokenElevationType -Token $linked_token

                $actual.GetType() | Should -Be ([PSAccessToken.TokenElevationType])
                $actual | Should -Be ([PSAccessToken.TokenElevationType]::Limited)
            } finally {
                $linked_token.Dispose()
            }
        }
    }
}
