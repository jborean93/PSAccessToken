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

        It 'Should return success Win32 Error Message' {
            $expected = 'The operation completed successfully (Win32 ErrorCode 0 - 0x00000000)'
            $actual = Get-Win32ErrorFromLsaStatus -ErrorCode 0

            $actual | Should -Be $expected
        }

        It 'Should convert NtStatus error to Win32' {
            $expected = 'Access is denied (Win32 ErrorCode 5 - 0x00000005)'
            $actual = Get-Win32ErrorFromLsaStatus -ErrorCode ([System.UInt32]"0xC0000022")

            $actual | Should -Be $expected
        }

        It 'Should handle large int values' {
            $expected = 'The chain of virtual hard disks is inaccessible. There was an error opening a virtual hard disk further up the chain (Win32 ErrorCode -1069940711 - 0xC03A0019)'
            $actual = Get-Win32ErrorFromLsaStatus -ErrorCode ([System.UInt32]"0xC03A0019")

            $actual | Should -Be $expected
        }

        It 'Should handle unmapped error codes' {
            $expected = 'Unknown LsaNtStatus Error (ErrorCode 2290649224 - 0x88888888)'
            $actual = Get-Win32ErrorFromLsaStatus -ErrorCode ([System.UInt32]"0x88888888")

            $actual | Should -Be $expected
        }
    }
}