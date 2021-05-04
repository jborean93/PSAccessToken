$moduleName   = (Get-Item ([IO.Path]::Combine($PSScriptRoot, '..', 'module', '*.psd1'))).BaseName
$manifestPath = [IO.Path]::Combine($PSScriptRoot, '..', 'build', $moduleName)

Import-Module $manifestPath

Describe "Get-ThreadToken" {
    Context "Current thread" {
        It "Failure with no impersonation" {
            $out = Get-ThreadToken -ErrorAction SilentlyContinue -ErrorVariable err

            $out | Should -Be $null
            $err.Count | Should -Be 1
            $err[0] | Should -BeLike 'Failed to get thread token*token that does not exist*'
        }
    }

    Context "Specific thread" {
        BeforeAll {
            $tid = Get-CurrentThreadId
            $thread = Get-ThreadHandle
        }

        AfterAll {
            $thread.Dispose()
        }

        It "Failure with no impersonation" {
            $out = Get-ThreadToken -Thread $thread -ErrorAction SilentlyContinue -ErrorVariable err

            $out | Should -Be $null
            $err.Count | Should -Be 1
            $err[0] | Should -BeLike 'Failed to get thread token*token that does not exist*'
        }

        It "Failure by tid with no impersonation" {
            $out = Get-ThreadToken -ThreadId $tid -ErrorAction SilentlyContinue -ErrorVariable err

            $out | Should -Be $null
            $err.Count | Should -Be 1
            $err[0] | Should -BeLike 'Failed to get thread token*token that does not exist*'
        }

        It "Fails to open token - invalid access" {
            $limitedProcess = Get-ThreadHandle -Id $tid -Access Impersonate
            $out = Get-ThreadToken -Thread $limitedProcess -ErrorVariable err -ErrorAction SilentlyContinue

            $out | Should -Be $null
            $err.Count | Should -Be 1
            $err[0] | Should -BeLike 'Failed to get thread token*Access is denied*'
        }
    }
}
