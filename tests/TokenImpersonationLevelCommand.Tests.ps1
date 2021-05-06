. ([IO.Path]::Combine($PSScriptRoot, 'common.ps1'))

Describe "Get-TokenImpersonationLevel" {
    Context "Current user" {
        It "Gets the current thread user" {
            Enter-TokenContext -ProcessId $pid
            try {
                $actual = Get-TokenImpersonationLevel

                $actual | Should -Be ([Security.Principal.TokenImpersonationLevel]::Impersonation)
            }
            finally {
                Exit-TokenContext
            }
        }

        It "Gets the current process user" {
            Enter-TokenContext -ProcessId $pid
            try {
                $actual = Get-TokenImpersonationLevel -UseProcessToken

                $actual | Should -Be ([Security.Principal.TokenImpersonationLevel]::None)
            }
            finally {
                Exit-TokenContext
            }
        }
    }

    Context "ProcessId" {
        It "PID by parameter" {
            $actual = Get-TokenImpersonationLevel -ProcessId $pid, $pid

            $actual.Count | Should -Be 2
            $actual[0] | Should -Be ([Security.Principal.TokenImpersonationLevel]::None)
            $actual[1] | Should -Be ([Security.Principal.TokenImpersonationLevel]::None)
        }

        It "PID by pipeline input" {
            $actual = $pid, $pid | Get-TokenImpersonationLevel
            $actual.Count | Should -Be 2
            $actual[0] | Should -Be ([Security.Principal.TokenImpersonationLevel]::None)
            $actual[1] | Should -Be ([Security.Principal.TokenImpersonationLevel]::None)

            $actual = [PSCustomObject]@{Id = $pid}, [PSCustomObject]@{ProcessId = $pid} | Get-TokenImpersonationLevel
            $actual.Count | Should -Be 2
            $actual[0] | Should -Be ([Security.Principal.TokenImpersonationLevel]::None)
            $actual[1] | Should -Be ([Security.Principal.TokenImpersonationLevel]::None)
        }

        It "Fails with invalid process id" {
            $out = 99999 | Get-TokenImpersonationLevel -ErrorVariable err -ErrorAction SilentlyContinue

            $out | Should -Be $null
            $err.Count | Should -Be 1
            [string]$err | Should -BeLike "Failed to open process 99999*"
        }
    }

    Context "ThreadId" {
        It "With impersonation" {
            Enter-TokenContext
            try {
                $actual = Get-TokenImpersonationLevel -ThreadId (Get-CurrentThreadId)

                $actual | Should -Be ([Security.Principal.TokenImpersonationLevel]::Impersonation)
            }
            finally {
                Exit-TokenContext
            }
        }

        It "Fails without token on thread" {
            $out = Get-TokenImpersonationLevel -ThreadId (Get-CurrentThreadId) -ErrorVariable err -ErrorAction SilentlyContinue

            $out | Should -Be $null
            $err.Count | Should -Be 1
            [string]$err | Should -BeLike "Failed to open thread*token that does not exist*"
        }

        It "Fails with invalid thread id" {
            $out = Get-TokenImpersonationLevel -ThreadId 99999 -ErrorVariable err -ErrorAction SilentlyContinue

            $out | Should -Be $null
            $err.Count | Should -Be 1
            [string]$err | Should -BeLike "Failed to open thread 99999*"
        }
    }

    Context "Handle" {
        It "With parameter" {
            $token = Get-ProcessToken
            try {
                $actual = Get-TokenImpersonationLevel -Token $token

                $actual | Should -Be ([Security.Principal.TokenImpersonationLevel]::None)
            }
            finally {
                $token.Dispose()
            }
        }

        It "With pipeline input" {
            $token = Get-ProcessToken
            try {
                $actual = $token | Get-TokenImpersonationLevel
                $actual | Should -Be ([Security.Principal.TokenImpersonationLevel]::None)

                $actual = [PSCustomObject]@{Token = $token} | Get-TokenImpersonationLevel
                $actual | Should -Be ([Security.Principal.TokenImpersonationLevel]::None)
            }
            finally {
                $token.Dispose()
            }
        }

        It "Fails with invalid access" {
            $token = Get-ProcessToken -Access Duplicate
            try {
                $out = Get-TokenImpersonationLevel -Token $token -ErrorVariable err -ErrorAction SilentlyContinue

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
