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
. $PSScriptRoot\..\$module_name\Private\$cmdlet_name.ps1
. $PSScriptRoot\..\$module_name\Private\Get-AuditSubCategoryName.ps1

Describe "$cmdlet_name PS$ps_version tests" {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It 'Should fail with invalid GUID' {
            $fake_guid = New-Object -TypeName System.Guid -ArgumentList '936DA01F-9ABD-4d9d-80C7-02AF85C822A8'
            $expected = 'Failed to get audit sub category list: The parameter is incorrect (Win32 ErrorCode 87 - 0x00000057)'
            { Get-AuditSubCategory -Category $fake_guid } | Should -Throw $expected
        }

        It 'Should return all sub categories on empty GUID' {
            $actual = Get-AuditSubCategory

            $actual.GetType().IsArray | Should -Be $true
            $actual[0].PSObject.TypeNames[0] | Should -Be 'PSAccessToken.AuditSubCategory'
            $entry_properties = $actual[0].PSObject.Properties
            $entry_properties.Value.Count | Should -Be 2
            $entry_properties.Name[0] | Should -Be 'Name'
            $entry_properties.TypeNameOfValue[0] | Should -Be 'System.String'
            $entry_properties.Name[1] | Should -Be 'Guid'
            $entry_properties.TypeNameOfValue[1] | Should -Be 'System.Guid'
        }
    }
}