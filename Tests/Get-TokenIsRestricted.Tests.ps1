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

        It 'Gets the is restricted for current process' {
            $actual = Get-TokenIsRestricted

            $actual | Should -Be $false
        }

        It 'Gets the is restricted enabled based on a PID' {
            $actual = Get-TokenIsRestricted -ProcessId $PID

            $actual | Should -Be $false
        }

        It 'Gets the is restricted enabled based on an explicit token' {
            $h_token = Open-ProcessToken
            try {
                $actual = Get-TokenIsRestricted -Token $h_token
            } finally {
                $h_token.Dispose()
            }

            $actual | Should -Be $false
        }

        It 'Get IsRestricted with a restricted token' {
            $restricted_token = New-RestrictedToken -RestrictedSids 'S-1-5-32-544'
            try {
                $actual = Get-TokenIsRestricted -Token $restricted_token

                $actual | Should -Be $true
            } finally {
                $restricted_token.Dispose()
            }
        }
    }
}
