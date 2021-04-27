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

. $PSScriptRoot\..\$module_name\Private\Copy-StructureToPointer.ps1
. $PSScriptRoot\..\$module_name\Private\Convert-LuidToPrivilege.ps1
. $PSScriptRoot\..\$module_name\Private\Convert-PointerToPrivilegeAndAttributes.ps1
. $PSScriptRoot\..\$module_name\Private\Convert-PointerToTokenPrivileges.ps1
. $PSScriptRoot\..\$module_name\Private\Convert-PrivilegeToLuid.ps1
. $PSScriptRoot\..\$module_name\Private\Use-SafePointer.ps1

Describe "$cmdlet_name PS$ps_version tests" {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It 'Should update attributes of privilege instead of replacing' {
            @(
                'SeTcbPrivilege',
                @{ Name = 'SeRestorePrivilege'; Attributes = 'Enabled' },
                @{ Name = 'SeRestorePrivilege'; Attributes = 'EnabledByDefault' }
            ) | Use-TokenPrivilegesPointer -Process {
                Param ([System.IntPtr]$Ptr)

                $actual = Convert-PointerToTokenPrivileges -Ptr $Ptr

                $actual.Length | Should -Be 2
                $actual[0].Name | Should -Be 'SeTcbPrivilege'
                $actual[0].Attributes | Should -Be 'EnabledByDefault, Enabled'
                $actual[1].Name | Should -Be 'SeRestorePrivilege'
                $actual[1].Attributes | Should -Be 'EnabledByDefault, Enabled'
            }
        }

        It 'Should use PSCustomObject as input' {
            @(
                [PSCustomObject]@{ Name = 'SeRestorePrivilege'; Attributes = 'Enabled' },
                [PSCustomObject]@{ Name = 'SeBackupPrivilege' }
            ) | Use-TokenPrivilegesPointer -Process {
                Param ([System.IntPtr]$Ptr)

                $actual = Convert-PointerToTokenPrivileges -Ptr $Ptr

                $actual.Length | Should -Be 2
                $actual[0].Name | Should -Be 'SeRestorePrivilege'
                $actual[0].Attributes | Should -Be 'Enabled'
                $actual[1].Name | Should -Be 'SeBackupPrivilege'
                $actual[1].Attributes | Should -Be 'EnabledByDefault, Enabled'
            }
        }

        It 'Should fail without Name of Hashtable' {
            $expected = "Privileges entry does not contain key 'Name'"
            { @( @{ Attributes = 'Enabled' } ) | Use-TokenPrivilegesPointer -Process {} } | Should -Throw $expected
        }

        It 'Should fail without Name of PSCustomObject' {
            $expected = "Privileges entry does not contain key 'Name'"
            { @( [PSCustomObject]@{ Attributes = 'Enabled' } ) | Use-TokenPrivilegesPointer -Process {} } | Should -Throw $expected
        }
    }
}