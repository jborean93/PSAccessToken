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

Function Compare-Dacl {
    Param (
        [System.Security.AccessControl.RawAcl]$Actual,
        [System.Security.AccessControl.AuthorizationRuleCollection]$Expected
    )

    # Now compare the ACLs
    $actual.Count | Should -Be $expected.Count
    foreach ($raw_ace in $Actual) {
        $found = $false
        foreach ($expected_ace in $Expected) {
            $expected_qualififer = switch ($expected_ace.AccessControlType) {
                Allow { [System.Security.AccessControl.AceQualifier]::AccessAllowed }
                Deny { [System.Security.AccessControl.AceQualifier]::AccessDenied }
            }

            if ($raw_ace.AceQualifier -ne $expected_qualififer) {
                continue
            }
            if ($raw_ace.SecurityIdentifier -ne $expected_ace.IdentityReference) {
                continue
            }
            if ($raw_ace.IsInherited -ne $expected_ace.IsInherited) {
                continue
            }
            if ($raw_ace.InheritanceFlags -ne $expected_ace.InheritanceFlags) {
                continue
            }
            if ($raw_ace.PropagationFlags -ne $expected_ace.PropagationFlags) {
                continue
            }

            $found = $true
            break
        }

        $found | Should -Be $true
    }
}

Describe "$cmdlet_name PS$ps_version tests" {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It 'Gets the token default DACL for current process' {
            $actual = Get-TokenDefaultDacl

            # Cannot test this against a file or registry key as DefaultDacl only applies to objects that do not exist
            # in an inheritable heirarchy. Create an anonymous pipe and get descriptor from that.
            # https://docs.microsoft.com/en-us/windows/desktop/SecAuthZ/dacl-for-a-new-object
            $pipe = New-Object -TypeName System.IO.Pipes.AnonymousPipeServerStream
            try {
                $expected = $pipe.GetAccessControl().GetAccessRules(
                    $true, $false, [System.Security.Principal.SecurityIdentifier]
                )
            } finally {
                $pipe.Dispose()
            }
            Compare-Dacl -Actual $actual -Expected $expected


        }

        It 'Gets the token default DACL based on a PID' {
            $actual = Get-TokenDefaultDacl -ProcessId $PID

            $pipe = New-Object -TypeName System.IO.Pipes.AnonymousPipeServerStream
            try {
                $expected = $pipe.GetAccessControl().GetAccessRules(
                    $true, $false, [System.Security.Principal.SecurityIdentifier]
                )
            } finally {
                $pipe.Dispose()
            }
            Compare-Dacl -Actual $actual -Expected $expected
        }

        It 'Gets the token based on an explicit token' {
            $h_token = Open-ProcessToken
            try {
                $actual = Get-TokenDefaultDacl -Token $h_token
            } finally {
                $h_token.Dispose()
            }

            $pipe = New-Object -TypeName System.IO.Pipes.AnonymousPipeServerStream
            try {
                $expected = $pipe.GetAccessControl().GetAccessRules(
                    $true, $false, [System.Security.Principal.SecurityIdentifier]
                )
            } finally {
                $pipe.Dispose()
            }
            Compare-Dacl -Actual $actual -Expected $expected
        }

        # TODO: Add test with null DefaultDacl
    }
}