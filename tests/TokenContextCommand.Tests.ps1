. ([IO.Path]::Combine($PSScriptRoot, 'common.ps1'))

Describe "Enter/Exit-TokenContext" {
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

    Context "Current process" {
        It "Impersonates current process" {
            $existingPrompt = ${function:prompt}

            $user = Get-TokenUser
            $user | Should -Be $currentAccount
            $tokenType = Get-TokenType
            $tokenType | Should -Be ([PSAccessToken.TokenType]::Primary)

            Enter-TokenContext
            try {
                $user = Get-TokenUser
                $user | Should -Be $currentAccount

                $tokenType = Get-TokenType
                $tokenType | Should -Be ([PSAccessToken.TokenType]::Impersonation)

                $actualPrompt = prompt
                "[$($currentAccount.Value)] $(&$existingPrompt)" | Should -Be $actualPrompt

                # Make sure it handles location changes
                Push-Location (Split-Path $PSScriptRoot -Parent)
                try {
                    $actualPrompt = prompt
                    "[$($currentAccount.Value)] $(&$existingPrompt)" | Should -Be $actualPrompt
                }
                finally {
                    Pop-Location
                }
            }
            finally {
                Exit-TokenContext
            }

            $user = Get-TokenUser
            $user | Should -Be $currentAccount
            $tokenType = Get-TokenType
            $tokenType | Should -Be ([PSAccessToken.TokenType]::Primary)

            # Ensure the prompt is reverted back
            &$existingPrompt | Should -Be (prompt)
        }

        It "Fails when impersonating in existing context" {
            Enter-TokenContext
            try {
                $out = Enter-TokenContext -ThreadId 99999 -ErrorVariable err -ErrorAction SilentlyContinue

                $out | Should -Be $null
                $err.Count | Should -Be 1
                [string]$err | Should -BeLike "Cannot enter new token context while in existing one"
            }
            finally {
                Exit-TokenContext
            }

            # Make sure we can call this as many times as we want
            Exit-TokenContext -ErrorAction Stop
        }
    }

    Context "ProcessId" {
        It "With parameter" {
            $user = Get-TokenUser
            $user | Should -Be $currentAccount
            $tokenType = Get-TokenType
            $tokenType | Should -Be ([PSAccessToken.TokenType]::Primary)

            Enter-TokenContext -ProcessId $systemPid
            try {
                $user = Get-TokenUser
                $user | Should -Be $systemAccount

                $tokenType = Get-TokenType
                $tokenType | Should -Be ([PSAccessToken.TokenType]::Impersonation)
            }
            finally {
                Exit-TokenContext
            }

            $user = Get-TokenUser
            $user | Should -Be $currentAccount
            $tokenType = Get-TokenType
            $tokenType | Should -Be ([PSAccessToken.TokenType]::Primary)
        }

        It "With pipeline input" {
            $user = Get-TokenUser
            $user | Should -Be $currentAccount
            $tokenType = Get-TokenType
            $tokenType | Should -Be ([PSAccessToken.TokenType]::Primary)

            $systemPid | Enter-TokenContext
            try {
                $user = Get-TokenUser
                $user | Should -Be $systemAccount

                $tokenType = Get-TokenType
                $tokenType | Should -Be ([PSAccessToken.TokenType]::Impersonation)
            }
            finally {
                Exit-TokenContext
            }

            $user = Get-TokenUser
            $user | Should -Be $currentAccount
            $tokenType = Get-TokenType
            $tokenType | Should -Be ([PSAccessToken.TokenType]::Primary)
        }

        It "With pipeline input by name" {
            $user = Get-TokenUser
            $user | Should -Be $currentAccount
            $tokenType = Get-TokenType
            $tokenType | Should -Be ([PSAccessToken.TokenType]::Primary)

            [PSCustomObject]@{Id = $systemPid} | Enter-TokenContext
            try {
                $user = Get-TokenUser
                $user | Should -Be $systemAccount

                $tokenType = Get-TokenType
                $tokenType | Should -Be ([PSAccessToken.TokenType]::Impersonation)
            }
            finally {
                Exit-TokenContext
            }

            $user = Get-TokenUser
            $user | Should -Be $currentAccount
            $tokenType = Get-TokenType
            $tokenType | Should -Be ([PSAccessToken.TokenType]::Primary)
        }
    }

    Context "ThreadId" {
        It "Fails without token on thread" {
            $out = Enter-TokenContext -ThreadId (Get-CurrentThreadId) -ErrorVariable err -ErrorAction SilentlyContinue

            $out | Should -Be $null
            $err.Count | Should -Be 1
            [string]$err | Should -BeLike "Failed to get token to impersonate*token that does not exist*"
        }

        It "Fails with invalid thread id" {
            $out = Enter-TokenContext -ThreadId 99999 -ErrorVariable err -ErrorAction SilentlyContinue

            $out | Should -Be $null
            $err.Count | Should -Be 1
            [string]$err | Should -BeLike "Failed to get token to impersonate*"
        }
    }

    Context "Handle" {
        It "By parameter" {
            $token = Get-ProcessToken -ProcessId $systemPid -Access Duplicate, Query
            try {
                Enter-TokenContext -Token $token
                try {
                    $user = Get-TokenUser
                    $user | Should -Be $systemAccount

                    $tokenType = Get-TokenType
                    $tokenType | Should -Be ([PSAccessToken.TokenType]::Impersonation)
                }
                finally {
                    Exit-TokenContext
                }
            }
            finally {
                $token.Dispose()
            }
        }

        It "By pipeline" {
            $token = Get-ProcessToken -ProcessId $systemPid -Access Duplicate, Query
            try {
                $token | Enter-TokenContext
                try {
                    $user = Get-TokenUser
                    $user | Should -Be $systemAccount

                    $tokenType = Get-TokenType
                    $tokenType | Should -Be ([PSAccessToken.TokenType]::Impersonation)
                }
                finally {
                    Exit-TokenContext
                }
            }
            finally {
                $token.Dispose()
            }
        }

        It "By pipeline by name" {
            $token = Get-ProcessToken -ProcessId $systemPid -Access Duplicate, Query
            try {
                [PSCustomObject]@{Token = $token} | Enter-TokenContext
                try {
                    $user = Get-TokenUser
                    $user | Should -Be $systemAccount

                    $tokenType = Get-TokenType
                    $tokenType | Should -Be ([PSAccessToken.TokenType]::Impersonation)
                }
                finally {
                    Exit-TokenContext
                }
            }
            finally {
                $token.Dispose()
            }
        }

        It "Fails with invalid access" {
            $token = Get-ProcessToken -Access Query
            try {
                $out = Enter-TokenContext -Token $token -ErrorVariable err -ErrorAction SilentlyContinue

                $out | Should -Be $null
                $err.Count | Should -Be 1
                [string]$err | Should -BeLike "Failed to impersonate token*Access is denied*"
            }
            finally {
                $token.Dispose()
            }
        }
    }
}
