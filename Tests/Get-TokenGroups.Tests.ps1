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

        It 'Gets the token groups for current process' {
            $actual = Get-TokenGroups

            $actual.GetType().IsArray | Should -Be $true
            $actual[0].GetType().FullName | Should -Be 'System.Management.Automation.PSCustomObject'
            $actual[0].PSObject.TypeNames[0] | Should -Be 'PSAccessToken.SidAndAttributes'
            $entry_properties = $actual[0].PSObject.Properties
            $entry_properties.Value.Count | Should -Be 2
            $entry_properties.Name[0] | Should -Be 'Sid'
            $entry_properties.TypeNameOfValue[0] | Should -Be 'System.Security.Principal.SecurityIdentifier'
            $entry_properties.Name[1] | Should -Be 'Attributes'
            $entry_properties.TypeNameOfValue[1] | Should -Be 'PSAccessToken.TokenGroupAttributes'

            $expected_groups = [System.Security.Principal.WindowsIdentity]::GetCurrent().Groups
            foreach ($expected_group in $expected_groups) {
                $expected_group -in $actual.Sid | Should -Be $true
            }
        }

        It 'Gets the token groups based on a PID' {
            $actual = Get-TokenGroups -ProcessId $PID

            $actual.GetType().IsArray | Should -Be $true
            $actual[0].GetType().FullName | Should -Be 'System.Management.Automation.PSCustomObject'
            $actual[0].PSObject.TypeNames[0] | Should -Be 'PSAccessToken.SidAndAttributes'
            $entry_properties = $actual[0].PSObject.Properties
            $entry_properties.Value.Count | Should -Be 2
            $entry_properties.Name[0] | Should -Be 'Sid'
            $entry_properties.TypeNameOfValue[0] | Should -Be 'System.Security.Principal.SecurityIdentifier'
            $entry_properties.Name[1] | Should -Be 'Attributes'
            $entry_properties.TypeNameOfValue[1] | Should -Be 'PSAccessToken.TokenGroupAttributes'
        }

        It 'Gets the token based on an explicit token' {
            $h_token = Open-ProcessToken
            try {
                $actual = Get-TokenGroups -Token $h_token
            } finally {
                $h_token.Dispose()
            }

            $actual.GetType().IsArray | Should -Be $true
            $actual[0].GetType().FullName | Should -Be 'System.Management.Automation.PSCustomObject'
            $actual[0].PSObject.TypeNames[0] | Should -Be 'PSAccessToken.SidAndAttributes'
            $entry_properties = $actual[0].PSObject.Properties
            $entry_properties.Value.Count | Should -Be 2
            $entry_properties.Name[0] | Should -Be 'Sid'
            $entry_properties.TypeNameOfValue[0] | Should -Be 'System.Security.Principal.SecurityIdentifier'
            $entry_properties.Name[1] | Should -Be 'Attributes'
            $entry_properties.TypeNameOfValue[1] | Should -Be 'PSAccessToken.TokenGroupAttributes'
        }
    }
}