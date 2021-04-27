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

        It 'Should invoke with added privilege' {
            $expected_user = Get-TokenUser
            $expected_groups = Get-TokenGroups
            $existing_privilege_count = (Get-TokenPrivileges).Length
            $expected_owner = Get-TokenOwner
            $expected_primary_group = Get-TokenPrimaryGroup
            $expected_dacl = Get-TokenDefaultDacl

            $actual = Invoke-WithPrivilege -Privilege SeCreateTokenPrivilege -ScriptBlock {
                Get-TokenUser | Should -Be $expected_user
                (Get-TokenGroups).Length | Should -Be $expected_groups.Length
                Get-TokenOwner | Should -Be $expected_owner
                Get-TokenPrimaryGroup | Should -Be $expected_primary_group
                (Get-TokenDefaultDacl).Count | Should -Be $expected_dacl.Count

                $token_privileges = Get-TokenPrivileges
                $token_privileges.Length | Should -Be ($existing_privilege_count + 1)
                ($token_privileges | Where-Object { $_.Name -eq 'SeCreateTokenPrivilege' }).Attributes | Should -Be 'EnabledByDefault, Enabled'
            }
            $actual | Should -Be $null
        }

        It 'Should invoke with explicit privileges' {
            $actual = Invoke-WithPrivilege -Privilege SeCreateTokenPrivilege, SeTcbPrivilege -ClearExistingPrivileges -ScriptBlock {
                $token_privileges = Get-TokenPrivileges

                $token_privileges.Length | Should -Be 2
                $token_privileges[0].Name | Should -Be 'SeCreateTokenPrivilege'
                $token_privileges[0].Attributes | Should -Be 'EnabledByDefault, Enabled'
                $token_privileges[1].Name | Should -Be 'SeTcbPrivilege'
                $token_privileges[1].Attributes | Should -Be 'EnabledByDefault, Enabled'
            }
            $actual | Should -Be $null
        }
    }
}