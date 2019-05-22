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

Describe "$cmdlet_name PS$ps_version tests" {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It 'Should create pointer with size' {
            Use-SafePointer -Size 4 -Process {
                Param ([System.IntPtr]$Ptr)

                $Ptr | Should -Not -Be ([System.IntPtr]::Zero)
            }
        }

        It 'Should return output back to caller' {
            $actual = Use-SafePointer -Size 4 -Process {
                'test'
            }

            $actual | Should -Be 'test'
        }

        It 'Creates an empty pointer' {
            Use-SafePointer -Size 0 -Process {
                Param ([System.IntPtr]$Ptr)

                $Ptr | Should -Be ([System.IntPtr]::Zero)
            }
        }

        It 'Passes in variables' {
            $variables = @{
                a = 'a'
                b = 'b'
                Process = $null
            }
            Use-SafePointer -Size 0 -Variables $variables -Process {
                Param ([System.IntPtr]$Ptr, [Hashtable]$Variables)

                $Variables.Count | Should -Be 3
                $Variables.a | Should -Be 'a'
                $Variables.b | Should -Be 'b'
                $Variables.Process | Should -Be $null
            }
        }
    }
}