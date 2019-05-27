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

        
        $it_params = @{}
        $os_version = [Version](Get-Item -LiteralPath "$env:SystemRoot\System32\kernel32.dll").VersionInfo.ProductVersion
        if ($os_version -lt [Version]"10.0.16299") {
            # TokenBnoIsolation was added in Windows 10 1709 (Build 16299)
            $it_params.Skip = $true
        }

        It 'Gets the token Bno Isolation for current process' @it_params {
            $actual = Get-TokenBnoIsolation

            $actual.GetType() | Should -Be ([System.Management.Automation.PSCustomObject])
            $actual.PSObject.TypeNames[0] | Should -Be 'PSAccessToken.TokenBnoIsolation'
            $actual.Enabled | Should -Be $false
            $actual.Prefix | Should -Be $null
        }

        It 'Gets the token Bno Isolation based on a PID' @it_params {
            $actual = Get-TokenBnoIsolation -ProcessId $PID

            $actual.GetType() | Should -Be ([System.Management.Automation.PSCustomObject])
            $actual.PSObject.TypeNames[0] | Should -Be 'PSAccessToken.TokenBnoIsolation'
            $actual.Enabled | Should -Be $false
            $actual.Prefix | Should -Be $null
        }

        It 'Gets the token Bno Isolation on an explicit token' @it_params {
            $h_token = Open-ProcessToken
            try {
                $actual = Get-TokenBnoIsolation -Token $h_token
            } finally {
                $h_token.Dispose()
            }

            $actual.GetType() | Should -Be ([System.Management.Automation.PSCustomObject])
            $actual.PSObject.TypeNames[0] | Should -Be 'PSAccessToken.TokenBnoIsolation'
            $actual.Enabled | Should -Be $false
            $actual.Prefix | Should -Be $null
        }
    }
}