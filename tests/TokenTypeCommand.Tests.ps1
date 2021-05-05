. ([IO.Path]::Combine($PSScriptRoot, 'common.ps1'))

Describe "Get-TokenType" {
    Context "Current user" {
        It "Gets the current thread user" {
            Enter-TokenContext -ProcessId $pid
            try {
                $actual = Get-TokenType

                $actual | Should -Be ([PSAccessToken.TokenType]::Impersonation)
            }
            finally {
                Exit-TokenContext
            }
        }

        It "Gets the current process user" {
            Enter-TokenContext -ProcessId $pid
            try {
                $actual = Get-TokenType -UseProcessToken

                $actual | Should -Be ([PSAccessToken.TokenType]::Primary)
            }
            finally {
                Exit-TokenContext
            }
        }
    }

    Context "ProcessId" {
        It "PID by parameter" {
            $actual = Get-TokenType -ProcessId $pid, $pid

            $actual.Count | Should -Be 2
            $actual[0] | Should -Be ([PSAccessToken.TokenType]::Primary)
            $actual[1] | Should -Be ([PSAccessToken.TokenType]::Primary)
        }

        It "PID by pipeline input" {
            $actual = $pid, $pid | Get-TokenType
            $actual.Count | Should -Be 2
            $actual[0] | Should -Be ([PSAccessToken.TokenType]::Primary)
            $actual[1] | Should -Be ([PSAccessToken.TokenType]::Primary)

            $actual = [PSCustomObject]@{Id = $pid}, [PSCustomObject]@{ProcessId = $pid} | Get-TokenType
            $actual.Count | Should -Be 2
            $actual[0] | Should -Be ([PSAccessToken.TokenType]::Primary)
            $actual[1] | Should -Be ([PSAccessToken.TokenType]::Primary)
        }

        It "Fails with invalid process id" {
            $out = 99999 | Get-TokenType -ErrorVariable err -ErrorAction SilentlyContinue

            $out | Should -Be $null
            $err.Count | Should -Be 1
            [string]$err | Should -BeLike "Failed to open process 99999*"
        }
    }

    Context "ThreadId" {
        It "With impersonation" {
            Enter-TokenContext
            try {
                $actual = Get-TokenType -ThreadId (Get-CurrentThreadId)

                $actual | Should -Be ([PSAccessToken.TokenType]::Impersonation)
            }
            finally {
                Exit-TokenContext
            }
        }

        It "Fails without token on thread" {
            $out = Get-TokenType -ThreadId (Get-CurrentThreadId) -ErrorVariable err -ErrorAction SilentlyContinue

            $out | Should -Be $null
            $err.Count | Should -Be 1
            [string]$err | Should -BeLike "Failed to open thread*token that does not exist*"
        }

        It "Fails with invalid thread id" {
            $out = Get-TokenType -ThreadId 99999 -ErrorVariable err -ErrorAction SilentlyContinue

            $out | Should -Be $null
            $err.Count | Should -Be 1
            [string]$err | Should -BeLike "Failed to open thread 99999*"
        }
    }

    Context "Handle" {
        It "With parameter" {
            $token = Get-ProcessToken
            try {
                $actual = Get-TokenType -Token $token

                $actual | Should -Be ([PSAccessToken.TokenType]::Primary)
            }
            finally {
                $token.Dispose()
            }
        }

        It "With pipeline input" {
            $token = Get-ProcessToken
            try {
                $actual = $token | Get-TokenType
                $actual | Should -Be ([PSAccessToken.TokenType]::Primary)

                $actual = [PSCustomObject]@{Token = $token} | Get-TokenType
                $actual | Should -Be ([PSAccessToken.TokenType]::Primary)
            }
            finally {
                $token.Dispose()
            }
        }

        It "Fails with invalid access" {
            $token = Get-ProcessToken -Access Duplicate
            try {
                $out = Get-TokenType -Token $token -ErrorVariable err -ErrorAction SilentlyContinue

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
