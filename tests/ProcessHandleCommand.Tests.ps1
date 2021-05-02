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

        It "Inherit is not psuedo handle" {
            $handle = Get-ProcessHandle -Inherit
            $handle.DangerousGetHandle() | Should -Not -Be ([IntPtr]::new(-1))

            $info = Get-HandleInformation -Handle $handle
            $info.HasFlag([PSAccessToken.HandleFlags]::Inherit) | Should -Be $true
        }

        It "Access is not psuedo handle" {
            $handle = Get-ProcessHandle -Access QueryInformation
            $handle.DangerousGetHandle() | Should -Not -Be ([IntPtr]::new(-1))
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

        It "Get inheritable handle" {
            $handle = $pid | Get-ProcessHandle
            $res = Get-HandleInformation -Handle $handle
            $res.HasFlag([PSAccessToken.HandleFlags]::Inherit) | Should -Be $false

            $handle = $pid | Get-ProcessHandle -Inherit
            $res = Get-HandleInformation -Handle $handle
            $res.HasFlag([PSAccessToken.HandleFlags]::Inherit) | Should -Be $true
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
