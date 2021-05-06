. ([IO.Path]::Combine($PSScriptRoot, 'common.ps1'))

Describe "Get-ProcessHandle" {
    Context "Current process" {
        It "Has the expected psuedo handle value" {
            $handle = Get-ProcessHandle
            try {
                $handle.DangerousGetHandle() | Should -Be ([IntPtr]::new(-1))
            }
            finally {
                $handle.Dispose()
            }
        }

        It "Is not invalid" {
            $handle = Get-ProcessHandle
            try {
                $handle.IsInvalid | Should -Be $false
            }
            finally {
                $handle.Dispose()
            }
        }

        It "Is not closed" {
            $handle = Get-ProcessHandle
            try {
                $handle.IsClosed | Should -Be $false

                $handle.Dispose()

                $handle.IsClosed | Should -be $true
            }
            finally {
                $handle.Dispose()
            }

        }

        It "Inherit is not psuedo handle" {
            $handle = Get-ProcessHandle -Inherit
            try {
                $handle.DangerousGetHandle() | Should -Not -Be ([IntPtr]::new(-1))

                $info = Get-HandleInformation -Handle $handle
                $info.HasFlag([PSAccessToken.HandleFlags]::Inherit) | Should -Be $true
            }
            finally {
                $handle.Dispose()
            }
        }

        It "Access is not psuedo handle" {
            $handle = Get-ProcessHandle -Access QueryInformation
            try {
                $handle.DangerousGetHandle() | Should -Not -Be ([IntPtr]::new(-1))
            }
            finally {
                $handle.Dispose()
            }
        }
    }

    Context "Explicit process" {
        It "Does not use the psuedo handle" {
            $handle = Get-ProcessHandle -ProcessId $pid
            try {
                $handle.DangerousGetHandle() | Should -Not -Be ([IntPtr]::new(-1))
            }
            finally {
                $handle.Dispose()
            }
        }

        It "Is not invalid" {
            $handle = Get-ProcessHandle -Id $pid
            try {
                $handle.IsInvalid | Should -Be $false
            }
            finally {
                $handle.Dispose()
            }
        }

        It "Is not closed" {
            $handle = Get-ProcessHandle -ProcessId $pid
            try {
                $handle.IsClosed | Should -Be $false

                $handle.Dispose()

                $handle.IsClosed | Should -be $true
            }
            finally {
                $handle.Dispose()
            }
        }

        It "Works with pipeline input" {
            $handle = $pid | Get-ProcessHandle
            try {
                $handle.IsInvalid | Should -Be $false
            }
            finally {
                $handle.Dispose()
            }
        }

        It "Works with array of pids" {
            $handle = Get-ProcessHandle -ProcessId $pid, $pid
            try {
                $handle.Count | Should -Be 2
                $handle[0].IsInvalid | Should -Be $false
                $handle[1].IsInvalid | Should -Be $false
            }
            finally {
                $handle.Dispose()
            }
        }

        It "Get inheritable handle" {
            $handle = $pid | Get-ProcessHandle
            try {
                $res = Get-HandleInformation -Handle $handle
                $res.HasFlag([PSAccessToken.HandleFlags]::Inherit) | Should -Be $false
            }
            finally {
                $handle.Dispose()
            }

            $handle = $pid | Get-ProcessHandle -Inherit
            try {
                $res = Get-HandleInformation -Handle $handle
                $res.HasFlag([PSAccessToken.HandleFlags]::Inherit) | Should -Be $true
            }
            finally {
                $handle.Dispose()
            }
        }

        It "Error on invalid process id" {
            $out = Get-ProcessHandle -ProcessId 999999 -ErrorVariable err -ErrorAction SilentlyContinue

            $out | Should -Be $null
            $err.Count | Should -Be 1
            $err[0] | Should -BeLike 'Failed to get process handle*The parameter is incorrect*'
        }

        It "Error on auth failure" {
            $out = Get-ProcessHandle -ProcessId 4 -ErrorVariable err -ErrorAction SilentlyContinue

            $out | Should -Be $null
            $err.Count | Should -Be 1
            $err[0] | Should -BeLike 'Failed to get process handle*Access is denied*'
        }
    }
}
