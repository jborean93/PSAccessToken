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

        It 'Should get current process token' {
            Use-ImplicitToken -Process {
                Param ([PInvokeHelper.SafeNativeHandle]$Token)

                $Token.GetType() | Should -Be ([PInvokeHelper.SafeNativeHandle])
                $Token.IsClosed | Should -Be $false
                $Token.IsInvalid | Should -Be $false
            }
        }

        It 'Uses explicitly passed in token' {
            $h_token = Open-ProcessToken
            try {
                Use-ImplicitToken -Token $h_token -Process {
                    Param ([PInvokeHelper.SafeNativeHandle]$Token, [Hashtable]$Variables)

                    $Token.GetType() | Should -Be ([PInvokeHelper.SafeNativeHandle])
                    $Token.IsClosed | Should -Be $false
                    $Token.IsInvalid | Should -Be $false
                }
            } finally {
                $h_token.Dispose()
            }
        }

        It 'Uses PID for token' {
            Use-ImplicitToken -ProcessId $PID -Process {
                Param ([PInvokeHelper.SafeNativeHandle]$Token, [Hashtable]$Variables)

                $Token.GetType() | Should -Be ([PInvokeHelper.SafeNativeHandle])
                $Token.IsClosed | Should -Be $false
                $Token.IsInvalid | Should -Be $false
            }
        }

        It 'Uses TID for token' {
            $h_token = Open-ProcessToken -Access Duplicate, Query
            try {
                Invoke-WithImpersonation -Token $h_token -ScriptBlock {
                    Use-ImplicitToken -ThreadId ([PSAccessToken.NativeMethods]::GetCurrentThreadId()) -Process {
                        Param ([PInvokeHelper.SafeNativeHandle]$Token, [Hashtable]$Variables)

                        $Token.GetType() | Should -Be ([PInvokeHelper.SafeNativeHandle])
                        $Token.IsClosed | Should -Be $false
                        $Token.IsInvalid | Should -Be $false
                    }
                }
            } finally {
                $h_token.Dispose()
            }
        }

        It 'Passes in variables' {
            $variables = @{
                a = 'a'
                b = 'b'
                Process = $null
            }
            Use-ImplicitToken -Variables $variables -Process {
                Param ([PInvokeHelper.SafeNativeHandle]$Token, [Hashtable]$Variables)

                $Variables.Count | Should -Be 3
                $Variables.a | Should -Be 'a'
                $Variables.b | Should -Be 'b'
                $Variables.Process | Should -Be $null
            }
        }

        It 'Supports unbound parameters' {
            Use-ImplicitToken -FakeParam DontFail -Process {
                Param ([PInvokeHelper.SafeNativeHandle]$Token, [Hashtable]$Variables)

                # Access UnboundParameters from parent cmdlet
                $UnboundParameters.Length | Should -Be 2
                $UnboundParameters[0] | Should -Be '-FakeParam'
                $UnboundParameters[1] | Should -be 'DontFail'
            }
        }
    }

    Context 'Open-ThreadToken failure' {
        Mock -CommandName Open-ThreadToken -MockWith { throw "random failure" }
        It 'Fails to open thread token' {
            $expected = 'random failure'
            { Use-ImplicitToken -Process {} } | Should -Throw $expected
        }
    }
}