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

        It 'Should convert a string' {
            $expected = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList 'S-1-5-18'
            $input_object = 'SYSTEM'

            $actual = ConvertTo-SecurityIdentifier -InputObject $input_object
            $actual | Should -Be $expected

            $actual = $input_object | ConvertTo-SecurityIdentifier
            $actual | Should -Be $expected
        }

        It 'Should convert a string as a sid' {
            $expected = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList 'S-1-5-18'
            $input_object = 'S-1-5-18'

            $actual = ConvertTo-SecurityIdentifier -InputObject $input_object
            $actual | Should -Be $expected

            $actual = $input_object | ConvertTo-SecurityIdentifier
            $actual | Should -Be $expected
        }

        It 'Should convert a SecurityIdentifier' {
            $expected = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList 'S-1-5-18'
            $input_object = $expected

            $actual = ConvertTo-SecurityIdentifier -InputObject $input_object
            $actual | Should -Be $expected

            $actual = $input_object | ConvertTo-SecurityIdentifier
            $actual | Should -Be $expected
        }

        It 'Should convert a NTAccount' {
            $expected = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList 'S-1-5-18'
            $input_object = New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList 'System'

            $actual = ConvertTo-SecurityIdentifier -InputObject $input_object
            $actual | Should -Be $expected

            $actual = $input_object | ConvertTo-SecurityIdentifier
            $actual | Should -Be $expected
        }

        It 'Should convert an array' {
            $expected = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList 'S-1-5-18'
            $input_object = @(
                'SYSTEM',
                'S-1-5-18',
                (New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList 'S-1-5-18'),
                (New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList 'System')
            )

            $actual = ConvertTo-SecurityIdentifier -InputObject $input_object
            $actual.Length | Should -Be 4
            $actual | ForEach-Object -Process { $_ | Should -Be $expected }

            $actual = $input_object | ConvertTo-SecurityIdentifier
            $actual.Length | Should -Be 4
            $actual | ForEach-Object -Process { $_ | Should -Be $expected }
        }
    }
}