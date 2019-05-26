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
. $PSScriptRoot\..\$module_name\Private\Convert-PointerToUInt32.ps1
. $PSScriptRoot\..\$module_name\Private\ConvertTo-SecurityIdentifier.ps1

Describe "$cmdlet_name PS$ps_version tests" {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It 'Should return null for unknown profile buffer type' {
            $invalid_buffer_bytes = [Byte[]]@(1, 2, 3, 4)
            $buffer_ptr = [System.Runtime.InteropServices.Marshal]::AllocHGlobal(4)
            try {
                [System.Runtime.InteropServices.Marshal]::Copy($invalid_buffer_bytes, 0, $buffer_ptr, 4)
                $params = @{
                    Token = New-Object -TypeName PInvokeHelper.SafeNativeHandle
                    ProfileBuffer = $buffer_ptr
                    Username = 'Test'
                    Domain = $null
                    LogonType = 'Interactive'
                    LogonId = New-Object -TypeName PSAccessToken.LUID
                    QuotaLimits = New-Object -TypeName PSAccessToken.QUOTA_LIMITS
                }

                $actual = ConvertTo-LogonInfo @params
                $actual.Profile | Should -Be $null
            } finally {
                [System.Runtime.InteropServices.Marshal]::FreeHGlobal($buffer_ptr)
            }
        }
    }
}