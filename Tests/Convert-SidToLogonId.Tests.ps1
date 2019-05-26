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

        It 'Should fail with invalid SID form <InputObject>' -TestCases @(
            @{ InputObject = 'S-1-1-0' },
            @{ InputObject = 'S-1-5-5-0' },
            @{ InputObject = 'S-1-5-5-1-2-3' }
        ) {
            Param ($InputObject)

            $expected = "The input SID '$InputObject' does not match the pattern 'S-1-5-5-{High}-{Low}', not a valid LogonID."
            { Convert-SidToLogonId -InputObject $InputObject } | Should -Throw $expected
        }
    }
}