# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    "PSAvoidUsingConvertToSecureStringWithPlainText", "",
    Justification="Cmdlet expects a SecureString so we need to test with them"
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    "PSUseDeclaredVarsMoreThanAssignments", "",
    Justification="Bug in PSScriptAnalyzer detecting Pester scope, the vars are being used"
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
. $PSScriptRoot\..\$module_name\Private\Get-AuditSubCategory.ps1
. $PSScriptRoot\..\$module_name\Private\Get-AuditSubCategoryName.ps1

. $PSScriptRoot\TestUtils.ps1

$account = 'test-audit-user'
$pass = ConvertTo-SecureString -String ([System.Guid]::NewGuid()).ToString() -AsPlainText -Force
$sub_categories = @()
Get-AuditSubCategory | ForEach-Object -Process { $sub_categories += @{ Name = $_.Name; Guid = $_.Guid } }

Describe "$cmdlet_name PS$ps_version tests" {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        BeforeAll {
            $account_sid = New-LocalAccount -Username $account -Password $pass
            Set-LocalAccountMembership -Username $account -Groups 'Users'
        }

        AfterAll {
            Remove-LocalAccount -Username $account
        }

        It 'Gets the token audit policy for current process' {
            $actual = Get-TokenAuditPolicy

            $actual[0].GetType().FullName | Should -Be 'System.Management.Automation.PSCustomObject'
            $actual[0].PSObject.TypeNames[0] | Should -Be 'PSAccessToken.TokenAuditPolicy'
            $entry_properties = $actual[0].PSObject.Properties
            $entry_properties.Value.Count | Should -Be 4
            $entry_properties.Name[0] | Should -Be 'Policy'
            $entry_properties.TypeNameOfValue[0] | Should -Be 'System.String'
            $entry_properties.Name[1] | Should -Be 'Guid'
            $entry_properties.TypeNameOfValue[1] | Should -Be 'System.Guid'
            $entry_properties.Name[2] | Should -Be 'Success'
            $entry_properties.TypeNameOfValue[2] | Should -Be 'System.Boolean'
            $entry_properties.Name[3] | Should -Be 'Failure'
            $entry_properties.TypeNameOfValue[3] | Should -Be 'System.Boolean'
        }

        It 'Gets the token audit policy based on a PID' {
            $actual = Get-TokenAuditPolicy -ProcessId $PID

            $actual[0].GetType().FullName | Should -Be 'System.Management.Automation.PSCustomObject'
            $actual[0].PSObject.TypeNames[0] | Should -Be 'PSAccessToken.TokenAuditPolicy'
            $entry_properties = $actual[0].PSObject.Properties
            $entry_properties.Value.Count | Should -Be 4
            $entry_properties.Name[0] | Should -Be 'Policy'
            $entry_properties.TypeNameOfValue[0] | Should -Be 'System.String'
            $entry_properties.Name[1] | Should -Be 'Guid'
            $entry_properties.TypeNameOfValue[1] | Should -Be 'System.Guid'
            $entry_properties.Name[2] | Should -Be 'Success'
            $entry_properties.TypeNameOfValue[2] | Should -Be 'System.Boolean'
            $entry_properties.Name[3] | Should -Be 'Failure'
            $entry_properties.TypeNameOfValue[3] | Should -Be 'System.Boolean'
        }

        It 'Gets the token based on an explicit token' {
            $h_token = Open-ProcessToken
            try {
                $actual = Get-TokenAuditPolicy -Token $h_token
            } finally {
                $h_token.Dispose()
            }

            $actual[0].GetType().FullName | Should -Be 'System.Management.Automation.PSCustomObject'
            $actual[0].PSObject.TypeNames[0] | Should -Be 'PSAccessToken.TokenAuditPolicy'
            $entry_properties = $actual[0].PSObject.Properties
            $entry_properties.Value.Count | Should -Be 4
            $entry_properties.Name[0] | Should -Be 'Policy'
            $entry_properties.TypeNameOfValue[0] | Should -Be 'System.String'
            $entry_properties.Name[1] | Should -Be 'Guid'
            $entry_properties.TypeNameOfValue[1] | Should -Be 'System.Guid'
            $entry_properties.Name[2] | Should -Be 'Success'
            $entry_properties.TypeNameOfValue[2] | Should -Be 'System.Boolean'
            $entry_properties.Name[3] | Should -Be 'Failure'
            $entry_properties.TypeNameOfValue[3] | Should -Be 'System.Boolean'
        }

        It 'Fails to get token audit policy with SeSecurityPrivilege' {
            $expected = 'AdjustTokenPrivileges(SeSecurityPrivilege) failed: Not all privileges or groups referenced are assigned to the caller (Win32 ErrorCode 1300 - 0x00000514)'
            $h_token = Copy-AccessToken
            try {
                Set-TokenPrivileges -Token $h_token -Name SeSecurityPrivilege -Attributes 'Removed'
                Invoke-WithImpersonation -Token $h_token -ScriptBlock {
                    { Get-TokenAuditPolicy -Token $h_token } | Should -Throw $expected
                }
            } finally {
                $h_token.Dispose()
            }
        }

        It 'Sets sub category ''<Name>'' - <Guid>' -TestCases $sub_categories {
            Param ($Name, $Guid)

            &Auditpol.exe "/set" "/user:{$($account_sid.Value)}" "/include" "/subcategory:{$($Guid.ToString())}" "/success:enable" "/failure:enable" > $null
            try {
                $logon = Invoke-LogonUser -Username $account -Password $pass
                try {
                    $actual = Get-TokenAuditPolicy -Token $logon.Token

                    foreach ($policy in $actual) {
                        if ($policy.Policy -eq $Name) {
                            $policy.Success | Should -Be $true
                            $policy.Failure | Should -Be $true
                        } else {
                            $policy.Success | Should -Be $false
                            $policy.Failure | Should -Be $false
                        }
                    }
                } finally {
                    $logon.Token.Dispose()
                }
            } finally {
                &Auditpol.exe "/remove" "/user:{$($account_sid.Value)}" > $null
            }
        }
    }
}