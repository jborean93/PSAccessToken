$moduleName   = (Get-Item ([IO.Path]::Combine($PSScriptRoot, '..', 'module', '*.psd1'))).BaseName
$manifestPath = [IO.Path]::Combine($PSScriptRoot, '..', 'build', $moduleName)

Import-Module $manifestPath

Describe "Get-TokenUser" {
    BeforeAll {
        $currentSid = [Security.Principal.WindowsIdentity]::GetCurrent().User
        $currentAccount = $currentSid.Translate([Security.Principal.NTAccount])

        $systemSid = [Security.Principal.SecurityIdentifier]::new(
            [Security.Principal.WellKnownSidType]::LocalSystemSid,
            $null
        )
        $systemAccount = $systemSid.Translate([Security.Principal.NTAccount])
        $systemPid = Get-Process -IncludeUserName | Where-Object {
            if ($_.UserName -ne $systemAccount.Value) {
                return $false
            }

            try {
                $null = Get-ProcessToken -ProcessId $_.Id -ErrorAction Stop
                return $true
            }
            catch {
                return $false
            }
        } | Select-Object -First 1 -ExpandProperty Id
    }

    Context "Current user" {
        It "Gets the current thread user" {
            Enter-TokenContext -ProcessId $systemPid
            try {
                $actual = Get-TokenUser

                $actual | Should -Be $systemAccount
            }
            finally {
                Exit-TokenContext
            }
        }

        It "Gets the current process user" {
            Enter-TokenContext -ProcessId $systemPid
            try {
                $actual = Get-TokenUser -UseProcessToken

                $actual | Should -Be $currentAccount
            }
            finally {
                Exit-TokenContext
            }
        }

        It "Specifies the output type" {
            $actual = Get-TokenUser -IdentityType ([Security.Principal.SecurityIdentifier])

            $actual | Should -Be $currentSid
        }
    }

    Context "ProcessId" {
        It "PID by parameter" {
            $actual = Get-TokenUser -ProcessId $pid, $systemPid

            $actual.Count | Should -Be 2
            $actual[0] | Should -Be $currentAccount
            $actual[1] | Should -Be $systemAccount
        }

        It "PID by pipeline with output type" {
            $actual = $pid, $systemPid | Get-TokenUser -IdentityType ([Security.Principal.SecurityIdentifier])

            $actual.Count | Should -Be 2
            $actual[0] | Should -Be $currentSid
            $actual[1] | Should -Be $systemSid
        }
    }

    Context "ThreadId" {
        It "Fails without token on thread" {
            $out = Get-TokenUser -ThreadId 99999 -ErrorVariable err -ErrorAction SilentlyContinue

            $out | Should -Be $null
            $err.Count | Should -Be 1
            [string]$err | Should -BeLike "Failed to open thread 99999*"
        }
    }

    Context "Handle" {

    }
}
