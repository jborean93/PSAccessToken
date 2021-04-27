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

        It 'Open token for current process' {
            $h_token = Open-ProcessToken
            try {
                $h_token.GetType().FullName | Should -Be 'PInvokeHelper.SafeNativeHandle'
            } finally {
                $h_token.Dispose()
            }
        }

        It 'Open token for current process and explicit process handle' {
            $h_process = Get-ProcessHandle

            $h_token = Open-ProcessToken -Process $h_process
            try {
                $h_token.GetType().FullName | Should -Be 'PInvokeHelper.SafeNativeHandle'
            } finally {
                $h_token.Dispose()
            }
        }

        It 'It opens a token with explicit pid' {
            $h_process = Get-ProcessHandle -ProcessId $PID
            try {
                $h_token = Open-ProcessToken -Process $h_process
                try {
                    $h_token.GetType().FullName | Should -Be 'PInvokeHelper.SafeNativeHandle'
                    $h_token.IsClosed | Should -Be $false
                    $h_token.IsInvalid | Should -Be $false
                } finally {
                    $h_token.Dispose()
                }
                $h_token.IsClosed | Should -Be $true
            } finally {
                $h_process.Dispose()
            }
        }

        It 'Fails to open token due to invalid access mask' {
            $h_process = Get-ProcessHandle -ProcessId 4 -Access QueryLimitedInformation
            try {
                $expected = "Failed to open process token: Access is denied (Win32 ErrorCode 5 - 0x00000005)"
                { Open-ProcessToken -Process $h_process -Access Impersonate -ErrorAction Stop } | Should -Throw $expected
            } finally {
                $h_process.Dispose()
            }
        }
    }
}