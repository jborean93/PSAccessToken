. ([IO.Path]::Combine($PSScriptRoot, 'common.ps1'))

Describe "Copy-Token" {
    BeforeAll {
        $token = Get-ProcessToken -Access Duplicate
    }
    AfterAll {
        $token.Dispose()
    }

    It "Creates with default values" {
        # Need Query so we can get the results
        $dup = $token | Copy-Token -Access Query
        try {
            $actualType = Get-TokenType $dup
            $actualLevel = Get-TokenImpersonationLevel $dup

            $actualType | Should -Be ([PSAccessToken.TokenType]::Primary)
            $actualLevel | Should -Be ([Security.Principal.TokenImpersonationLevel]::None)
        }
        finally {
            $dup.Dispose()
        }
    }

    It "Uses existing access level as default" {
        $dup = [PSCustomObject]@{Token = $token} | Copy-Token
        try {
            # $token was opened with just Duplicate rights so this should fail
            $out = Get-TokenUser -Token $token -ErrorVariable err -ErrorAction SilentlyContinue

            $out | Should -Be $null
            $err.Count | Should -Be 1
            $err[0] | Should -BeLike 'Failed to get token information*Access is denied*'
        }
        finally {
            $dup.Dispose()
        }
    }

    It "Creates a primary token" {
        $dup = Copy-Token -Token $token -TokenType Primary -Access Query
        try {
            $actualType = Get-TokenType $dup
            $actualLevel = Get-TokenImpersonationLevel $dup

            $actualType | Should -Be ([PSAccessToken.TokenType]::Primary)
            $actualLevel | Should -Be ([Security.Principal.TokenImpersonationLevel]::None)
        }
        finally {
            $dup.Dispose()
        }
    }

    It "Failed with primary token and <Level> impersonation" -TestCases @(
        @{Level = [Security.Principal.TokenImpersonationLevel]::Anonymous}
        @{Level = [Security.Principal.TokenImpersonationLevel]::Identification}
        @{Level = [Security.Principal.TokenImpersonationLevel]::Impersonation}
        @{Level = [Security.Principal.TokenImpersonationLevel]::Delegation}
    ) {
        param ($Level)

        $out = Copy-Token -Token $token -ImpersonationLevel $Level -ErrorVariable err -ErrorAction SilentlyContinue

        $out | Should -Be $null
        $err.Count | Should -Be 1
        $err[0] | Should -BeLike 'Cannot create a Primary token with any impersonation level other than None'
    }

    It "Creates an impersonation token <Level>" -TestCases @(
        @{Level = $null}
        @{Level = [Security.Principal.TokenImpersonationLevel]::Anonymous}
        @{Level = [Security.Principal.TokenImpersonationLevel]::Identification}
        @{Level = [Security.Principal.TokenImpersonationLevel]::Impersonation}
        @{Level = [Security.Principal.TokenImpersonationLevel]::Delegation}
    ) {
        param ($Level)

        $copySplat = @{
            Token = $token
            TokenType = 'Impersonation'
            Access = 'Query'
        }
        if ($null -ne $Level) {
            $copySplat.ImpersonationLevel = $Level
        }
        else {
            # Used for test assertion
            $Level = [Security.Principal.TokenImpersonationLevel]::Impersonation
        }

        $dup = Copy-Token @copySplat
        try {
            $actualType = Get-TokenType $dup
            $actualLevel = Get-TokenImpersonationLevel $dup

            $actualType | Should -Be ([PSAccessToken.TokenType]::Impersonation)
            $actualLevel | Should -Be $Level
        }
        finally {
            $dup.Dispose()
        }
    }

    It "Fails with impersonation token and None level" {
        $out = Copy-Token -Token $token -TokenType Impersonation -ImpersonationLevel None -ErrorVariable err -ErrorAction SilentlyContinue

        $out | Should -Be $null
        $err.Count | Should -Be 1
        $err[0] | Should -BeLike 'Cannot create an Impersonation token with the None impersonation level'
    }

    It "Creates inheritable token" {
        $dup = Copy-Token -Token $token -Inherit -Access Query
        try {
            $actual = Get-HandleInformation $dup
            $actual | Should -Be ([PSAccessToken.HandleFlags]::Inherit)
        }
        finally {
            $dup.Dispose()
        }
    }
}
