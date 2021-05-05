. ([IO.Path]::Combine($PSScriptRoot, 'common.ps1'))

Describe "Get-ProcessToken" {
    Context "Current process" {
        It "Gets token" {
            $handle = Get-ProcessToken
            try {
                $handle.IsInvalid | Should -Be $false
                $handle.IsClosed | Should -Be $false
            }
            finally {
                $handle.Dispose()
            }
        }

        It "Closes the token" {
            $handle = Get-ProcessToken
            $handle.Dispose()

            $handle.IsClosed | Should -Be $true
        }
    }

    Context "Specific process" {
        BeforeAll {
            $process = Get-ProcessHandle
        }

        AfterAll {
            $process.Dispose()
        }

        It "Gets token" {
            $handle = Get-ProcessToken -Process $process
            try {
                $handle.IsInvalid | Should -Be $false
                $handle.IsClosed | Should -Be $false
            }
            finally {
                $handle.Dispose()
            }
        }

        It "Pipe handle to input" {
            $handle = $process | Get-ProcessToken
            try {
                $handle.IsInvalid | Should -Be $false
                $handle.IsClosed | Should -Be $false
            }
            finally {
                $handle.Dispose()
            }
        }

        It "Fails to open token - invalid access" {
            $limitedProcess = Get-ProcessHandle -Id $pid -Access CreateProcess
            try {
                $out = Get-ProcessToken -Process $limitedProcess -ErrorVariable err -ErrorAction SilentlyContinue
            }
            finally {
                $limitedProcess.Dispose()
            }

            $out | Should -Be $null
            $err.Count | Should -Be 1
            $err[0] | Should -BeLike 'Failed to get process token*Access is denied*'
        }
    }
}
