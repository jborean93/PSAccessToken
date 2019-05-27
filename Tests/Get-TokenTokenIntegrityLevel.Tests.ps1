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
. $PSScriptRoot\TestUtils.ps1

Describe "$cmdlet_name PS$ps_version tests" {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It 'Gets the integrity level for current process' {
            $expected_sid = [System.Security.Principal.SecurityIdentifier]'S-1-16-12288'
            $expected_label = New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList 'Mandatory Label', 'High Mandatory Label'
            $actual = Get-TokenIntegrityLevel

            $actual.GetType() | Should -Be ([System.Management.Automation.PSCustomObject])
            $actual.PSObject.TypeNames[0] | Should -Be 'PSAccessToken.TokenIntegrityLevel'
            $actual.Sid | Should -Be $expected_sid
            $actual.Label | Should -Be $expected_label
            $actual.Attributes | Should -Be 'Integrity, IntegrityEnabled'
        }

        It 'Gets the integrity level based on a PID' {
            $expected_sid = [System.Security.Principal.SecurityIdentifier]'S-1-16-12288'
            $expected_label = New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList 'Mandatory Label', 'High Mandatory Label'
            $actual = Get-TokenIntegrityLevel -Process $PID

            $actual.GetType() | Should -Be ([System.Management.Automation.PSCustomObject])
            $actual.PSObject.TypeNames[0] | Should -Be 'PSAccessToken.TokenIntegrityLevel'
            $actual.Sid | Should -Be $expected_sid
            $actual.Label | Should -Be $expected_label
            $actual.Attributes | Should -Be 'Integrity, IntegrityEnabled'
        }

        It 'Gets the integrity level for the system token' {
            $expected_sid = [System.Security.Principal.SecurityIdentifier]'S-1-16-16384'
            $expected_label = New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList 'Mandatory Label', 'System Mandatory Label'

            $system_token = Get-SystemToken
            try {
                Invoke-WithImpersonation -Token $system_token -ScriptBlock {
                    $actual = Get-TokenIntegrityLevel
                    $actual.Sid | Should -Be $expected_sid
                    $actual.Label | Should -Be $expected_label
                    $actual.Attributes | Should -Be 'Integrity, IntegrityEnabled'
                }
            } finally {
                $system_token.Dispose()
            }
        }

        It 'Gets the integrity level for a limited token' {
            $expected_sid = [System.Security.Principal.SecurityIdentifier]'S-1-16-8192'
            $expected_label = New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList 'Mandatory Label', 'Medium Mandatory Label'

            $linked_token = Get-TokenLinkedToken
            try {
                $actual = Get-TokenIntegrityLevel -Token $linked_token

                $actual.Sid | Should -Be $expected_sid
                $actual.Label | Should -Be $expected_label
                $actual.Attributes | Should -Be 'Integrity, IntegrityEnabled'
            } finally {
                $linked_token.Dispose()
            }
        }
    }
}