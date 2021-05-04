$moduleName   = (Get-Item ([IO.Path]::Combine($PSScriptRoot, '..', 'module', '*.psd1'))).BaseName
$manifestPath = [IO.Path]::Combine($PSScriptRoot, '..', 'build', $moduleName)

Import-Module $manifestPath

Describe "Get-HandleInformation" {
    It "Is not inherited" {
        $handle = Get-ProcessHandle -Id $pid
        try {
            $actual = Get-HandleInformation -Handle $handle

            $actual.HasFlag([PSAccessToken.HandleFlags]::Inherit) | Should -Be $false
        }
        finally {
            $handle.Dispose()
        }
    }

    It "Is inherited" {
        $handle = Get-ProcessHandle -Id $pid -Inherit
        try {
            $actual = $handle | Get-HandleInformation

            $actual.HasFlag([PSAccessToken.HandleFlags]::Inherit) | Should -Be $true
        }
        finally {
            $handle.Dispose()
        }
    }

    It "Fails with invalid handle" {
        $handle = [Microsoft.Win32.SafeHandles.SafeWaitHandle]::new([IntPtr]::Zero, $false)
        $out = Get-HandleInformation -Handle $handle -ErrorVariable err -ErrorAction SilentlyContinue

        $out | Should -Be $null
        $err.Count | Should -Be 1
        $err[0] | Should -BeLike 'Failed to get handle information*The handle is invalid*'
    }
}

Describe "Set-HandleInformation" {
    It "Set individual flags" {
        $handle = Get-ProcessHandle -Id $pid
        try {
            Set-HandleInformation -Handle $handle -Inherit

            $actual = $handle | Get-HandleInformation
            $actual.HasFlag([PSAccessToken.HandleFlags]::Inherit) | Should -Be $true

            $handle | Set-HandleInformation -ProtectFromClose
            try {
                $actual = $handle | Get-HandleInformation
                $actual.HasFlag([PSAccessToken.HandleFlags]::Inherit) | Should -Be $true
                $actual.HasFlag([PSAccessToken.HandleFlags]::ProtectFromClose) | Should -Be $true

            }
            finally {
                Set-HandleInformation -Handle $handle -Clear
            }
        }
        finally {
            $handle.Dispose()
        }
    }

    It "Sets a flag while clearing others" {
        $handle = Get-ProcessHandle -Id $pid -Inherit

        try {
            Set-HandleInformation -Handle $handle -ProtectFromClose -Clear
            try {
                $actual = $handle | Get-HandleInformation
                $actual.HasFlag([PSAccessToken.HandleFlags]::Inherit) | Should -Be $false
                $actual.HasFlag([PSAccessToken.HandleFlags]::ProtectFromClose) | Should -Be $true

            }
            finally {
                Set-HandleInformation -Handle $handle -Clear
            }
        }
        finally {
            $handle.Dispose()
        }
    }

    It "Respects WhatIf" {
        $handle = Get-ProcessHandle -Id $pid

        try {
            Set-HandleInformation -Handle $handle -Inherit -WhatIf

            $actual = $handle | Get-HandleInformation
            $actual.HasFlag([PSAccessToken.HandleFlags]::Inherit) | Should -Be $false
        }
        finally {
            $handle.Dispose()
        }
    }

    It "Fails with invalid handle" {
        $handle = [Microsoft.Win32.SafeHandles.SafeWaitHandle]::new([IntPtr]::Zero, $false)
        $out = Set-HandleInformation -Handle $handle -Clear -ErrorVariable err -ErrorAction SilentlyContinue

        $out | Should -Be $null
        $err.Count | Should -Be 1
        $err[0] | Should -BeLike 'Failed to set handle information*The handle is invalid*'
    }
}
