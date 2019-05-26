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

    .PARAMETER Name
    The name of the privilege to set.

    .PARAMETER Attributes
    The attributes to set for the privilege, defaults to 'Enabled'.

    .PARAMETER DisableAllPrivileges
    Whether to disable all privileges on the token.

    .PARAMETER Strict
    Whether to throw an exception if not all privileges were held by the token.

    .INPUTS
    [PSAccessToken.PrivilegeAndAttributes] A PSCustomObject with the following keys
        Name - The name of the privilege.
        Attributes - The attributes to set on the privilege.

    .OUTPUTS
    [Hashtable] The previous state that can be used for the Privileges parameter of this cmdlet to reverse the
    token privilege adjustment.

    .EXAMPLE Enable a privilege
    $old_state = Set-TokenPrivileges -Name SeTcbPrivilege -Attributes Enabled
    try {
        # Do Work
    } finally {
        $old_state | Set-TokenPrivileges > $null
    }

    .EXAMPLE Disable a privilege
    $old_state = Set-TokenPrivileges -Name SeTcbPrivilege -Attributes Enabled
    try {
        # Do Work
    } finally {
        $old_state | Set-TokenPrivileges > $null
    }

    .EXAMPLE Remove a privilege
    $old_state = Set-TokenPrivileges -Name SeTcbPrivilege -Attributes Enabled
    try {
        # Do Work
    } finally {
        $old_state | Set-TokenPrivileges > $null
    }

    .EXAMPLE Set multiple privilege and attributes in 1 call
    $old_state = @(
        [PSCustomObject]@{ Name = 'SeBackupPrivilege'; Attributes = 'Enabled' },
        [PSCustomObject]@{ Name = 'SeRestorePrivilege'; Attributes = 'Disabled' },
        [PSCustomObject]@{ Name = 'SeTcbPrivilege'; Attributes = 'Removed' }
    ) | Set-TokenPrivileges

    try {
        # Do Work
    } finally {
        $old_state | Set-TokenPrivileges > $null
    }

    .NOTES
    If manipulating multiple privileges, it is recommended to use the pipeline input with multiple
    PrivilegeAndAttributes objects. This way you can set and revert in just 2 calls. The input is the same format
    as the output of Get-TokenPrivileges.
    #>
    [OutputType([Hashtable])]
    [CmdletBinding(DefaultParameterSetName="Token", SupportsShouldProcess=$true)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSUseSingularNouns", "",
        Justification="The cmdlet mirror Get-TokenPrivileges and is a representative of the TokenPrivileges info class enum."
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

        [Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias('Privilege')]
        [AllowEmptyString()]
        [System.String]
        $Name = $null,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [PSAccessToken.TokenPrivilegeAttributes]
        $Attributes = [PSAccessToken.TokenPrivilegeAttributes]::Enabled,

        [Switch]
        $DisableAllPrivileges,

        [Switch]
        $Strict
    )

    Begin {
        # Store variables that will be passed into nested scriptblocks.
        $variables = @{
            disable_all = $DisableAllPrivileges.IsPresent
            strict = $Strict.IsPresent
            adjust_sb = {
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
                    throw "AdjustTokenPrivileges($($Variables.privilege_names -join ', ')) failed: $msg"
                }

                return $length
            }
            privilege_names = [System.Collections.Generic.List`1[System.String]]@()
        }

        # Create a list that will store all the parsed LUID_AND_ATTRIBUTES structure
        $luid_and_attr = [System.Collections.Generic.List`1[[Object]]]@()
    }

    Process {
        if (-not [System.String]::IsNullOrEmpty($Name)) {
            $luid_and_attr.Add(@{Name = $Name; Attributes = $Attributes})
            $variables.privilege_names.Add($Name)
        }
    }

    End {
        Use-ImplicitToken @PSBoundParameters -Access AdjustPrivileges, Query -Variables $variables -Process {
            Param ([PInvokeHelper.SafeNativeHandle]$Token, [Hashtable]$Variables)

            $Variables.token = $Token
            if ($DisableAllPrivileges) {
                # Make sure we have no variables that are actually set.
                $luid_and_attr = [System.Collections.Generic.List`1[System.String]]@()
            } else {
                # Return if no privileges need to be set.
                if ($luid_and_attr.Count -eq 0) {
                    return
                }
            }

            $luid_and_attr | Use-TokenPrivilegesPointer -NullAsEmpty -Variables $Variables -Process {
                Param ([System.IntPtr]$Ptr, [Hashtable]$Variables)

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

                    # Now output the old state so it can be used as an input to this cmdlet to revert the action.
                    return Convert-PointerToTokenPrivileges -Ptr $Ptr
                }
            }
        }
    }
}