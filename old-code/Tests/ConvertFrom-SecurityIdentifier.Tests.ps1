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

        $fail_sid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList 'S-1-23-45-6-78-9'
        $sid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User
        $nt_account = $sid.Translate([System.Security.Principal.NTAccount])

        It 'Converts to NTAccount' {
            $expected = $nt_account
            $actual = ConvertFrom-SecurityIdentifier -Sid $sid

            $actual | Should -Be $expected
        }

        It 'Fail with Error behaviour' {
            $expected = 'Some or all identity references could not be translated.'
            { ConvertFrom-SecurityIdentifier -Sid $fail_sid -ErrorBehaviour Error } | Should -Throw $expected
        }

        It 'Returns SID back on error' {
            $expected = $fail_sid
            $actual = ConvertFrom-SecurityIdentifier -Sid $fail_sid -ErrorBehaviour PassThru

            $actual | Should -Be $expected
        }

        It 'Returns SID string back on error' {
            $expected = $fail_sid.Value
            $actual = ConvertFrom-SecurityIdentifier -Sid $fail_sid -ErrorBehaviour SidString

            $actual | Should -Be $expected
        }

        It 'Returns an empty string on error' {
            $expected = ''
            $actual = ConvertFrom-SecurityIdentifier -Sid $fail_sid -ErrorBehaviour Empty

            $actual | Should -Be $expected
        }

        It 'Returns an NTAccount for the <Expected> integrity label' -TestCases @(
            @{ Sid = 'S-1-16-0'; Expected = 'Untrusted' },
            @{ Sid = 'S-1-16-4096'; Expected = 'Low' },
            @{ Sid = 'S-1-16-8192'; Expected = 'Medium' },
            @{ Sid = 'S-1-16-12288'; Expected = 'High' },
            @{ Sid = 'S-1-16-16384'; Expected = 'System' }
        ) {
            Param ($Sid, $Expected)

            $input_sid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList $Sid
            $expected = New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList 'Mandatory Label', "$Expected Mandatory Label"
            $actual = ConvertFrom-SecurityIdentifier -Sid $input_sid

            $actual | Should -Be $expected
        }

        It 'Does not choke on unknown integrity label' {
            $input_sid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList 'S-1-16-1'
            $expected = $input_sid.Value
            $actual = ConvertFrom-SecurityIdentifier -Sid $input_sid

            $actual | Should -Be $expected
        }

        It 'Converts from a logon session id <Sid>' -TestCases @(
            @{ Sid = 'S-1-5-5-0-1234'; Expected = '0-1234' },
            @{ Sid = 'S-1-5-5-1234-5678'; Expected = '1234-5678' }
        ) {
            Param ($Sid, $Expected)

            $input_sid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList $Sid
            $expected = New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList 'NT AUTHORITY', "LogonSessionId_$Expected"
            $actual = ConvertFrom-SecurityIdentifier -Sid $input_sid

            $actual | Should -Be $expected
        }
    }
}