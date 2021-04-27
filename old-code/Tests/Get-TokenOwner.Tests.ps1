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
. $PSScriptRoot\..\$module_name\Private\ConvertFrom-SecurityIdentifier.ps1

Describe "$cmdlet_name PS$ps_version tests" {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It 'Gets the token owner for current process' {
            $expected = ConvertFrom-SecurityIdentifier -Sid ([System.Security.Principal.WindowsIdentity]::GetCurrent().Owner)
            $actual = Get-TokenOwner

            $actual | Should -Be $expected

            # Test the group by creating a new file
            $path = 'TestDrive:\no_param.txt'
            New-Item -Path $path -ItemType File > $null
            $actual_sd = Get-Acl -LiteralPath $path
            $actual_owner = New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList $actual_sd.Owner
            $actual_owner | Should -Be $actual
        }

        It 'Gets the token owner based on a PID' {
            $expected = ConvertFrom-SecurityIdentifier -Sid ([System.Security.Principal.WindowsIdentity]::GetCurrent().Owner)
            $actual = Get-TokenOwner -ProcessId $PID

            $actual | Should -Be $expected

            $path = 'TestDrive:\pid.txt'
            New-Item -Path $path -ItemType File > $null
            $actual_sd = Get-Acl -LiteralPath $path
            $actual_owner = New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList $actual_sd.Owner
            $actual_owner | Should -Be $actual
        }

        It 'Gets the token based on an explicit token' {
            $expected = ConvertFrom-SecurityIdentifier -Sid ([System.Security.Principal.WindowsIdentity]::GetCurrent().Owner)
            $h_token = Open-ProcessToken
            try {
                $actual = Get-TokenOwner -Token $h_token
            } finally {
                $h_token.Dispose()
            }

            $expected = ConvertFrom-SecurityIdentifier -Sid ([System.Security.Principal.WindowsIdentity]::GetCurrent().Owner)
            $actual | Should -Be $expected

            $path = 'TestDrive:\token.txt'
            New-Item -Path $path -ItemType File > $null
            $actual_sd = Get-Acl -LiteralPath $path
            $actual_owner = New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList $actual_sd.Owner
            $actual_owner | Should -Be $actual
        }
    }
}