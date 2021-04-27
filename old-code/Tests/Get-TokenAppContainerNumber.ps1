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

        It 'Gets the AppContainer number for current process' {
            $actual = Get-TokenAppContainerNumber

            $actual | Should -Be 0
        }

        It 'Gets the AppContainer number based on a PID' {
            $actual = Get-TokenAppContainerNumber -ProcessId $PID

            $actual | Should -Be 0
        }

        It 'Gets the AppContainer number based on an explicit token' {
            $h_token = Open-ProcessToken
            try {
                $actual = Get-TokenAppContainerNumber -Token $h_token
            } finally {
                $h_token.Dispose()
            }

            $actual | Should -Be 0
        }

        It 'Gets AppContainer number for an actual AppContainer' {
            $h_token = New-LowBoxToken -AppContainer 'TestContainer1' -Capabilities @()
            try {
                $actual = Get-TokenAppContainerNumber -Token $h_token

                $actual | Should -Not -Be 0
                $actual | Should -Be (Get-TokenAccessInformation -Token $h_token).AppContainerNumber
            } finally {
                $h_token.Dispose()
            }
        }
    }
}