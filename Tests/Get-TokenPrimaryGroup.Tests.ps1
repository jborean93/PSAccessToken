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

        It 'Gets the token primary group for current process' {
            $actual = Get-TokenPrimaryGroup

            $actual.GetType().FullName | Should -Be 'System.Security.Principal.NTAccount'

            # Test the group by creating a new file
            $path = 'TestDrive:\no_param.txt'
            New-Item -Path $path -ItemType File > $null
            $actual_sd = Get-Acl -LiteralPath $path
            $actual_group = New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList $actual_sd.Group
            $actual_group | Should -Be $actual
        }

        It 'Gets the token primary group based on a PID' {
            $actual = Get-TokenPrimaryGroup -ProcessId $PID

            $actual.GetType().FullName | Should -Be 'System.Security.Principal.NTAccount'

            $path = 'TestDrive:\pid.txt'
            New-Item -Path $path -ItemType File > $null
            $actual_sd = Get-Acl -LiteralPath $path
            $actual_group = New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList $actual_sd.Group
            $actual_group | Should -Be $actual
        }

        It 'Gets the token based on an explicit token' {
            $h_token = Open-ProcessToken
            try {
                $actual = Get-TokenPrimaryGroup -Token $h_token
            } finally {
                $h_token.Dispose()
            }

            $actual.GetType().FullName | Should -Be 'System.Security.Principal.NTAccount'

            $path = 'TestDrive:\token.txt'
            New-Item -Path $path -ItemType File > $null
            $actual_sd = Get-Acl -LiteralPath $path
            $actual_group = New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList $actual_sd.Group
            $actual_group | Should -Be $actual
        }
    }
}