# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Use-SafePointer {
    <#
    .SYNOPSIS
    Invokes a script block with an allocated pointer as the -Ptr param.

    .DESCRIPTION
    This cmdlet should be used to when needing to allocated unmanaged memory and reference it with a IntPtr. The
    allocation and de-allocation is done for you.

    .PARAMETER Size
    The number of bytes to allocated in the unmanaged memory heap.

    .PARAMETER Process
    The script block to run. It can reference the pointer using $args[0] or by adding the Param block
        Param ([System.IntPtr]$Ptr)

    .PARAMETER Variables
    Custom variables to pass into the Process scriptblock for execution.

    .PARAMETER AllocEmpty
    Actually allocate a buffer even when Size is 0.

    .EXAMPLE
    Use-SafePointer -Size 4 -Process {
        Param ([System.IntPtr]$Ptr)

        $bytes = New-Object -TypeName System.Byte[] -ArgumentList 4
        [System.Runtime.InteropServices.Marshal]::Copy($Ptr, $bytes, 0, $bytes.Length)

        [System.BitConverter]::ToUInt32($bytes.Length)
    }
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [System.Int32]$Size,

        [Parameter(Mandatory=$true)]
        [ScriptBlock]
        $Process,

        [AllowEmptyCollection()]
        [Hashtable]
        $Variables = @{},

        [Switch]
        $AllocEmpty
    )

    if ($Size -eq 0 -and -not $AllocEmpty) {
        $safe_ptr = [System.IntPtr]::Zero
    } else {
        $safe_ptr = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($Size)
    }

    try {
        &$Process -Ptr $safe_ptr -Variables $Variables
    } finally {
        if ($safe_ptr -ne [System.IntPtr]::Zero) {
            [System.Runtime.InteropServices.Marshal]::FreeHGlobal($safe_ptr)
        }
    }
}