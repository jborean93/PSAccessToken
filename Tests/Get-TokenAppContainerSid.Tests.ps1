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

        It 'Gets the AppContainer Sid for current process' {
            $actual = Get-TokenAppContainerSid

            $actual | Should -Be $null
        }

        It 'Gets the AppContainer SID based on a PID' {
            $actual = Get-TokenAppContainerSid -ProcessId $PID

            $actual | Should -Be $null
        }

        It 'Gets the AppContainer SID based on an explicit token' {
            $h_token = Open-ProcessToken
            try {
                $actual = Get-TokenAppContainerSid -Token $h_token
            } finally {
                $h_token.Dispose()
            }

            $actual | Should -Be $null
        }

        It 'Gets AppContainer SID for an actual AppContainer' {
            $h_token = New-LowBoxToken -AppContainer 'TestContainer1' -Capabilities @()
            try {
                $actual = Get-TokenAppContainerSid -Token $h_token

                $actual | Should -Be 'S-1-15-2-3527424397-42422233-3524195815-1686030626-3157169321-2713159295-2306415250'
            } finally {
                $h_token.Dispose()
            }
        }
    }
}