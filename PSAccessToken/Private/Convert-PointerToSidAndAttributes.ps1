# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Convert-PointerToSidAndAttributes {
    <#
    .SYNOPSIS
    Converts a pointer to SidAndAttributes object.

    .DESCRIPTION
    Converts a pointer to unmanaged memory to a managed object that represents an array of SID_AND_ATTRIBUTES struct.

    .PARAMETER Ptr
    The IntPtr to the unmanaged memory of the SID_AND_ATTRIBUTES array.

    .PARAMETER Count
    The number of SID_AND_ATTRIBUTES entries in the unmanaged array.
    #>
    [OutputType('PSAccessToken.SidAndAttributes')]
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSUseSingularNouns", "",
        Justification="The actual object is called SID_AND_ATTRIBUTES"
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
        $sid_and_attributes = [System.Runtime.InteropServices.Marshal]::PtrToStructure(
            $Ptr, [Type][PSAccessToken.SID_AND_ATTRIBUTES]
        )

        $sid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList $sid_and_attributes.Sid
        [PSCustomObject]@{
            PSTypeName = 'PSAccessToken.SidAndAttributes'
            Account = ConvertFrom-SecurityIdentifier -Sid $sid -ErrorBehaviour Empty
            Sid = $sid
            Attributes = $sid_and_attributes.Attributes
        }

        # Increment the ptr so we get the next SID_AND_ATTRIBUTES entry
        $Ptr = [System.IntPtr]::Add($Ptr, [System.Runtime.InteropServices.Marshal]::SizeOf($sid_and_attributes))
    }
}