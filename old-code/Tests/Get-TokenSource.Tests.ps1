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

        It 'Gets the token source for current process' {
            $actual = Get-TokenSource

            $properties = $actual.PSObject.Properties
            $properties.Value.Count | Should -Be 2
            $properties.Name[0] | Should -Be 'Name'
            $properties.TypeNameOfValue[0] | Should -Be 'System.String'
            $properties.Name[1] | Should -Be 'Id'
            $properties.TypeNameOfValue[1] | Should -Be 'PSAccessToken.LUID'

            $actual.PSObject.TypeNames[0] | Should -Be 'PSAccessToken.TokenSource'
        }

        It 'Gets the token user based on a PID' {
            $actual = Get-TokenSource -ProcessId $PID

            $actual.PSObject.TypeNames[0] | Should -Be 'PSAccessToken.TokenSource'
        }

        It 'Gets the token based on an explicit token' {
            $h_token = Open-ProcessToken -Access QuerySource
            try {
                $actual = Get-TokenSource -Token $h_token
            } finally {
                $h_token.Dispose()
            }

            $actual.PSObject.TypeNames[0] | Should -Be 'PSAccessToken.TokenSource'
        }
    }
}