# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Convert-PointerToTokenPrivileges {
    <#
    .SYNOPSIS
    Converts a pointer to a PrivilegeAndAttributes object array in a TOKEN_PRIVILEGES struct.

    .DESCRIPTION
    Converts a pointer to unmanaged memory to a managed object that represents a TOKEN_PRIVILEGES struct.

    .PARAMETER Ptr
    The IntPtr to the unmanaged memory of the TOKEN_PRIVILEGES struct.
    #>
    [OutputType('PSAccessToken.PrivilegeAndAttributes')]
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSUseSingularNouns", "",
        Justification="The actual object is called TOKEN_PRIVILEGES"
    )]
    Param (
        [Parameter(Mandatory=$true)]
        [System.IntPtr]
        $Ptr
    )

    $token_privileges = [System.Runtime.InteropServices.Marshal]::PtrToStructure(
        $Ptr, [Type][PSAccessToken.TOKEN_PRIVILEGES]
    )

    # Defined struct has a static size const for Groups set to 1. We get the actual PrivilegeCount and manually get
    # each LUID_AND_ATTRIBUTES Privilege entry from the pointer
    $luid_ptr = [System.IntPtr]::Add(
        $Ptr, [System.Runtime.InteropServices.Marshal]::SizeOf($token_privileges.PrivilegeCount)
    )
    Convert-PointerToPrivilegeAndAttributes -Ptr $luid_ptr -Count $token_privileges.PrivilegeCount
}