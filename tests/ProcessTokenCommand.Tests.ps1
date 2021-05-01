$moduleName   = (Get-Item ([IO.Path]::Combine($PSScriptRoot, '..', 'module', '*.psd1'))).BaseName
$manifestPath = [IO.Path]::Combine($PSScriptRoot, '..', 'build', $moduleName)

Import-Module $manifestPath

Describe "Get-ProcessToken" {
    Context "Current process" {
        It "Gets token" {
            $handle = Get-ProcessToken

            $handle.IsInvalid | Should -Be $false
            $handle.IsClosed | Should -Be $false
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

        It "Gets token" {
            $handle = Get-ProcessToken -Process $process

            $handle.IsInvalid | Should -Be $false
            $handle.IsClosed | Should -Be $false
        }

        It "Pipe handle to input" {
            $handle = $process | Get-ProcessToken

            $handle.IsInvalid | Should -Be $false
            $handle.IsClosed | Should -Be $false
        }

        It "Fails to open token - invalid access" {
            $limitedProcess = Get-ProcessHandle -Id $pid -Access CreateProcess
            $out = Get-ProcessToken -Process $limitedProcess -ErrorVariable err -ErrorAction SilentlyContinue

            $out | Should -Be $null
            $err.Count | Should -Be 1
            $err[0] | Should -BeLike 'Failed to get process token*Access is denied*'
        }
    }
}
