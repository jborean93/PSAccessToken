# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

$verbose = @{}
if ($env:APPVEYOR_REPO_BRANCH -and $env:APPVEYOR_REPO_BRANCH -notlike "master") {
    $verbose.Add("Verbose", $true)
}

$ps_version = $PSVersionTable.PSVersion.Major
$cmdlet_name = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
$module_name = (Get-ChildItem -Path $PSScriptRoot\.. -Directory -Exclude @("Build", "Docs", "Tests")).Name
Import-Module -Name $PSScriptRoot\..\$module_name -Force

Describe "$cmdlet_name PS$ps_version tests" {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It 'Disables all token privileges' {
            $h_token = Copy-AccessToken
            try {
                # Get the current privileges on the token then disable all privileges
                $original_privileges = Get-TokenPrivileges -Token $h_token
                $enabled_priv_count = ($original_privileges | Where-Object { $_.Attributes.HasFlag([PSAccessToken.TokenPrivilegeAttributes]::Enabled) }).Length

                $old_state = Set-TokenPrivileges -Token $h_token -DisableAllPrivileges
                $new_privileges = Get-TokenPrivileges -Token $h_token

                # Verify that all the enabled privileges have now been disabled
                $old_state.Count | Should -Be $enabled_priv_count
                foreach ($state in $old_state.GetEnumerator()) {
                    $priv_name = $state.Key
                    $old_priv_state = $original_privileges | Where-Object { $_.Name -eq $priv_name }
                    $old_priv_state.Attributes.HasFlag([PSAccessToken.TokenPrivilegeAttributes]::Enabled) | Should -Be $true

                    $new_priv_state = $new_privileges | Where-Object { $_.Name -eq $priv_name }
                    $new_priv_state.Attributes.HasFlag([PSAccessToken.TokenPrivilegeAttributes]::Disabled) | Should -Be $true
                }

                foreach ($priv in $new_privileges) {
                    $priv.Attributes.HasFlag([PSAccessToken.TokenPrivilegeAttributes]::Disabled) | Should -Be $true
                }

                # Reset the privileges back to before and get the state again
                $new_state = Set-TokenPrivileges -Token $h_token -Privileges $old_state
                $final_privileges = Get-TokenPrivileges -Token $h_token

                $new_state.Count | Should -Be $enabled_priv_count
                foreach ($state in $new_state.GetEnumerator()) {
                    $priv_name = $state.Key

                    $final_priv_state = $final_privileges | Where-Object { $_.Name -eq $priv_name }
                    $final_priv_state.Attributes.HasFlag([PSAccessToken.TokenPrivilegeAttributes]::Enabled) | Should -Be $true
                }
            } finally {
                $h_token.Dispose()
            }
        }

        It 'Removes a privilege' {
            $h_token = Copy-AccessToken
            try {
                $priv_names = (Get-TokenPrivileges -Token $h_token).Name

                # Remove privilege with -WhatIf
                $old_state = Set-TokenPrivileges -Token $h_token -Privileges @{$priv_names[0] = $null; $priv_names[1] = $null} -WhatIf
                $old_state | Should -Be $null
                $privileges = Get-TokenPrivileges -Token $h_token
                $privileges | Where-Object { $_.Name -eq $priv_names[0] } | Should -Not -Be $null
                $privileges | Where-Object { $_.Name -eq $priv_names[1] } | Should -Not -Be $null


                $old_state = Set-TokenPrivileges -Token $h_token -Privileges @{$priv_names[0] = $null; $priv_names[1] = $null}
                $old_state.Count | Should -Be 0  # Cannot add a privilege that has been removed

                # Assert that the privileges have been removed
                $privileges = Get-TokenPrivileges -Token $h_token
                $privileges | Where-Object { $_.Name -eq $priv_names[0] } | Should -Be $null
                $privileges | Where-Object { $_.Name -eq $priv_names[1] } | Should -Be $null

                # Make sure we didn't remove it from our current access token
                $curr_privilege = Get-TokenPrivileges
                $curr_privilege | Where-Object { $_.Name -eq $priv_names[0] } | Should -Not -Be $null
                $curr_privilege | Where-Object { $_.Name -eq $priv_names[1] } | Should -Not -Be $null

                # Remove privilege again
                $old_state = Set-TokenPrivileges -Token $h_token -Privileges @{$priv_names[0] = $null}
                $old_state.Count | Should -Be 0
            } finally {
                $h_token.Dispose()
            }
        }

        It 'Disables a privileges' {
            $h_token = Copy-AccessToken
            try {
                # Set initial state to enabled
                $priv_name = (Get-TokenPrivileges -Token $h_token).Name[0]
                Set-TokenPrivileges -Token $h_token -Privileges @{$priv_name = $true} > $null

                # Run with -WhatIf
                $old_state = Set-TokenPrivileges -Token $h_token -Privileges @{$priv_name = $false} -WhatIf
                $old_state | Should -Be $null
                $privileges = Get-TokenPrivileges -Token $h_token
                ($privileges | Where-Object { $_.Name -eq $priv_name }).Attributes.HasFlag([PSAccessToken.TokenPrivilegeAttributes]::Enabled) | Should -Be $true

                # Disable privilege
                $old_state = Set-TokenPrivileges -Token $h_token -Privileges @{$priv_name = $false}
                $privileges = Get-TokenPrivileges -Token $h_token
                ($privileges | Where-Object { $_.Name -eq $priv_name }).Attributes.HasFlag([PSAccessToken.TokenPrivilegeAttributes]::Enabled) | Should -Be $false

                # Disable the privilege again
                $old_state = Set-TokenPrivileges -Token $h_token -Privileges @{$priv_name = $false}
                $old_state.Count | Should -Be 0
            } finally {
                $h_token.Dispose()
            }
        }

        It 'Enables a privilege' {
            $h_token = Copy-AccessToken
            try {
                # Set initial state to disabled
                $priv_name = (Get-TokenPrivileges -Token $h_token).Name[0]
                Set-TokenPrivileges -Token $h_token -Privileges @{$priv_name = $false} > $null

                # Run with -WhatIf
                $old_state = Set-TokenPrivileges -Token $h_token -Privileges @{$priv_name = $true} -WhatIf
                $old_state | Should -Be $null
                $privileges = Get-TokenPrivileges -Token $h_token
                ($privileges | Where-Object { $_.Name -eq $priv_name }).Attributes.HasFlag([PSAccessToken.TokenPrivilegeAttributes]::Enabled) | Should -Be $false

                # Enable privilege
                $old_state = Set-TokenPrivileges -Token $h_token -Privileges @{$priv_name = $true}
                $privileges = Get-TokenPrivileges -Token $h_token
                ($privileges | Where-Object { $_.Name -eq $priv_name }).Attributes.HasFlag([PSAccessToken.TokenPrivilegeAttributes]::Enabled) | Should -Be $true

                # Enable the privilege again
                $old_state = Set-TokenPrivileges -Token $h_token -Privileges @{$priv_name = $true}
                $old_state.Count | Should -Be 0
            } finally {
                $h_token.Dispose()
            }
        }

        It 'Sets no parameters' {
            $before_priv = Get-TokenPrivileges
            $state = Set-TokenPrivileges
            $after_priv = Get-TokenPrivileges

            $state | Should -Be $null
            $before_priv.Length | Should -Be $after_priv.Length
            foreach ($before in $before_priv) {
                $after = $after_priv | Where-Object { $_.Name -eq $before.Name }
                $before.Attributes | Should -Be $after.Attributes
            }
        }

        It 'Sets null -Privileges' {
            $before_priv = Get-TokenPrivileges
            $state = Set-TokenPrivileges -Privileges $null
            $after_priv = Get-TokenPrivileges

            $state | Should -Be $null
            $before_priv.Length | Should -Be $after_priv.Length
            foreach ($before in $before_priv) {
                $after = $after_priv | Where-Object { $_.Name -eq $before.Name }
                $before.Attributes | Should -Be $after.Attributes
            }
        }

        It 'Sets empty -Privileges' {
            $before_priv = Get-TokenPrivileges
            $state = Set-TokenPrivileges -Privileges @{}
            $after_priv = Get-TokenPrivileges

            $state | Should -Be $null
            $before_priv.Length | Should -Be $after_priv.Length
            foreach ($before in $before_priv) {
                $after = $after_priv | Where-Object { $_.Name -eq $before.Name }
                $before.Attributes | Should -Be $after.Attributes
            }
        }

        It 'Fails with invalid privilege name' {
            $expected = "Failed to get LUID value for privilege 'FakePrivilege': A specified privilege does not exist (Win32 ErrorCode 1313 - 0x00000521)"
            { Set-TokenPrivileges -Privileges @{ FakePrivilege = $true } } | Should -Throw $expected
        }

        It 'Succees with not strict and privilege not held' {
            $h_token = Copy-AccessToken
            try {
                # Remove a privilege
                Set-TokenPrivileges -Token $h_token -Privileges @{ SeTcbPrivilege = $null }

                $state = Set-TokenPrivileges -Token $h_token -Privileges @{ SeChangeNotifyPrivilege = $false; SeTcbPrivilege = $true }
                $privileges = Get-TokenPrivileges -Token $h_token

                $state.Count | Should -Be 1
                $state.SeChangeNotifyPrivilege | Should -Be $true
                ($privileges | Where-Object { $_.Name -eq 'SeChangeNotifyPrivilege' }).Attributes.HasFlag([PSAccessToken.TokenPrivilegeAttributes]::Enabled) | Should -Be $false
            } finally {
                $h_token.Dispose()
            }
        }

        It 'Fails with strict and privilege not held' {
            $expected = 'AdjustTokenPrivileges(SeIncreaseWorkingSetPrivilege, SeTcbPrivilege) failed: '
            $expected += 'Not all privileges or groups referenced are assigned to the caller (Win32 ErrorCode 1300 - 0x00000514)'
            $h_token = Copy-AccessToken
            try {
                # Remove a privilege and ensure a privilege is disabled
                Set-TokenPrivileges -Token $h_token -Privileges @{ SeTcbPrivilege = $null; SeIncreaseWorkingSetPrivilege = $false } > $null

                { Set-TokenPrivileges -Token $h_token -Privileges @{ SeIncreaseWorkingSetPrivilege = $true; SeTcbPrivilege = $true } -Strict } | Should -Throw $expected
            } finally {
                $h_token.Dispose()
            }
        }
    }
}