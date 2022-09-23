. ([IO.Path]::Combine($PSScriptRoot, 'common.ps1'))

Describe "Get-ThreadHandle" {
    Context "Current thread" {
        It "Has the expected psuedo handle value" {
            $handle = Get-ThreadHandle
            try {
                $handle.DangerousGetHandle() | Should -Be ([IntPtr]::new(-2))
            }
            finally {
                $handle.Dispose()
            }
        }

        It "Is not invalid" {
            $handle = Get-ThreadHandle
            try {
                $handle.IsInvalid | Should -Be $false
            }
            finally {
                $handle.Dispose()
            }
        }

        It "Is not closed" {
            $handle = Get-ThreadHandle
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
            $handle = Get-ThreadHandle -Inherit
            try {
                $handle.DangerousGetHandle() | Should -Not -Be ([IntPtr]::new(-2))

                $info = Get-HandleInformation -Handle $handle
                $info.HasFlag([PSAccessToken.HandleFlags]::Inherit) | Should -Be $true
            }
            finally {
                $handle.Dispose()
            }
        }

        It "Access is not psuedo handle" {
            $handle = Get-ThreadHandle -Access QueryInformation
            try {
                $handle.DangerousGetHandle() | Should -Not -Be ([IntPtr]::new(-2))
            }
            finally {
                $handle.Dispose()
            }
        }
    }

    Context "Explicit thread" {
        BeforeAll {
            $tid = Get-CurrentThreadId
        }

        It "Does not use the psuedo handle" {
            $handle = Get-ThreadHandle -ThreadId $tid
            try {
                $handle.DangerousGetHandle() | Should -Not -Be ([IntPtr]::new(-1))
            }
            finally {
                $handle.Dispose()
            }
        }

        It "Is not invalid" {
            $handle = Get-ThreadHandle -ThreadId $tid
            try {
                $handle.IsInvalid | Should -Be $false
            }
            finally {
                $handle.Dispose()
            }
        }

        It "Is not closed" {
            $handle = Get-ThreadHandle -ThreadId $tid
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
            $handle = $tid | Get-ThreadHandle
            try {
                $handle.IsInvalid | Should -Be $false
            }
            finally {
                $handle.Dispose()
            }
        }

        It "Works with array of pids" {
            $handle = Get-ThreadHandle -ThreadId $tid, $tid
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
            $handle = $tid | Get-ThreadHandle
            try {
                $res = Get-HandleInformation -Handle $handle
                $res.HasFlag([PSAccessToken.HandleFlags]::Inherit) | Should -Be $false
            }
            finally {
                $handle.Dispose()
            }

            $handle = $tid | Get-ThreadHandle -Inherit
            try {
                $res = Get-HandleInformation -Handle $handle
                $res.HasFlag([PSAccessToken.HandleFlags]::Inherit) | Should -Be $true
            }
            finally {
                $handle.Dispose()
            }
        }

        It "Error on invalid thread id" {
            $out = Get-ThreadHandle -ThreadId 999999 -ErrorVariable err -ErrorAction SilentlyContinue

            $out | Should -Be $null
            $err.Count | Should -Be 1
            $err[0] | Should -BeLike 'Failed to get thread handle*The parameter is incorrect*'
        }
    }
}
