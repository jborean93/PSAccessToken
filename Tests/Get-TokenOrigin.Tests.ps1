# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    "PSAvoidUsingConvertToSecureStringWithPlainText", "",
    Justification="Cmdlet expects a SecureString so we need to test with them"
)]
Param ()

$verbose = @{}
if ($env:APPVEYOR_REPO_BRANCH -and $env:APPVEYOR_REPO_BRANCH -notlike "master") {
    $verbose.Add("Verbose", $true)
}

$ps_version = $PSVersionTable.PSVersion.Major
$cmdlet_name = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
$module_name = (Get-ChildItem -Path $PSScriptRoot\.. -Directory -Exclude @("Build", "Docs", "Tests")).Name
Import-Module -Name $PSScriptRoot\..\$module_name -Force
. $PSScriptRoot\TestUtils.ps1

Describe "$cmdlet_name PS$ps_version tests" {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It 'Gets the token origin for current process' {
            $actual = Get-TokenOrigin
            $actual.GetType() | Should -Be ([System.Security.Principal.SecurityIdentifier])
        }

        It 'Gets the token owner based on a PID' {
            $actual = Get-TokenOrigin -ProcessId $PID
            $actual.GetType() | Should -Be ([System.Security.Principal.SecurityIdentifier])
        }

        It 'Gets the token based on an explicit token' {
            $user = ([System.Security.Principal.WindowsIdentity]::GetCurrent().User)

            $system_token = Get-SystemToken
            try {
                Invoke-WithImpersonation -Token $system_token -ScriptBlock {
                    $logon = Invoke-LogonUser -Username $user -Password $null
                    try {
                        $actual = Get-TokenOrigin -Token $logon.Token
                        $actual | Should -Be 'S-1-5-5-0-999'  # We created it under the SYSTEM context.
                    } finally {
                        $logon.Token.Dispose()
                    }
                }
            } finally {
                $system_token.Dispose()
            }
        }

        It 'Gets the token for a <Type> logon type' -TestCases @(
            @{ Type = 'Network' },
            @{ Type = 'NetworkCleartext' }
        ) {
            Param ($Type)

            $account = 'test-account'
            $password = ConvertTo-SecureString -String ([System.Guid]::NewGuid().ToString()) -AsPlainText -Force
            New-LocalAccount -Username $account -Password $password > $null
            try {
                Set-LocalAccountMembership -Username $account -Groups 'Users', 'Administrators'

                $parent_logon = Invoke-LogonUser -Username $account -Password $password -LogonType $Type
                try {
                    Invoke-WithImpersonation -Token $parent_logon.Token -ScriptBlock {
                        $expected = (Get-TokenStatistics).AuthenticationId

                        $logon = Invoke-LogonUser -Username $account -Password $password -LogonType $Type
                        try {
                            $actual = Get-TokenOrigin -Token $logon.Token
                            $actual | Should -Be $expected
                        } finally {
                            $logon.Token.Dispose()
                        }
                    }
                } finally {
                    $parent_logon.Token.Dispose()
                }
            } finally {
                Remove-LocalAccount -Username $account
            }
        }
    }
}