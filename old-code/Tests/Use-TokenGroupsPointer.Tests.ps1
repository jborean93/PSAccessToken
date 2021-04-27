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
. $PSScriptRoot\..\$module_name\Private\Convert-PointerToSidAndAttributes.ps1
. $PSScriptRoot\..\$module_name\Private\Convert-PointerToTokenGroups.ps1
. $PSScriptRoot\..\$module_name\Private\ConvertFrom-SecurityIdentifier.ps1
. $PSScriptRoot\..\$module_name\Private\ConvertTo-SecurityIdentifier.ps1
. $PSScriptRoot\..\$module_name\Private\ConvertTo-SidAndAttributes.ps1
. $PSScriptRoot\..\$module_name\Private\Copy-SidToPointer.ps1
. $PSScriptRoot\..\$module_name\Private\Copy-StructureToPointer.ps1
. $PSScriptRoot\..\$module_name\Private\Use-SafePointer.ps1


Describe "$cmdlet_name PS$ps_version tests" {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It 'Should update attributes of group instead of replacing' {
            @(
                'Users',
                @{ Sid = 'Administrators'; Attributes = 'Enabled' },
                [PSCustomObject]@{ Sid = 'Administrators'; Attributes = 'LogonId' }
            ) | Use-TokenGroupsPointer -Process {
                Param ([System.IntPtr]$Ptr)

                $actual = Convert-PointerToTokenGroups -Ptr $Ptr

                $actual.Length | Should -Be 2
                $actual[0].Sid | Should -Be 'S-1-5-32-545'
                $actual[0].Attributes | Should -Be 'Mandatory, EnabledByDefault, Enabled'
                $actual[1].Sid | Should -Be 'S-1-5-32-544'
                $actual[1].Attributes | Should -Be 'Enabled, LogonId'
            }
        }

        It 'Should use PSCustomObject as input' {
            @(
                [PSCustomObject]@{ Sid = 'Administrators'; Attributes = 'LogonId' },
                [PSCustomObject]@{ Sid = 'Administrators' }
            ) | Use-TokenGroupsPointer -Process {
                Param ([System.IntPtr]$Ptr)

                $actual = Convert-PointerToTokenGroups -Ptr $Ptr

                $actual.Sid | Should -Be 'S-1-5-32-544'
                $actual.Attributes | Should -Be 'Mandatory, EnabledByDefault, Enabled, LogonId'
            }
        }

        It 'Should fail without Name of Hashtable' {
            $expected = "Groups entry does not contain key 'Sid'"
            { @( @{ Attributes = 'Enabled' } ) | Use-TokenGroupsPointer -Process {} } | Should -Throw $expected
        }

        It 'Should fail without Name of PSCustomObject' {
            $expected = "Groups entry does not contain key 'Sid'"
            { @( [PSCustomObject]@{ Attributes = 'Enabled' } ) | Use-TokenGroupsPointer -Process {} } | Should -Throw $expected
        }
    }
}