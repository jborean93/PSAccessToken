# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Copy-SidToSidAndAttributesPtr {
    Param (
        [Parameter(Mandatory=$true)]
        [System.IntPtr]
        $Ptr,

        [Parameter(Mandatory=$true)]
        [AllowEmptyCollection()]
        [AllowNull()]
        [System.Security.Principal.SecurityIdentifier[]]
        $Sids
    )

    if ($null -eq $Sids -or $Sids.Length -eq 0) {
        return
    }

    $sid_and_attribute_size = [System.Runtime.InteropServices.Marshal]::SizeOf(
        [Type][PSAccessToken.SID_AND_ATTRIBUTES]
    )
    $sid_ptr = [System.IntPtr]::Add($Ptr, $sid_and_attribute_size * $Sids.Length)

    foreach ($sid in $Sids) {
        # First copy the SID bytes representation onto the end of the Ptr
        $sid_bytes = New-Object -TypeName System.Byte[] -ArgumentList $sid.BinaryLength
        $sid.GetBinaryForm($sid_bytes, 0)
        [System.Runtime.InteropServices.Marshal]::Copy($sid_bytes, 0, $sid_ptr, $sid_bytes.Length)

        # Create the SID_AND_ATTRIBUTES struct which points to the SID above
        $sid_and_attributes = New-Object -TypeName PSAccessToken.SID_AND_ATTRIBUTES
        $sid_and_attributes.Sid = $sid_ptr
        $Ptr = Copy-StructureToPointer -Ptr $Ptr -Structure $sid_and_attributes

        # Move the pointer location along for the next entry
        $sid_ptr = [System.IntPtr]::Add($sid_ptr, $sid.BinaryLength)
    }
}