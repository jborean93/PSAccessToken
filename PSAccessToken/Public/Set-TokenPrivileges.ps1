# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Set-TokenPrivileges {
    <#
    .SYNOPSIS
    Adjusts the privileges on an access token.

    .DESCRIPTION
    Used to adjust the privileges that are enable/disabled/removed on an access token. This uses the
    AdjustTokenPrivileges Win32 API to achieve this.

    .PARAMETER Token
    An explicit token to use when setting the privileges, falls back to the current thread/process if omitted.

    .PARAMETER ProcessId
    Uses the access token for the process specified, falls back to the current thread/process if omitted.

    .PARAMETER ThreadId
    Uses the thread token for the thread specified, falls back to the current thread/process if omitted.

    .PARAMETER Privileges
    A hashtable or dictionary where the key is the privilege name and the value can be;
        $true = Makes sure the privilege is enabled
        $false = Makes sure the privilege is disabled
        $null = Removes the privilege from the token (no reversing this)

    .PARAMETER DisableAllPrivileges
    Whether to disable all privileges on the token.

    .PARAMETER Strict
    Whether to throw an exception if not all privileges were held by the token.

    .OUTPUTS
    [Hashtable] The previous state that can be used for the Privileges parameter of this cmdlet to reverse the
    token privilege adjustment.

    .EXAMPLE
    $old_state = Set-TokenPrivileges -Token $Token -Privileges @{
        SeTcbPrivilege = $true  # enables the privilege
        SeDebugPrivilege = $false  # disables the privilege
        SeCreatePrimaryToken = $null  # removes the privilege
    }

    try {
        # Do Work
    } finally {
        Set-TokenPrivileges -Token $Token -Privileges $old_state
    }
    #>
    [OutputType([Hashtable])]
    [CmdletBinding(DefaultParameterSetName="Token", SupportsShouldProcess=$true)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSUseSingularNouns", "",
        Justification="The cmdlet is designed to edit privileges in bulk and mirror Get-TokenPrivileges"
    )]
    Param (
        [Parameter(ParameterSetName="Token")]
        [System.Runtime.InteropServices.SafeHandle]
        $Token,

        [Parameter(ParameterSetName="PID")]
        [System.UInt32]
        $ProcessId,

        [Parameter(ParameterSetName="TID")]
        [System.UInt32]
        $ThreadId,

        [AllowNull()]
        [System.Collections.IDictionary]
        $Privileges,

        [Switch]
        $DisableAllPrivileges,

        [Switch]
        $Strict
    )

    Use-ImplicitToken @PSBoundParameters -Access AdjustPrivileges, Query -Process {
        Param ([PInvokeHelper.SafeNativeHandle]$Token)

        $variables = @{
            disable_all = $DisableAllPrivileges.IsPresent
            strict = $Strict.IsPresent
            token = $Token
        }

        if ($DisableAllPrivileges) {
            $new_state_bytes = New-Object -TypeName System.Byte[] -ArgumentList 0
        } else {
            # No privileges need to be adjusted, just return
            if ($null -eq $Privileges -or $Privileges.Count -eq 0) {
                return
            }

            $token_privilege_size = [System.Runtime.InteropServices.Marshal]::SizeOf(
                [Type][PSAccessToken.TOKEN_PRIVILEGES]
            )
            $luid_attr_size = [System.Runtime.InteropServices.Marshal]::SizeOf(
                [Type][PSAccessToken.LUID_AND_ATTRIBUTES]
            ) * ($Privileges.Count - 1)  # TOKEN_PRIVILEGES holds 1 LUID_AND_ATTRIBUTES, remove 1 from this count
            $total_size = $token_privilege_size + $luid_attr_size
            $new_state_bytes = New-Object -TypeName System.Byte[] -ArgumentList $total_size

            $token_privileges = New-Object -TypeName PSAccessToken.TOKEN_PRIVILEGES
            $token_privileges.PrivilegeCount = $Privileges.Count
            $token_privileges.Privileges = New-Object -TypeName PSAccessToken.LUID_AND_ATTRIBUTES[] -ArgumentList 1

            Function ConvertTo-LuidAndAttributesInternal {
                [CmdletBinding()]
                Param (
                    [Parameter(Mandatory=$true)][System.String]$Privilege,
                    $State
                )

                $luid_and_attr = New-Object -TypeName PSAccessToken.LUID_AND_ATTRIBUTES
                $luid_and_attr.Luid = Convert-PrivilegeToLuid -Name $Privilege
                $luid_and_attr.Attributes = switch($State) {
                    $true { [PSAccessToken.TokenPrivilegeAttributes]::Enabled }
                    $false { [PSAccessToken.TokenPrivilegeAttributes]::Disabled }
                    default { [PSAccessToken.TokenPrivilegeAttributes]::Removed }
                }

                return $luid_and_attr
            }

            $privilege_keys = New-Object -TypeName System.String[] -ArgumentList $Privileges.Count
            $Privileges.Keys.CopyTo($privilege_keys, 0)
            $variables.privileges = $privilege_keys
            $first_privilege = $privilege_keys[0]
            $token_privileges.Privileges[0] = ConvertTo-LuidAndAttributesInternal -Privilege $first_privilege -State $Privileges.$first_privilege

            $offset = Copy-StructureToBytes -Bytes $new_state_bytes -Structure $token_privileges

            for ($i = 1; $i -lt $Privileges.Count; $i++) {
                $privilege_name = $privilege_keys[$i]
                $luid_and_attr = ConvertTo-LuidAndAttributesInternal -Privilege $privilege_name -State $Privileges.$privilege_name

                $offset += Copy-StructureToBytes -Bytes $new_state_bytes -Structure $luid_and_attr -Offset $offset
            }
        }

        # Define the scriptblock that calls AdjustTokenPrivileges
        $variables.adjust_sb = {
            Param (
                [System.IntPtr]$PreviousState,
                [System.UInt32]$PreviousStateLength,
                [Hashtable]$Variables,
                [System.Int32[]]$ValidErrors
            )

            $length = $PreviousStateLength
            $res = [PSAccessToken.NativeMethods]::AdjustTokenPrivileges(
                $Variables.token,
                $Variables.disable_all,
                $Variables.new_state,
                $PreviousStateLength,
                $PreviousState,
                [Ref]$length
            ); $err_code = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()

            # The error condition is different depending on whether we called this to get the buffer or to set
            # the privileges.
            if ($PreviousStateLength -eq 0) {
                $failed = ((-not $res) -and ($err_code -notin $ValidErrors))
            } else {
                $failed = ((-not $res) -or ($err_code -notin $ValidErrors))
            }

            if ($failed) {
                $msg = Get-Win32ErrorMessage -ErrorCode $err_code
                throw "AdjustTokenPrivileges($($Variables.privileges -join ', ')) failed: $msg"
            }

            return $length
        }
        $variables.new_state_bytes = $new_state_bytes

        Use-SafePointer -Size $new_state_bytes.Length -Variables $variables -Process {
            Param ([System.IntPtr]$Ptr, [Hashtable]$Variables)

            if ($Variables.new_state_bytes.Length -ne 0) {
                [System.Runtime.InteropServices.Marshal]::Copy(
                    $Variables.new_state_bytes, 0, $Ptr, $Variables.new_state_bytes.Length
                )
            }
            $Variables.new_state = $Ptr

            # Get the size of the previous state buffer
            $Variables.previous_state_length = Use-SafePointer -Size 0 -AllocEmpty -Variables $Variables {
                Param ([System.IntPtr]$Ptr, [Hashtable]$Variables)

                $adjust_params = @{
                    Variables = $Variables
                    PreviousState = $Ptr
                    PreviousStateLength = 0
                    ValidErrors = @(0, 122)
                }
                &$Variables.adjust_sb @adjust_params
            }

            Use-SafePointer -Size $Variables.previous_state_length -Variables $variables -Process {
                Param ([System.IntPtr]$Ptr, [Hashtable]$Variables)

                # Even when res == true, ERROR_NOT_ALL_ASSIGNED may be set as the last error code.
                # Fail if we are running with Strict, otherwise ignore those privileges.
                if ($Variables.strict) {
                    $valid_err_code = @(0)
                } else {
                    $valid_err_code = @(0, 0x00000514)  # ERROR_NOT_ALL_ASSIGNED
                }

                # Call AdjustTokenPrivileges again with the allocated previous state pointer.
                $adjust_params = @{
                    Variables = $Variables
                    PreviousState = $Ptr
                    PreviousStateLength = $Variables.previous_state_length
                    ValidErrors = $valid_err_code
                }

                # Stop short of editing privilege when in -WhatIf
                if (-not $PSCmdlet.ShouldProcess("Token Privileges", "Set")) {
                    return
                }
                &$Variables.adjust_sb @adjust_params > $null

                # Now convert the old state to a hash so it can be used in this function to undo the action
                $previous_state = Convert-PointerToTokenPrivileges -Ptr $Ptr
                $previous_state_hash = @{}
                foreach ($state in $previous_state) {
                    $previous_state_value = $state.Attributes.HasFlag([PSAccessToken.TokenPrivilegeAttributes]::Enabled)
                    $previous_state_hash."$($state.Name)" = $previous_state_value
                }
                return $previous_state_hash
            }
        }
    }
}