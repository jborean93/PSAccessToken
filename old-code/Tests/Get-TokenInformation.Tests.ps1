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
. $PSScriptRoot\..\$module_name\Private\Use-ImplicitToken.ps1

Describe "$cmdlet_name PS$ps_version tests" {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It 'It fails to get the buffer length' {
            # By getting an explicit process handle and we open with just Query, we can guarantee that
            # GetTokenInformation with the Source token class will fail.
            $h_process = Get-ProcessHandle -ProcessId $PID
            try {
                $h_token = Open-ProcessToken -Process $h_process -Access "Query"
                try {
                    $expected = "GetTokenInformation(Source) failed: Access is denied (Win32 ErrorCode 5 - 0x00000005)"
                    { Get-TokenInformation -Token $h_token -TokenInfoClass "Source" -Process {} } | Should -Throw $expected
                } finally {
                    $h_token.Dispose()
                }
            } finally {
                $h_process.Dispose()
            }
        }
    }
}