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
. $PSScriptRoot\TestUtils.ps1

Describe "$cmdlet_name PS$ps_version tests" {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It 'Get logon session data for the current process' {
            $actual = Get-LogonSessionData

            $actual[0].GetType().FullName | Should -Be 'System.Management.Automation.PSCustomObject'
            $actual[0].PSObject.TypeNames[0] | Should -Be 'PSAccessToken.LogonSessionData'
            $entry_properties = $actual[0].PSObject.Properties
            $entry_properties.Value.Count | Should -Be 24
            $entry_properties.Name[0] | Should -Be 'LogonId'
            $entry_properties.TypeNameOfValue[0] | Should -Be 'System.Security.Principal.SecurityIdentifier'
            $entry_properties.Name[1] | Should -Be 'LogonType'
            $entry_properties.TypeNameOfValue[1] | Should -Be 'PSAccessToken.LogonType'
            $entry_properties.Name[2] | Should -Be 'Session'
            $entry_properties.TypeNameOfValue[2] | Should -Be 'System.UInt32'
            $entry_properties.Name[3] | Should -Be 'Sid'
            $entry_properties.TypeNameOfValue[3] | Should -Be 'System.Security.Principal.SecurityIdentifier'
            $entry_properties.Name[4] | Should -Be 'UserFlags'
            $entry_properties.TypeNameOfValue[4] | Should -Be 'PSAccessToken.ProfileUserFlags'

            # The DateTime fields may not be set so we can only rely on checking the property name
            $entry_properties.Name[5] | Should -Be 'LogonTime'
            $entry_properties.Name[6] | Should -Be 'LogoffTime'
            $entry_properties.Name[7] | Should -Be 'KickOffTime'
            $entry_properties.Name[8] | Should -Be 'PasswordLastSet'
            $entry_properties.Name[9] | Should -Be 'PasswordCanChange'
            $entry_properties.Name[10] | Should -Be 'PasswordMustChange'
            $entry_properties.Name[11] | Should -Be 'LastSuccessfulLogon'
            $entry_properties.Name[12] | Should -Be 'LastFailedLogon'

            $entry_properties.Name[13] | Should -Be 'FailedAttemptCountSinceLastSuccessfulLogon'
            $entry_properties.TypeNameOfValue[13] | Should -Be 'System.UInt32'
            $entry_properties.Name[14] | Should -Be 'UserName'
            $entry_properties.TypeNameOfValue[14] | Should -Be 'System.String'
            $entry_properties.Name[15] | Should -Be 'LogonDomain'
            $entry_properties.TypeNameOfValue[15] | Should -Be 'System.String'
            $entry_properties.Name[16] | Should -Be 'AuthenticationPackage'
            $entry_properties.TypeNameOfValue[16] | Should -Be 'System.String'
            $entry_properties.Name[17] | Should -Be 'LogonServer'
            $entry_properties.TypeNameOfValue[17] | Should -Be 'System.String'

            # Cannot rely on these being set, just check the propert name
            $entry_properties.Name[18] | Should -Be 'DnsDomainName'
            $entry_properties.Name[19] | Should -Be 'Upn'
            $entry_properties.Name[20] | Should -Be 'LogonScript'
            $entry_properties.Name[21] | Should -Be 'ProfilePath'
            $entry_properties.Name[22] | Should -Be 'HomeDirectory'
            $entry_properties.Name[23] | Should -Be 'HomeDirectoryDrive'
        }

        It 'Gets the logon session data for a specific id' {
            $system_sid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList 'S-1-5-18'
            $logon_sid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList 'S-1-5-5-0-999'

            $actual = Get-LogonSessionData -LogonId $logon_sid
            $actual.Sid | Should -Be $system_sid
            $actual.LogonId | Should -Be $logon_sid
        }

        It 'Fails with invalid logon id' {
            $expected = 'Failed to get LSA logon session data: A specified logon session does not exist. '
            $expected += 'It may already have been terminated (Win32 ErrorCode 1312 - 0x00000520)'
            { Get-LogonSessionData -LogonId 'S-1-5-5-0-0' } | Should -Throw $expected
        }

        It 'Gets a logon session for the <Account> logon' -TestCases @(
            @{ Account = 'System'; Sid = 'S-1-5-18'; LogonSid = 'S-1-5-5-0-999' },
            @{ Account = 'Network Service'; Sid = 'S-1-5-20'; LogonSid = 'S-1-5-5-0-996' },
            @{ Account = 'Local Service'; Sid = 'S-1-5-19'; LogonSid = 'S-1-5-5-0-997' }
        ) {
            Param (
                [System.String]$Account,
                [System.Security.Principal.SecurityIdentifier]$Sid,
                [System.Security.Principal.SecurityIdentifier]$LogonSid
            )

            $system_token = Get-SystemToken
            try {
                Invoke-WithImpersonation -Token $system_token -ScriptBlock {
                    $logon = Invoke-LogonUser -Username $Account -Password $null
                    try {
                        $actual = Get-LogonSessionData -Token $logon.Token
                        $actual[0].GetType().FullName | Should -Be 'System.Management.Automation.PSCustomObject'
                        $actual[0].PSObject.TypeNames[0] | Should -Be 'PSAccessToken.LogonSessionData'
                        $entry_properties = $actual[0].PSObject.Properties
                        $entry_properties.Value.Count | Should -Be 24

                        $actual.Sid | Should -Be $Sid
                        $actual.LogonId | Should -Be $LogonSid
                    } finally {
                        $logon.Token.Dispose()
                    }
                }
            } finally {
                $system_token.Dispose()
            }
        }

        It 'Gets a logon session for own own created token' {
            $elevated_token = Get-TokenWithPrivilege -Privileges 'SeCreateTokenPrivilege'
            try {
                Invoke-WithImpersonation -Token $elevated_token -ScriptBlock {
                    # The logons ession data for the new token should be the same as the impersonated token as we set
                    # the LogonId/AuthenticationId to the current user's one.
                    $token_user = Get-TokenUser
                    $token_statistics = Get-TokenStatistics

                    $current_user = [System.Security.Principal.WindowsIdentity]::GetCurrent().User
                    $h_token = New-AccessToken $current_user -Groups @() -Privileges @()
                    try {
                        $actual = Get-LogonSessionData -Token $h_token
                        $actual.Sid | Should -Be $token_user.Translate([System.Security.Principal.SecurityIdentifier])
                        $actual.LogonId | Should -Be $token_statistics.AuthenticationId
                    } finally {
                        $h_token.Dispose()
                    }
                }
            } finally {
                $elevated_token.Dispose()
            }
        }
    }
}
