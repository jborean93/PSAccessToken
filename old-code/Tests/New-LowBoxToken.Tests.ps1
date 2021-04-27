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

        It 'Should create a low box token with 0 capabilities' {
            # Make sure -WhatIf works
            $h_token = New-LowBoxToken -AppContainer 'LowBoxContainer' -Capabilities @() -WhatIf
            $h_token | Should -Be $null

            $h_token = New-LowBoxToken -AppContainer 'LowBoxContainer' -Capabilities @()
            try {
                $is_app_container = Get-TokenIsAppContainer -Token $h_token
                $app_container_number = Get-TokenAppContainerNumber -Token $h_token
                $app_container_sid = Get-TokenAppContainerSid -Token $h_token
                $token_capabilities = Get-TokenCapabilities -Token $h_token

                $is_app_container | Should -Be $true
                $app_container_number | Should -Not -Be 0
                $app_container_sid | Should -Be 'S-1-15-2-3413103605-2696603304-1349478410-2125281921-2879041757-526922028-1093822688'
                $token_capabilities | Should -Be $null
            } finally {
                $h_token.Dispose()
            }
        }

        It 'Should create a low box token with 1 capabilities' {
            $cap = 'S-1-15-3-1024-1065365936-1281604716-3511738428-1654721687-432734479-3232135806-4053264122-3456934681'
            $h_token = New-LowBoxToken -AppContainer 'LowBoxContainer' -Capabilities $cap
            try {
                $is_app_container = Get-TokenIsAppContainer -Token $h_token
                $app_container_number = Get-TokenAppContainerNumber -Token $h_token
                $app_container_sid = Get-TokenAppContainerSid -Token $h_token
                $token_capabilities = Get-TokenCapabilities -Token $h_token

                $is_app_container | Should -Be $true
                $app_container_number | Should -Not -Be 0
                $app_container_sid | Should -Be 'S-1-15-2-3413103605-2696603304-1349478410-2125281921-2879041757-526922028-1093822688'
                $token_capabilities.Sid | Should -Be $cap
                $token_capabilities.Attributes | Should -Be 'Enabled'
            } finally {
                $h_token.Dispose()
            }
        }

        It 'Should create a low box token with 2 capabilities' {
            $cap = @(
                'S-1-15-3-1024-1065365936-1281604716-3511738428-1654721687-432734479-3232135806-4053264122-3456934681',
                'S-1-15-3-3845273463-1331427702-1186551195-114810997'
            )
            $h_token = New-LowBoxToken -AppContainer 'LowBoxContainer' -Capabilities $cap
            try {
                $is_app_container = Get-TokenIsAppContainer -Token $h_token
                $app_container_number = Get-TokenAppContainerNumber -Token $h_token
                $app_container_sid = Get-TokenAppContainerSid -Token $h_token
                $token_capabilities = Get-TokenCapabilities -Token $h_token

                $is_app_container | Should -Be $true
                $app_container_number | Should -Not -Be 0
                $app_container_sid | Should -Be 'S-1-15-2-3413103605-2696603304-1349478410-2125281921-2879041757-526922028-1093822688'

                $token_capabilities.Length | Should -Be $true
                $token_capabilities[0].Sid | Should -Be $cap[0]
                $token_capabilities[0].Attributes | Should -Be 'Enabled'
                $token_capabilities[1].Sid | Should -Be $cap[1]
                $token_capabilities[1].Attributes | Should -Be 'Enabled'
            } finally {
                $h_token.Dispose()
            }
        }

        It 'Should create a low box token with explicit SID' {
            $expected = 'S-1-15-2-3-4-5-6-7-8-9'
            $h_token = New-LowBoxToken -AppContainer $expected -Capabilities @()
            try {
                $is_app_container = Get-TokenIsAppContainer -Token $h_token
                $app_container_number = Get-TokenAppContainerNumber -Token $h_token
                $app_container_sid = Get-TokenAppContainerSid -Token $h_token
                $token_capabilities = Get-TokenCapabilities -Token $h_token

                $is_app_container | Should -Be $true
                $app_container_number | Should -Not -Be 0
                $app_container_sid | Should -Be $expected
                $token_capabilities | Should -Be $null
            } finally {
                $h_token.Dispose()
            }
        }

        It 'Should fail with invalid capability' {
            $expected = 'Failed to create low box token: The parameter is incorrect (Win32 ErrorCode 87 - 0x00000057)'
            { New-LowBoxToken -AppContainer 'LowBoxContainer' -Capabilities @('S-1-2-3-4-5') } | Should -Throw $expected
        }
    }
}