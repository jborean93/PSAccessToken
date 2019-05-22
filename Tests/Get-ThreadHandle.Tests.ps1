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

        It 'It opens the current thread handle' {
            $h_thread = Get-ThreadHandle
            $h_thread.GetType().FullName | Should -Be 'PInvokeHelper.SafeNativeHandle'
            [System.IntPtr]$h_thread | Should -Be -2
        }

        It 'It opens a thread using explicit tid' {
            $h_thread = Get-ThreadHandle -ThreadId ([PSAccessToken.NativeMethods]::GetCurrentThreadId())
            try {
                $h_thread.GetType().FullName | Should -Be 'PInvokeHelper.SafeNativeHandle'
                [System.IntPtr]$h_thread | Should -Not -Be -2
                $h_thread.IsClosed | Should -Be $false
                $h_thread.IsInvalid | Should -Be $false
            } finally {
                $h_thread.Dispose()
            }
            $h_thread.IsClosed | Should -Be $true
        }

        It 'Fails to open a thread' {
            $expected = "Failed to open thread '0': The parameter is incorrect (Win32 ErrorCode 87 - 0x00000057)"
            { Get-ThreadHandle -ThreadId 0 -ErrorAction Stop } | Should -Throw $expected
        }

        It 'Returns null with EAP Continue' {
            $expected = "Failed to open thread '0': The parameter is incorrect (Win32 ErrorCode 87 - 0x00000057)"
            $err = $null
            $actual = Get-ThreadHandle -ThreadId 0 -ErrorAction SilentlyContinue -ErrorVariable err

            $actual | Should -Be $null
            $err | Should -Be $expected
        }
    }
}