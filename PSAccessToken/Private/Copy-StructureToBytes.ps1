# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Copy-StructureToBytes {
    <#
    .SYNOPSIS
    Copies a struct to the byte array specified.

    .PARAMETER Bytes
    The byte array to copy to, this should have enough entries to fit the structure.

    .PARAMETER Structure
    The structure to copy.

    .PARAMETER Offset
    The offset in the byte array to copy to, default to 0.
    #>
    [OutputType([System.Int32])]
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSUseSingularNouns", "",
        Justification="This deals with multiple bytes and not just one."
    )]
    Param (
        [Parameter(Mandatory=$true)]
        [System.Byte[]]
        $Bytes,

        [Parameter(Mandatory=$true)]
        [Object]
        $Structure,

        [System.Int32]
        $Offset = 0
    )

    $structure_size = [System.Runtime.InteropServices.Marshal]::SizeOf($Structure)
    Use-SafePointer -Size $structure_size -Process {
        Param ([System.IntPtr]$Ptr)

        Copy-StructureToPointer -Ptr $Ptr -Structure $Structure > $null
        [System.Runtime.InteropServices.Marshal]::Copy($Ptr, $Bytes, $Offset, $structure_size)

        return $structure_size
    }
}