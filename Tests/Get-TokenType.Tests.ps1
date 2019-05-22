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
            $actual = Get-TokenType

            $actual.GetType() | Should -Be ([PSAccessToken.TokenType])
            $actual | Should -Be ([PSAccessToken.TokenType]::Primary)
        }

        It 'Gets the token type based on a PID' {
            $actual = Get-TokenType -ProcessId $PID

            $actual.GetType() | Should -Be ([PSAccessToken.TokenType])
            $actual | Should -Be ([PSAccessToken.TokenType]::Primary)
        }

        It 'Gets the token based on an explicit token' {
            $h_token = Open-ProcessToken
            try {
                $actual = Get-TokenType -Token $h_token
            } finally {
                $h_token.Dispose()
            }

            $actual.GetType() | Should -Be ([PSAccessToken.TokenType])
            $actual | Should -Be ([PSAccessToken.TokenType]::Primary)
        }

        It 'Gets the token type for an impersonation <Level> token' -TestCases @(
            @{ Level = [System.Security.Principal.TokenImpersonationLevel]::Anonymous },
            @{ Level = [System.Security.Principal.TokenImpersonationLevel]::Identification },
            @{ Level = [System.Security.Principal.TokenImpersonationLevel]::Impersonation },
            @{ Level = [System.Security.Principal.TokenImpersonationLevel]::Delegation }
        ) {
            Param ($Level)

            $h_token = Copy-AccessToken -ImpersonationLevel $Level
            try {
                $actual = Get-TokenType -Token $h_token

                $actual | Should -Be ([PSAccessToken.TokenType]::Impersonation)
            } finally {
                $h_token.Dispose()
            }
        }
    }
}