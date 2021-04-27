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

        It 'Gets the token privileges for current process' {
            $actual = Get-TokenPrivileges

            $actual.GetType().IsArray | Should -Be $true
            $actual[0].GetType().FullName | Should -Be 'System.Management.Automation.PSCustomObject'
            $actual[0].PSObject.TypeNames[0] | Should -Be 'PSAccessToken.PrivilegeAndAttributes'
            $entry_properties = $actual[0].PSObject.Properties
            $entry_properties.Value.Count | Should -Be 2
            $entry_properties.Name[0] | Should -Be 'Name'
            $entry_properties.TypeNameOfValue[0] | Should -Be 'System.String'
            $entry_properties.Name[1] | Should -Be 'Attributes'
            $entry_properties.TypeNameOfValue[1] | Should -Be 'PSAccessToken.TokenPrivilegeAttributes'
        }

        It 'Gets the token privileges based on a PID' {
            $actual = Get-TokenPrivileges -ProcessId $PID

            $actual.GetType().IsArray | Should -Be $true
            $actual[0].GetType().FullName | Should -Be 'System.Management.Automation.PSCustomObject'
            $actual[0].PSObject.TypeNames[0] | Should -Be 'PSAccessToken.PrivilegeAndAttributes'
            $entry_properties = $actual[0].PSObject.Properties
            $entry_properties.Value.Count | Should -Be 2
            $entry_properties.Name[0] | Should -Be 'Name'
            $entry_properties.TypeNameOfValue[0] | Should -Be 'System.String'
            $entry_properties.Name[1] | Should -Be 'Attributes'
            $entry_properties.TypeNameOfValue[1] | Should -Be 'PSAccessToken.TokenPrivilegeAttributes'
        }

        It 'Gets the token based on an explicit token' {
            $h_token = Open-ProcessToken
            try {
                $actual = Get-TokenPrivileges -Token $h_token
            } finally {
                $h_token.Dispose()
            }

            $actual.GetType().IsArray | Should -Be $true
            $actual[0].GetType().FullName | Should -Be 'System.Management.Automation.PSCustomObject'
            $actual[0].PSObject.TypeNames[0] | Should -Be 'PSAccessToken.PrivilegeAndAttributes'
            $entry_properties = $actual[0].PSObject.Properties
            $entry_properties.Value.Count | Should -Be 2
            $entry_properties.Name[0] | Should -Be 'Name'
            $entry_properties.TypeNameOfValue[0] | Should -Be 'System.String'
            $entry_properties.Name[1] | Should -Be 'Attributes'
            $entry_properties.TypeNameOfValue[1] | Should -Be 'PSAccessToken.TokenPrivilegeAttributes'
        }
    }
}