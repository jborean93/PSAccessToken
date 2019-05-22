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

        It 'Copy current process' {
            $h_token = Copy-AccessToken
            try {
                $h_token.GetType() | Should -Be ([PInvokeHelper.SafeNativeHandle])
                $h_token.IsInvalid | Should -Be $false
                $h_token.IsClosed | Should -Be $false

                $actual_type = Get-TokenType -Token $h_token
                $actual_impersonation_level = Get-TokenImpersonationLevel -Token $h_token

                $actual_type | Should -Be ([PSAccessToken.TokenType]::Primary)
                $actual_impersonation_level | Should -Be ([System.Security.Principal.TokenImpersonationLevel]::None)
            } finally {
                $h_token.Dispose()
            }
            $h_token.IsClosed | Should -Be $true
        }

        It 'Copies a token to an impersonation <level> token' -TestCases @(
            @{ Level = [System.Security.Principal.TokenImpersonationLevel]::Anonymous },
            @{ Level = [System.Security.Principal.TokenImpersonationLevel]::Identification },
            @{ Level = [System.Security.Principal.TokenImpersonationLevel]::Impersonation },
            @{ Level = [System.Security.Principal.TokenImpersonationLevel]::Delegation }
         ) {
            Param ($Level)

            $h_token = Copy-AccessToken -ImpersonationLevel $Level
            try {
                $h_token.GetType() | Should -Be ([PInvokeHelper.SafeNativeHandle])
                $h_token.IsInvalid | Should -Be $false
                $h_token.IsClosed | Should -Be $false

                $actual_type = Get-TokenType -Token $h_token
                $actual_impersonation_level = Get-TokenImpersonationLevel -Token $h_token

                $actual_type | Should -Be ([PSAccessToken.TokenType]::Impersonation)
                $actual_impersonation_level | Should -Be $Level
            } finally {
                $h_token.Dispose()
            }
            $h_token.IsClosed | Should -Be $true
         }

        It 'Copies a token with explicit access mask' {
            $expected = 'GetTokenInformation(Source) failed: Access is denied (Win32 ErrorCode 5 - 0x00000005)'

            # Get-TokenSource required QuerySource in the access mask, we only duplicate with Query to expect an error
            $h_token = Copy-AccessToken -Access Query
            try {
                { Get-TokenSource -Token $h_token } | Should -Throw $expected
            } finally {
                $h_token.Dispose()
            }
        }

        It 'Copies a token from an existing token' {
            $h_token = Open-ProcessToken -Access Duplicate

            try {
                $dup_token = Copy-AccessToken -Token $h_token
                try {
                    $dup_token.GetType() | Should -Be ([PInvokeHelper.SafeNativeHandle])
                    $dup_token.IsInvalid | Should -Be $false
                    $dup_token.IsClosed | Should -Be $false
                } finally {
                    $dup_token.Dispose()
                }
                $dup_token.IsClosed | Should -Be $true
            } finally {
                $h_token.Dispose()
            }
        }

        It 'Failed to open token without Duplicate access mask' {
            $h_token = Open-ProcessToken -Access Query

            try {
                $expected = 'DuplicateTokenEx() failed: Access is denied (Win32 ErrorCode 5 - 0x00000005)'
                { Copy-AccessToken -Token $h_token } | Should -Throw $expected
            } finally {
                $h_token.Dispose()
            }
        }

        It 'It copies an explicit token with access mask' {
            $h_token = Open-ProcessToken -Access Duplicate

            try {
                # Even though the original token does not have QuerySource, our copied token does
                $dup_token = Copy-AccessToken -Token $h_token -Access QuerySource
                try {
                    $actual = Get-TokenSource -Token $dup_token
                    $actual | Should -Not -Be $null
                } finally {
                    $dup_token.Dispose()
                }
                $dup_token.IsClosed | Should -Be $true
            } finally {
                $h_token.Dispose()
            }
        }

        It 'Copied a token with explicit PID' {
            $expected = [System.Security.Principal.WindowsIdentity]::GetCurrent().User

            $h_token = Copy-AccessToken -ProcessId $PID
            try {
                $h_token.GetType() | Should -Be ([PInvokeHelper.SafeNativeHandle])
                $h_token.IsInvalid | Should -Be $false
                $h_token.IsClosed | Should -Be $false

                $actual = Get-TokenUser -Token $h_token
                $actual | Should -Be $expected
            } finally {
                $h_token.Dispose()
            }
            $h_token.IsClosed | Should -Be $true
        }

        It 'Copies a token with -WhatIf' {
            $actual = Copy-AccessToken -WhatIf
            $actual | Should -Be $null
        }
    }
}