. ([IO.Path]::Combine($PSScriptRoot, 'common.ps1'))

Describe "Get-TokenUser" {
    BeforeAll {
        . ([IO.Path]::Combine($PSScriptRoot, 'common.ps1'))

        $currentSid = [Security.Principal.WindowsIdentity]::GetCurrent().User
        $currentAccount = $currentSid.Translate([Security.Principal.NTAccount])

        $systemSid = [Security.Principal.SecurityIdentifier]::new(
            [Security.Principal.WellKnownSidType]::LocalSystemSid,
            $null
        )
        $systemAccount = $systemSid.Translate([Security.Principal.NTAccount])
        $systemPid = Get-ProcessForUser -UserName $systemAccount.Value | Select-Object -First 1 -ExpandProperty Id
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

        It "Fails with invalid IdentityType" {
            $expType = [Management.Automation.ParameterBindingException]
            { Get-TokenUser -IdentityType ([String]) } |
                Should -Throw "*Type must be subclass of IdentityReference" -ExceptionType $expType
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

            $actual = [PSCustomObject]@{ProcessId = $pid }, [PSCustomObject]@{Id = $systemPid } | Get-TokenUser

            $actual.Count | Should -Be 2
            $actual[0] | Should -Be $currentAccount
            $actual[1] | Should -Be $systemAccount
        }

        It "Fails with invalid process id" {
            $out = Get-TokenUser -ProcessId 99999 -ErrorVariable err -ErrorAction SilentlyContinue

            $out | Should -Be $null
            $err.Count | Should -Be 1
            [string]$err | Should -BeLike "Failed to open process 99999*"
        }
    }

    Context "ThreadId" {
        It "With impersonation" {
            Enter-TokenContext -ProcessId $systemPid
            try {
                $actual = Get-TokenUser -ThreadId (Get-CurrentThreadId)

                $actual | Should -Be $systemAccount
            }
            finally {
                Exit-TokenContext
            }
        }

        It "Fails without token on thread" {
            $out = Get-TokenUser -ThreadId (Get-CurrentThreadId) -ErrorVariable err -ErrorAction SilentlyContinue

            $out | Should -Be $null
            $err.Count | Should -Be 1
            [string]$err | Should -BeLike "Failed to open thread*token that does not exist*"
        }

        It "Fails with invalid thread id" {
            $out = Get-TokenUser -ThreadId 99999 -ErrorVariable err -ErrorAction SilentlyContinue

            $out | Should -Be $null
            $err.Count | Should -Be 1
            [string]$err | Should -BeLike "Failed to open thread 99999*"
        }
    }

    Context "Handle" {
        It "With parameter" {
            $token = Get-ProcessToken -ProcessId $systemPid
            try {
                $actual = Get-TokenUser -Token $token

                $actual | Should -Be $systemAccount
            }
            finally {
                $token.Dispose()
            }
        }

        It "With pipeline input" {
            $token = Get-ProcessToken
            try {
                $actual = $token | Get-TokenUser
                $actual | Should -Be $currentAccount

                $actual = [PSCustomObject]@{Token = $token } | Get-TokenUser
                $actual | Should -Be $currentAccount
            }
            finally {
                $token.Dispose()
            }
        }

        It "Fails with invalid access" {
            $token = Get-ProcessToken -Access Duplicate
            try {
                $out = Get-TokenUser -Token $token -ErrorVariable err -ErrorAction SilentlyContinue

                $out | Should -Be $null
                $err.Count | Should -Be 1
                [string]$err | Should -BeLike "Failed to get token information*Access is denied*"
            }
            finally {
                $token.Dispose()
            }
        }
    }
}
