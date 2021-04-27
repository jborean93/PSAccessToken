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

        It 'Gets the token capabilities for current process' {
            $actual = Get-TokenCapabilities

            $actual | Should -Be $null
        }

        It 'Gets the token groups based on a PID' {
            $actual = Get-TokenCapabilities -ProcessId $PID

            $actual | Should -Be $null
        }

        It 'Gets the token based on an explicit token' {
            $h_token = Open-ProcessToken
            try {
                $actual = Get-TokenCapabilities -Token $h_token
            } finally {
                $h_token.Dispose()
            }

            $actual | Should -Be $null
        }

        It 'Gets the token capabilities for AppContainer without capabilities' {
            $h_token = New-LowBoxToken -AppContainer 'TestContainer' -Capabilities @()
            try {
                $actual = Get-TokenCapabilities -Token $h_token
            } finally {
                $h_token.Dispose()
            }

            $actual | Should -Be $null
        }

        It 'Gets the token capabilities for AppContainer with capabilities' {
            $h_token = New-LowBoxToken -AppContainer 'TestContainer' -Capabilities @(
                'S-1-15-3-3215430884-1339816292-89257616-1145831019',
                'S-1-15-3-3845273463-1331427702-1186551195-114810997'
            )
            try {
                $actual = Get-TokenCapabilities -Token $h_token
            } finally {
                $h_token.Dispose()
            }

            $actual.Length | Should -Be 2
            $actual[0].GetType() | Should -Be ([System.Management.Automation.PSCustomObject])
            $actual[0].GetType().FullName | Should -Be 'System.Management.Automation.PSCustomObject'
            $actual[0].PSObject.TypeNames[0] | Should -Be 'PSAccessToken.SidAndAttributes'
            $entry_properties = $actual[0].PSObject.Properties
            $entry_properties.Value.Count | Should -Be 3
            $entry_properties.Name[0] | Should -Be 'Account'
            $entry_properties.TypeNameOfValue[0] | Should -Be 'System.String'
            $entry_properties.Name[1] | Should -Be 'Sid'
            $entry_properties.TypeNameOfValue[1] | Should -Be 'System.Security.Principal.SecurityIdentifier'
            $entry_properties.Name[2] | Should -Be 'Attributes'
            $entry_properties.TypeNameOfValue[2] | Should -Be 'PSAccessToken.TokenGroupAttributes'

            $actual[0].Sid | Should -Be 'S-1-15-3-3215430884-1339816292-89257616-1145831019'
            $actual[0].Attributes | Should -Be 'Enabled'
            $actual[1].Sid | Should -Be 'S-1-15-3-3845273463-1331427702-1186551195-114810997'
            $actual[1].Attributes | Should -Be 'Enabled'
        }
    }
}