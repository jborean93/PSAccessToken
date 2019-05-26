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
.$PSScriptRoot\TestUtils.ps1

Describe "$cmdlet_name PS$ps_version tests" {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It 'Should impersonate the system account' {
            $system_token = Get-SystemToken
            try {
                $actual = Invoke-WithImpersonation -Token $system_token -ScriptBlock {
                    [System.Security.Principal.WindowsIdentity]::GetCurrent().User
                    Get-TokenUser
                }
            } finally {
                $system_token.Dispose()
            }

            $actual[0].GetType() | Should -Be ([System.Security.Principal.SecurityIdentifier])
            $actual[0].Value | Should -Be 'S-1-5-18'
            $actual[1].GetType() | Should -Be ([System.Security.Principal.NTAccount])
            $actual[1].Value | Should -Be 'NT AUTHORITY\SYSTEM'
        }

        It 'Should fail with invalid token' {
            $expected = 'Failed to impersonate access token: The handle is invalid (Win32 ErrorCode 6 - 0x00000006)'
            $fake_t = New-Object -TypeName PInvokeHelper.SafeNativeHandle
            { Invoke-WithImpersonation -Token $fake_t -ScriptBlock {} -ErrorAction Stop } | Should -Throw $expected
        }

        It 'Should return null when EAP is Continue' {
            $expected = 'Failed to impersonate access token: The handle is invalid (Win32 ErrorCode 6 - 0x00000006)'
            $fake_t = New-Object -TypeName PInvokeHelper.SafeNativeHandle

            $err = $null
            $actual = Invoke-WithImpersonation -Token $fake_t -ScriptBlock {} -ErrorAction SilentlyContinue -ErrorVariable err

            $actual | Should -Be $null
            $err | Should -Be $expected
        }
    }
}