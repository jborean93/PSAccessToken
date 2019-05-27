# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Convert-PointerToSidAndAttributesHash {
    <#
    .SYNOPSIS
    Converts a pointer to SidAndAttributesHash object.

    .DESCRIPTION
    Converts a pointer to unmanaged memory to a managed object that represents a SID_AND_ATTRIBUTES_HASH struct.

    .PARAMETER Ptr
    The IntPtr to the unmanaged memory of the SID_AND_ATTRIBUTES_HASH struct.

    .OUTPUTS
    [PSAccessToken.SidAndAttributesHash]
        Hash: The hash value of Sids, this is UInt32 array of 32 elements.
        Sids: A PSAccessToken.SidAndAttributes object.
    #>
    [OutputType('PSAccessToken.SidAndAttributesHash')]
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [System.IntPtr]
        $Ptr
    )

    $hash = [System.Runtime.InteropServices.Marshal]::PtrToStructure(
        $Ptr, [Type][PSAccessToken.SID_AND_ATTRIBUTES_HASH]
    )

    [PSCustomObject]@{
        PSTypeName = 'PSAccessToken.SidAndAttributesHash'
        Hash = $hash.Hash
        Sids = Convert-PointerToSidAndAttributes -Ptr $hash.SidAttr -Count $hash.SidCount
    }
}