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
. $PSScriptRoot\..\$module_name\Private\ConvertTo-SecurityIdentifier.ps1

Describe "$cmdlet_name PS$ps_version tests" {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It 'Should create restricted token' {
            $h_token = New-RestrictedToken `
                -DisabledSids 'Administrators', 'Users' `
                -RemovedPrivileges 'SeRestorePrivilege', 'SeBackupPrivilege' `
                -RestrictedSids 'Everyone', 'INTERACTIVE'
            try {
                $actual_groups = Get-TokenGroups -Token $h_token
                $actual_privileges = Get-TokenPrivileges -Token $h_token
                $actual_restricted_sids = Get-TokenRestrictedSids -Token $h_token
            } finally {
                $h_token.Dispose()
            }

            'Administrators', 'Users' | ConvertTo-SecurityIdentifier | ForEach-Object -Process {
                $current_sid = $_
                $actual_sid = $actual_groups | Where-Object { $_.Sid -eq $current_sid }
                $actual_sid.Attributes | Should -Be ([PSAccessToken.TokenGroupAttributes]::UseForDenyOnly)
            }

            'SeRestorePrivilege', 'SeBackupPrivilege' | ForEach-Object -Process {
                $_ -notin $actual_privileges.Name | Should -Be $true
            }

            $actual_restricted_sids.Length | Should -Be 2
            'Everyone', 'INTERACTIVE' | ConvertTo-SecurityIdentifier | ForEach-Object -Process {
                $_ -in $actual_restricted_sids.Sid | Should -Be $true
            }
        }

        It 'Should create restricted token with no privileges' {
            $h_token = New-RestrictedToken -DisableMaxPrivilege
            try {
                $actual_privileges = Get-TokenPrivileges -Token $h_token
            } finally {
                $h_token.Dispose()
            }

            $actual_privileges.GetType() | Should -Be ([System.Management.Automation.PSCustomObject])
            $actual_privileges.Name | Should -Be 'SeChangeNotifyPrivilege'
        }

        It 'Fails with invalid privilege' {
            $expected = 'Failed to create restricted token: Access is denied (Win32 ErrorCode 5 - 0x00000005)'
            $h_token = Open-ProcessToken -Access Query
            try {
                { New-RestrictedToken -Token $h_token } | Should -Throw $expected
            } finally {
                $h_token.Dispose()
            }

        }

        It 'Creates token with sandbox inert' {
            $h_token = New-RestrictedToken -SandboxInert
            try {
                $h_token.IsClosed | Should -Be $false
                $h_token.IsInvalid | Should -Be $false
            } finally {
                $h_token.Dispose()
            }
            $h_token.IsClosed | Should -Be $true
        }

        It 'Creates a LUA token' {
            $h_token = New-RestrictedToken -LuaToken
            try {
                $actual_privileges = Get-TokenPrivileges -Token $h_token
                $h_token.IsClosed | Should -Be $false
                $h_token.IsInvalid | Should -Be $false
            } finally {
                $h_token.Dispose()
            }
            $h_token.IsClosed | Should -Be $true

            'SeRestorePrivilege' -notin $actual_privileges.Name | Should -Be $true
        }

        It 'Creates a write restricted token' {
            $h_token = New-RestrictedToken -WriteRestricted
            try {
                $h_token.IsClosed | Should -Be $false
                $h_token.IsInvalid | Should -Be $false
            } finally {
                $h_token.Dispose()
            }
            $h_token.IsClosed | Should -Be $true
        }

        It 'Does not create token with -WhatIf' {
            $actual = New-RestrictedToken -WhatIf
            $actual | Should -Be $null
        }
    }
}