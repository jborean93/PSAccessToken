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

        It 'Gets the is private namespace for current process' {
            $actual = Get-TokenPrivateNameSpace

            $actual | Should -Be $false
        }

        It 'Gets the is private namespace based on a PID' {
            $actual = Get-TokenPrivateNameSpace -ProcessId $PID

            $actual | Should -Be $false
        }

        It 'Gets the is private namespace based on an explicit token' {
            $h_token = Open-ProcessToken
            try {
                $actual = Get-TokenPrivateNameSpace -Token $h_token
            } finally {
                $h_token.Dispose()
            }

            $actual | Should -Be $false
        }
    }
}