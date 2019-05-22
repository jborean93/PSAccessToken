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

        It 'It opens the current process handle' {
            $h_process = Get-ProcessHandle
            $h_process.GetType().FullName | Should -Be 'PInvokeHelper.SafeNativeHandle'
            [System.IntPtr]$h_process | Should -Be -1
        }

        It 'It opens a process using explicit pid' {
            $h_process = Get-ProcessHandle -ProcessId $PID
            try {
                $h_process.GetType().FullName | Should -Be 'PInvokeHelper.SafeNativeHandle'
                [System.IntPtr]$h_process | Should -Not -Be -1
                $h_process.IsClosed | Should -Be $false
                $h_process.IsInvalid | Should -Be $false
            } finally {
                $h_process.Dispose()
            }
            $h_process.IsClosed | Should -Be $true
        }

        It 'Fails to open a process' {
            $expected = "Failed to open process '0': The parameter is incorrect (Win32 ErrorCode 87 - 0x00000057)"
            { Get-ProcessHandle -ProcessId 0 -ErrorAction Stop } | Should -Throw $expected
        }

        It 'Returns null with EAP Continue' {
            $expected = "Failed to open process '0': The parameter is incorrect (Win32 ErrorCode 87 - 0x00000057)"
            $err = $null
            $actual = Get-ProcessHandle -ProcessId 0 -ErrorAction SilentlyContinue -ErrorVariable err

            $actual | Should -Be $null
            $err | Should -Be $expected
        }
    }
}