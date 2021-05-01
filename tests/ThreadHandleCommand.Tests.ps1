$moduleName   = (Get-Item ([IO.Path]::Combine($PSScriptRoot, '..', 'module', '*.psd1'))).BaseName
$manifestPath = [IO.Path]::Combine($PSScriptRoot, '..', 'build', $moduleName)

Import-Module $manifestPath

Describe "Get-ThreadHandle" {
    Context "Current thread" {
        It "Has the expected psuedo handle value" {
            $handle = Get-ThreadHandle
            $handle.DangerousGetHandle() | Should -Be ([IntPtr]::new(-2))
        }

        It "-Current always means current process" {
            $handle = Get-ThreadHandle -Current
            $handle.DangerousGetHandle() | Should -Be ([IntPtr]::new(-2))

            $handle = Get-ThreadHandle -Current:$false
            $handle.DangerousGetHandle() | Should -Be ([IntPtr]::new(-2))
        }

        It "Is not invalid" {
            $handle = Get-ThreadHandle
            $handle.IsInvalid | Should -Be $false
        }

        It "Is not closed" {
            $handle = Get-ThreadHandle
            $handle.IsClosed | Should -Be $false

            $handle.Dispose()

            $handle.IsClosed | Should -be $true
        }
    }

    Context "Explicit thread" {
        BeforeAll {
            Add-Type -Namespace ThreadTest -Name Native -MemberDefinition @'
[DllImport("Kernel32.dll")]
public static extern int GetCurrentThreadId();
'@
            $tid = [ThreadTest.Native]::GetCurrentThreadId()
        }

        It "Does not use the psuedo handle" {
            $handle = Get-ThreadHandle -ThreadId $tid
            $handle.DangerousGetHandle() | Should -Not -Be ([IntPtr]::new(-1))
        }

        It "Is not invalid" {
            $handle = Get-ThreadHandle -ThreadId $tid
            $handle.IsInvalid | Should -Be $false
        }

        It "Is not closed" {
            $handle = Get-ThreadHandle -ThreadId $tid
            $handle.IsClosed | Should -Be $false

            $handle.Dispose()

            $handle.IsClosed | Should -be $true
        }

        It "Works with pipeline input" {
            $handle = $tid | Get-ThreadHandle

            $handle.IsInvalid | Should -Be $false
        }

        It "Works with array of pids" {
            $handle = Get-ThreadHandle -ThreadId $tid, $tid

            $handle.Count | Should -Be 2
            $handle[0].IsInvalid | Should -Be $false
            $handle[1].IsInvalid | Should -Be $false
        }

        It "Get inheritable handle" {
            $handle = $tid | Get-ThreadHandle
            $res = Get-HandleInformation -Handle $handle
            $res.HasFlag([PSAccessToken.HandleFlags]::Inherit) | Should -Be $false

            $handle = $tid | Get-ThreadHandle -Inherit
            $res = Get-HandleInformation -Handle $handle
            $res.HasFlag([PSAccessToken.HandleFlags]::Inherit) | Should -Be $true
        }

        It "Error on invalid thread id" {
            $out = Get-ThreadHandle -ThreadId 999999 -ErrorVariable err -ErrorAction SilentlyContinue

            $out | Should -Be $null
            $err.Count | Should -Be 1
            $err[0] | Should -BeLike 'Failed to get thread handle*The parameter is incorrect*'
        }
    }
}
