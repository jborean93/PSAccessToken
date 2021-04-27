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
                $old_state.Length | Should -Be $enabled_priv_count
                foreach ($state in $old_state.GetEnumerator()) {
                    $old_priv_state = $original_privileges | Where-Object { $_.Name -eq $state.Name }
                    $old_priv_state.Attributes.HasFlag([PSAccessToken.TokenPrivilegeAttributes]::Enabled) | Should -Be $true

                    $new_priv_state = $new_privileges | Where-Object { $_.Name -eq $state.Name }
                    $new_priv_state.Attributes.HasFlag([PSAccessToken.TokenPrivilegeAttributes]::Disabled) | Should -Be $true
                }

                foreach ($priv in $new_privileges) {
                    $priv.Attributes.HasFlag([PSAccessToken.TokenPrivilegeAttributes]::Disabled) | Should -Be $true
                }

                # Reset the privileges back to before and get the state again
                $new_state = $old_state | Set-TokenPrivileges -Token $h_token
                $final_privileges = Get-TokenPrivileges -Token $h_token

                $new_state.Length | Should -Be $enabled_priv_count
                foreach ($state in $new_state.GetEnumerator()) {
                    $final_priv_state = $final_privileges | Where-Object { $_.Name -eq $state.Name }
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
                $old_state = @(
                    [PSCustomObject]@{Name = $priv_names[0]; Attributes = 'Removed'},
                    [PSCustomObject]@{Name = $priv_names[1]; Attributes = 'Removed'}
                ) |Set-TokenPrivileges -Token $h_token -WhatIf
                $old_state | Should -Be $null

                $privileges = Get-TokenPrivileges -Token $h_token
                $privileges | Where-Object { $_.Name -eq $priv_names[0] } | Should -Not -Be $null
                $privileges | Where-Object { $_.Name -eq $priv_names[1] } | Should -Not -Be $null

                $old_state = @(
                    [PSCustomObject]@{Name = $priv_names[0]; Attributes = 'Removed'},
                    [PSCustomObject]@{Name = $priv_names[1]; Attributes = 'Removed'}
                ) | Set-TokenPrivileges -Token $h_token
                $old_state | Should -Be $null  # Cannot add a privilege that has been removed

                # Make sure we can safely pass null in through the pipeline input without errors
                $old_state | Set-TokenPrivileges -Token $h_token | Should -Be $null

                # Assert that the privileges have been removed
                $privileges = Get-TokenPrivileges -Token $h_token
                $privileges | Where-Object { $_.Name -eq $priv_names[0] } | Should -Be $null
                $privileges | Where-Object { $_.Name -eq $priv_names[1] } | Should -Be $null

                # Make sure we didn't remove it from our current access token
                $curr_privilege = Get-TokenPrivileges
                $curr_privilege | Where-Object { $_.Name -eq $priv_names[0] } | Should -Not -Be $null
                $curr_privilege | Where-Object { $_.Name -eq $priv_names[1] } | Should -Not -Be $null

                # Remove privilege again
                $old_state = Set-TokenPrivileges -Token $h_token -Name $priv_names[0] -Attributes 'Removed'
                $old_state | Should -Be $null
            } finally {
                $h_token.Dispose()
            }
        }

        It 'Disables a privileges' {
            $h_token = Copy-AccessToken
            try {
                # Set initial state to enabled
                $priv_name = (Get-TokenPrivileges -Token $h_token).Name[0]
                Set-TokenPrivileges -Token $h_token -Name $priv_name -Attributes Enabled > $null

                # Run with -WhatIf
                $old_state = Set-TokenPrivileges -Token $h_token -Name $priv_name -Attributes Disabled -WhatIf
                $old_state | Should -Be $null
                $privileges = Get-TokenPrivileges -Token $h_token
                ($privileges | Where-Object { $_.Name -eq $priv_name }).Attributes.HasFlag([PSAccessToken.TokenPrivilegeAttributes]::Enabled) | Should -Be $true

                # Disable privilege
                $old_state = [PSCustomObject]@{Name = $priv_name; Attributes = 'Disabled'} | Set-TokenPrivileges -Token $h_token
                $old_state.Attributes.HasFlag([PSAccessToken.TokenPrivilegeAttributes]::Enabled)

                $privileges = Get-TokenPrivileges -Token $h_token
                ($privileges | Where-Object { $_.Name -eq $priv_name }).Attributes.HasFlag([PSAccessToken.TokenPrivilegeAttributes]::Enabled) | Should -Be $false

                # Disable the privilege again
                $old_state = Set-TokenPrivileges -Token $h_token -Name $priv_name -Attributes Disabled
                $old_state | Should -Be $null
            } finally {
                $h_token.Dispose()
            }
        }

        It 'Enables a privilege' {
            $h_token = Copy-AccessToken
            try {
                # Set initial state to enabled
                $priv_name = (Get-TokenPrivileges -Token $h_token).Name[0]
                Set-TokenPrivileges -Token $h_token -Name $priv_name -Attributes Disabled > $null

                # Run with -WhatIf
                $old_state = Set-TokenPrivileges -Token $h_token -Name $priv_name -Attributes Enabled -WhatIf
                $old_state | Should -Be $null
                $privileges = Get-TokenPrivileges -Token $h_token
                ($privileges | Where-Object { $_.Name -eq $priv_name }).Attributes.HasFlag([PSAccessToken.TokenPrivilegeAttributes]::Enabled) | Should -Be $false

                # Enable privilege
                $old_state = Set-TokenPrivileges -Token $h_token -Name $priv_name
                $old_state.Attributes.HasFlag([PSAccessToken.TokenPrivilegeAttributes]::Disabled)

                $privileges = Get-TokenPrivileges -Token $h_token
                ($privileges | Where-Object { $_.Name -eq $priv_name }).Attributes.HasFlag([PSAccessToken.TokenPrivilegeAttributes]::Enabled) | Should -Be $true

                # Enable the privilege again
                $old_state = [PSCustomObject]@{Name=$priv_name; Attributes='Enabled'} | Set-TokenPrivileges -Token $h_token
                $old_state | Should -Be $null
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
            $state1 = Set-TokenPrivileges
            $state2 = Set-TokenPrivileges -Name ''
            $after_priv = Get-TokenPrivileges

            $state1 | Should -Be $null
            $state2 | Should -Be $null
            $before_priv.Length | Should -Be $after_priv.Length
            foreach ($before in $before_priv) {
                $after = $after_priv | Where-Object { $_.Name -eq $before.Name }
                $before.Attributes | Should -Be $after.Attributes
            }
        }

        It 'Fails with invalid privilege name' {
            $expected = "Failed to get LUID value for privilege 'FakePrivilege': A specified privilege does not exist (Win32 ErrorCode 1313 - 0x00000521)"
            { Set-TokenPrivileges -Name FakePrivilege } | Should -Throw $expected
        }

        It 'Succeess with not strict and privilege not held' {
            $h_token = Copy-AccessToken
            try {
                # Remove a privilege
                Set-TokenPrivileges -Token $h_token -Name SeTcbPrivilege -Attributes 'Removed'

                $state = @(
                    [PSCustomObject]@{ Name = 'SeChangeNotifyPrivilege'; Attributes = 'Disabled' },
                    [PSCustomObject]@{ Name = 'SeTcbPrivilege'; Attributes = 'Enabled' }
                ) | Set-TokenPrivileges -Token $h_token
                $privileges = Get-TokenPrivileges -Token $h_token

                $state.GetType() | Should -Be ([System.Management.Automation.PSCustomObject])
                $state.Name | Should -Be 'SeChangeNotifyPrivilege'
                $state.Attributes | Should -Be 'EnabledByDefault, Enabled'  # Previous state
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
                @(
                    [PSCustomObject]@{ Name = 'SeTcbPrivilege'; Attributes = 'Removed' },
                    [PSCustomObject]@{ Name = 'SeIncreaseWorkingSetPrivilege'; Attributes = 'Disabled' }
                ) | Set-TokenPrivileges -Token $h_token > $null

                {
                    @(
                        [PSCustomObject]@{ Name = 'SeIncreaseWorkingSetPrivilege'; Attributes = 'Enabled' },
                        [PSCustomObject]@{ Name = 'SeTcbPrivilege'; Attributes = 'Enabled' }
                    ) | Set-TokenPrivileges -Token $h_token -Strict > $null
                } | Should -Throw $expected
            } finally {
                $h_token.Dispose()
            }
        }
    }
}