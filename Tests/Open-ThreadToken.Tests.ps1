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

        It 'Fails to open thread token when not impersonating when EAP stop' {
            $expected = 'Failed to open thread token: An attempt was made to reference a token that does not exist (Win32 ErrorCode 1008 - 0x000003F0)'
            { Open-ThreadToken -ErrorAction Stop } | Should -Throw $expected
        }

        It 'Failed to open thread token and return null when EAP Continue' {
            $expected = 'Failed to open thread token: An attempt was made to reference a token that does not exist (Win32 ErrorCode 1008 - 0x000003F0)'
            $err = $null
            $actual = Open-ThreadToken -ErrorAction SilentlyContinue -ErrorVariable err

            $actual | Should -Be $null
            $err | Should -Be $expected
        }

        It 'Open token for current thread' {
            $h_token = Open-ProcessToken -Access Duplicate, Query
            try {
                Invoke-WithImpersonation -Token $h_token -ScriptBlock {
                    $imp_token = Open-ThreadToken
                    try {
                        $imp_token.GetType().FullName | Should -Be 'PInvokeHelper.SafeNativeHandle'
                        $imp_token.IsInvalid | Should -Be $false
                        $imp_token.IsClosed | Should -Be $false
                    } finally {
                        $imp_token.Dispose()
                    }
                    $imp_token.IsClosed | Should -Be $true
                }
            } finally {
                $h_token.Dispose()
            }
        }

        It 'Open token for current thread and explicit thread handle' {
            $h_token = Open-ProcessToken -Access Duplicate, Query
            try {
                Invoke-WithImpersonation -Token $h_token -ScriptBlock {
                    $imp_h_thread = Get-ThreadHandle
                    $imp_token = Open-ThreadToken -Thread $imp_h_thread
                    try {
                        $imp_token.GetType().FullName | Should -Be 'PInvokeHelper.SafeNativeHandle'
                        $imp_token.IsInvalid | Should -Be $false
                        $imp_token.IsClosed | Should -Be $false
                    } finally {
                        $imp_token.Dispose()
                    }
                    $imp_token.IsClosed | Should -Be $true
                }
            } finally {
                $h_token.Dispose()
            }
        }

        It 'It opens a token with explicit tid' {
            $h_token = Open-ProcessToken -Access Duplicate, Query
            try {
                Invoke-WithImpersonation -Token $h_token -ScriptBlock {
                    $imp_h_thread = Get-ThreadHandle -ThreadId ([PSAccessToken.NativeMethods]::GetCurrentThreadId())
                    try {
                        $imp_token = Open-ThreadToken -Thread $imp_h_thread
                        try {
                            $imp_token.GetType().FullName | Should -Be 'PInvokeHelper.SafeNativeHandle'
                            $imp_token.IsInvalid | Should -Be $false
                            $imp_token.IsClosed | Should -Be $false
                        } finally {
                            $imp_token.Dispose()
                        }
                        $imp_token.IsClosed | Should -Be $true
                    } finally {
                        $imp_h_thread.Dispose()
                    }
                }
            } finally {
                $h_token.Dispose()
            }
        }
    }
}