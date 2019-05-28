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
. $PSScriptRoot\..\$module_name\Private\$cmdlet_name.ps1
. $PSScriptRoot\..\$module_name\Private\Get-Win32ErrorFromLsaStatus.ps1

Describe "$cmdlet_name PS$ps_version tests" {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It 'Should fail to logon on' {
            $user = Get-TokenUser
            $token = Invoke-WithPrivilege -Privilege SeCreateTokenPrivilege -ScriptBlock {
                New-AccessToken -User $user -Groups @() -Privileges @()
            }
            try {
                $expected = 'Failed to open LSA Policy handle: Access is denied (Win32 ErrorCode 5 - 0x00000005)'
                Invoke-WithImpersonation -Token $token -ScriptBlock {
                    { Use-LsaPolicy -Access 0 -Process {} } | Should -Throw $expected
                }
            } finally {
                $token.Dispose()
            }
        }
    }
}