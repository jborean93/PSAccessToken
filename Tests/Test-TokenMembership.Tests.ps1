# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

$verbose = @{}
if ($env:APPVEYOR_REPO_BRANCH -and $env:APPVEYOR_REPO_BRANCH -notlike "master") {
    $verbose.Add("Verbose", $true)
}

$ps_version = $PSVersionTable.PSVersion.Major
$cmdlet_name = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
$module_name = (Get-ChildItem -Path $PSScriptRoot\.. -Directory -Exclude @("Build", "Docs", "Tests")).Name

Describe "$cmdlet_name PS$ps_version tests" {
    Describe 'Mock Copy-AccessToken' {
        Set-StrictMode -Version latest

        Import-Module -Name $PSScriptRoot\..\$module_name -Force
        # Tests that it fails by returning the primary token back from the call of Copy-AccessToken
        Mock -ModuleName PSAccessToken -CommandName Copy-AccessToken {
            Param (
                $Token,
                $Access,
                $ImpersonationLevel
            )
            $Access | Should -Be 'Query'
            $ImpersonationLevel | Should -Be 'Identification'
            return $Token
        }

        It 'Should fail with invalid SID' {
            $expected = 'Failed to check token membership for SID: An attempt has been made to operate on an '
            $expected += 'impersonation token by a thread that is not currently impersonating a client '
            $expected += '(Win32 ErrorCode 1309 - 0x0000051D)'
            { Test-TokenMembership -Sid 'Users' } | Should -Throw $expected
            Assert-MockCalled -ModuleName PSAccessToken -CommandName Copy-AccessToken -Exactly 1
        }
    }

    Context 'Strict mode' {
        Set-StrictMode -Version latest

        Import-Module -Name $PSScriptRoot\..\$module_name -Force

        It 'Should detect if SID is part of token membership for the current process' {
            $actual = Test-TokenMembership -Sid 'Users'

            $actual | Should -Be $true

            $actual = Test-TokenMembership -Sid 'Users' -IncludeAppContainers

            $actual | Should -Be $true
        }

        It 'Should detect if SID is part of token membership for specified process' {
            $actual = Test-TokenMembership -ProcessId $PID -Sid 'Users'

            $actual | Should -Be $true
        }

        It 'Should detect if SID is part of token membership for explicit primary token' {
            # Needs Duplicate so the internal cmdlet can copy to an impersonation token.
            $h_token = Copy-AccessToken -Access Duplicate, Query -ImpersonationLevel None
            try {
                $actual = Test-TokenMembership -Token $h_token -Sid 'Users'
            } finally {
                $h_token.Dispose()
            }

            $actual | Should -Be $true
        }

        It 'Should detect if SID is part of token membership for explicit impersonation token' {
            $h_token = Copy-AccessToken -Access Query -ImpersonationLevel Identification
            try {
                $actual = Test-TokenMembership -Token $h_token -Sid 'Users'
            } finally {
                $h_token.Dispose()
            }

            $actual | Should -Be $true
        }

        It 'Should return false for Deny only access groups' {
            $h_token = Get-TokenLinkedToken
            try {
                $actual = Test-TokenMembership -Token $h_token -Sid 'Administrators'
            } finally {
                $h_token.Dispose()
            }

            $actual | Should -Be $false
        }
    }
}