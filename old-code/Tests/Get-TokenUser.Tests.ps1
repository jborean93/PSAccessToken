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
. $PSScriptRoot\..\$module_name\Private\ConvertFrom-SecurityIdentifier.ps1
. $PSScriptRoot\..\$module_name\Private\Use-SafePointer.ps1

Describe "$cmdlet_name PS$ps_version tests" {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It 'Gets the token user for current process' {
            $expected = ConvertFrom-SecurityIdentifier -Sid ([System.Security.Principal.WindowsIdentity]::GetCurrent().User)
            $actual = Get-TokenUser

            $actual.GetType().FullName | Should -Be 'System.Security.Principal.NTAccount'
            $actual.Value | Should -Be $expected.Value
        }

        It 'Gets the token user based on a PID' {
            $expected = ConvertFrom-SecurityIdentifier -Sid ([System.Security.Principal.WindowsIdentity]::GetCurrent().User)
            $actual = Get-TokenUser -ProcessId $PID

            $actual.GetType().FullName | Should -Be 'System.Security.Principal.NTAccount'
            $actual.Value | Should -Be $expected.Value
        }

        It 'Gets the token based on an explicit token' {
            $expected = ConvertFrom-SecurityIdentifier -Sid ([System.Security.Principal.WindowsIdentity]::GetCurrent().User)

            $h_token = Open-ProcessToken
            try {
                $actual = Get-TokenUser -Token $h_token
            } finally {
                $h_token.Dispose()
            }

            $actual.GetType().FullName | Should -Be 'System.Security.Principal.NTAccount'
            $actual.Value | Should -Be $expected.Value
        }

        It 'Fails to get a token without proper rights' {
            # The System process is a protected process and we won't be able to access it.
            { Get-TokenUser -ProcessId 4 } | Should -Throw "Failed to open process '4': Access is denied (Win32 ErrorCode 5 - 0x00000005)"
        }

        It 'Pass in variables to scriptblock' {
            $variables = @{
                a = "a"
                b = "b"
                safe_ptr = $null
            }
            Use-SafePointer -Size 0 -Variables $variables -Process {
                Param ([System.IntPtr]$Ptr, [Hashtable]$Variables)

                $Variables.Count | Should -Be 3
                $Variables.a | Should -Be 'a'
                $Variables.b | Should -Be 'b'
                $Variables.safe_ptr | Should -Be $null
            }
        }
    }
}