# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Convert-PointerToPrivilegeAndAttributes {
    <#
    .SYNOPSIS
    Converts a pointer to LuidAndAttributes object.

    .DESCRIPTION
    Converts a pointer to unmanaged memory to a managed object that represents an array of LUID_AND_ATTRIBUTES struct.

    .PARAMETER Ptr
    The IntPtr to the unmanaged memory of the LUID_AND_ATTRIBUTES array.

    .PARAMETER Count
    The number of LUID_AND_ATTRIBUTES entries in the unmanaged array.
    #>
    [OutputType('PSAccessToken.PrivilegeAndAttributes')]
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSUseSingularNouns", "",
        Justification="The actual object is called LUID_AND_ATTRIBUTES"
    )]
    Param (
        [Parameter(Mandatory=$true)]
        [System.IntPtr]
        $Ptr,

        [Parameter(Mandatory=$true)]
        [System.UInt32]
        $Count
    )

    for ($i = 0; $i -lt $Count; $i++) {
        $luid_and_attributes = [System.Runtime.InteropServices.Marshal]::PtrToStructure(
            $Ptr, [Type][PSAccessToken.LUID_AND_ATTRIBUTES]
        )

        [PSCustomObject]@{
            PSTypeName = 'PSAccessToken.PrivilegeAndAttributes'
            Name = Convert-LuidToPrivilege -Luid $luid_and_attributes.Luid
            Attributes = $luid_and_attributes.Attributes
        }

        # Increment the ptr so we get the next LUID_AND_ATTRIBUTE entry
        $Ptr = [System.IntPtr]::Add($Ptr, [System.Runtime.InteropServices.Marshal]::SizeOf($luid_and_attributes))
    }
}