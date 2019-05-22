# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Convert-PointerToUInt32 {
    <#
    .SYNOPSIS
    Convert a pointer to a UInt32 value.

    .DESCRIPTION
    Convert a pointer that points to an unmanage block of memory that represents a UInt32.

    .PARAMETER Ptr
    The pointer to the unmanaged block of memory.

    .NOTES
    The memory at the Ptr should only be 4 bytes.
    #>
    [OutputType([System.UInt32])]
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [System.IntPtr]
        $Ptr
    )

    $raw_bytes = New-Object -TypeName System.Byte[] -ArgumentList 4
    [System.Runtime.InteropServices.Marshal]::Copy($Ptr, $raw_bytes, 0, 4)
    [System.BitConverter]::ToUInt32($raw_bytes, 0)
}