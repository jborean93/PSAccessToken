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
. $PSScriptRoot\..\$module_name\Private\ConvertTo-SecurityIdentifier.ps1

Describe "$cmdlet_name PS$ps_version tests" {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It 'Gets the token restricted sids for current process' {
            $actual = Get-TokenRestrictedSids
            $actual | Should -Be $null
        }

        It 'Gets the token groups based on a PID' {
            $actual = Get-TokenRestrictedSids -ProcessId $PID
            $actual | Should -Be $null
        }

        It 'Gets the token based on an explicit token' {
            $h_token = New-RestrictedToken -RestrictedSids 'Users'
            try {
                $actual = Get-TokenRestrictedSids -Token $h_token
            } finally {
                $h_token.Dispose()
            }

            $actual.GetType() | Should -Be ([System.Management.Automation.PSCustomObject])
            $actual.Sid | Should -Be (ConvertTo-SecurityIdentifier -InputObject 'Users')
        }
    }
}