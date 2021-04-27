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

Describe "$cmdlet_name PS$ps_version tests" {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It 'Should get LUID for privilege' {
            $actual = Convert-PrivilegeToLuid -Name SeRestorePrivilege

            $actual.GetType() | Should -Be ([PSAccessToken.LUID])
        }

        It 'Should fail with invalid privilage' {
            $expected = "Failed to get LUID value for privilege 'SeFakePrivilege': A specified privilege does not exist (Win32 ErrorCode 1313 - 0x00000521)"
            { Convert-PrivilegeToLuid -Name SeFakePrivilege } | Should -Throw $expected
        }
    }
}