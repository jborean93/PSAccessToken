# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Convert-PointerToTokenGroups {
    <#
    .SYNOPSIS
    Converts a pointer to a SidAndAttributes object array in a TOKEN_GROUPS struct.

    .DESCRIPTION
    Converts a pointer to unmanaged memory to a managed object that represents a TOKEN_GROUPS struct.

    .PARAMETER Ptr
    The IntPtr to the unmanaged memory of the TOKEN_GROUPS struct.
    #>
    [OutputType('PSAccessToken.SidAndAttributes')]
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSUseSingularNouns", "",
        Justification="The actual object is called TOKEN_GROUPS"
    )]
    Param (
        [Parameter(Mandatory=$true)]
        [System.IntPtr]
        $Ptr
    )

    $token_groups = [System.Runtime.InteropServices.Marshal]::PtrToStructure(
        $Ptr, [Type][PSAccessToken.TOKEN_GROUPS]
    )

    # Defined struct has a static size const for Groups set to 1. We get the actual GroupCount and manually get each
    # SID_AND_ATTRIBUTES Group entry from the pointer
    # Due to packing size, the byte boundary would be the size of an IntPtr (4 on 32, 8 on 64 bit)
    $sid_ptr = [System.IntPtr]::Add($Ptr, [System.IntPtr]::Size)
    Convert-PointerToSidAndAttributes -Ptr $sid_ptr -Count $token_groups.GroupCount
}