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

        It 'Gets the token type for current process' {
            $actual = Get-TokenImpersonationLevel

            $actual.GetType() | Should -Be ([System.Security.Principal.TokenImpersonationLevel])
            $actual | Should -Be ([System.Security.Principal.TokenImpersonationLevel]::None)
        }

        It 'Gets the token type based on a PID' {
            $actual = Get-TokenImpersonationLevel -ProcessId $PID

            $actual.GetType() | Should -Be ([System.Security.Principal.TokenImpersonationLevel])
            $actual | Should -Be ([System.Security.Principal.TokenImpersonationLevel]::None)
        }

        It 'Gets the token based on an explicit token' {
            $h_token = Open-ProcessToken
            try {
                $actual = Get-TokenImpersonationLevel -Token $h_token
            } finally {
                $h_token.Dispose()
            }

            $actual.GetType() | Should -Be ([System.Security.Principal.TokenImpersonationLevel])
            $actual | Should -Be ([System.Security.Principal.TokenImpersonationLevel]::None)
        }

        It 'Gets the token impersonation level for an impersonation <Level> token' -TestCases @(
            @{ Level = [System.Security.Principal.TokenImpersonationLevel]::Anonymous },
            @{ Level = [System.Security.Principal.TokenImpersonationLevel]::Identification },
            @{ Level = [System.Security.Principal.TokenImpersonationLevel]::Impersonation },
            @{ Level = [System.Security.Principal.TokenImpersonationLevel]::Delegation }
        ) {
            Param ($Level)

            $h_token = Copy-AccessToken -ImpersonationLevel $Level
            try {
                $actual = Get-TokenImpersonationLevel -Token $h_token

                $actual | Should -Be $Level
            } finally {
                $h_token.Dispose()
            }
        }

        It 'Throw exception on failure to get level' {
            $h_token = Open-ProcessToken -Access Duplicate
            try {
                $expected = 'GetTokenInformation(ImpersonationLevel) failed: Access is denied (Win32 ErrorCode 5 - 0x00000005)'
                { Get-TokenImpersonationLevel -Token $h_token } | Should -Throw $expected
            } finally {
                $h_token.Dispose()
            }
        }
    }
}