$moduleName   = (Get-Item ([IO.Path]::Combine($PSScriptRoot, '..', 'module', '*.psd1'))).BaseName
$manifestPath = [IO.Path]::Combine($PSScriptRoot, '..', 'build', $moduleName)

Import-Module $manifestPath

Describe "Get-ProcessHandle" {
    Context "Current process" {
        It "Has the expected psuedo handle value" {
            $handle = Get-ProcessHandle
            $handle.DangerousGetHandle() | Should -Be ([IntPtr]::new(-1))
        }

        It "Is not invalid" {
            $handle = Get-ProcessHandle
            $handle.IsInvalid | Should -Be $false
        }

        It "Is not closed" {
            $handle = Get-ProcessHandle
            $handle.IsClosed | Should -Be $false

            $handle.Dispose()

            $handle.IsClosed | Should -be $true
        }
    }

    Context "Explicit process" {
        It "Does not use the psuedo handle" {
            $handle = Get-ProcessHandle -ProcessId $pid
            $handle.DangerousGetHandle() | Should -Not -Be ([IntPtr]::new(-1))
        }

        It "Is not invalid" {
            $handle = Get-ProcessHandle -Id $pid
            $handle.IsInvalid | Should -Be $false
        }

        It "Is not closed" {
            $handle = Get-ProcessHandle -ProcessId $pid
            $handle.IsClosed | Should -Be $false

            $handle.Dispose()

            $handle.IsClosed | Should -be $true
        }

        It "Works with pipeline input" {
            $handle = $pid | Get-ProcessHandle

            $handle.IsInvalid | Should -Be $false
        }

        It "Works with array of pids" {
            $handle = Get-ProcessHandle -ProcessId $pid, $pid

            $handle.Count | Should -Be 2
            $handle[0].IsInvalid | Should -Be $false
            $handle[1].IsInvalid | Should -Be $false
        }
    }
}
