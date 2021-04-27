# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Copy-SidToPointer {
    Param (
        [Parameter(Mandatory=$true)]
        [System.IntPtr]
        $Ptr,

        [Parameter(Mandatory=$true)]
        [System.Security.Principal.SecurityIdentifier]
        $Sid
    )

    $sid_bytes = New-Object -TypeName System.Byte[] -ArgumentList $Sid.BinaryLength
    $Sid.GetBinaryForm($sid_bytes, 0)
    [System.Runtime.InteropServices.Marshal]::Copy($sid_bytes, 0, $Ptr, $sid_bytes.Length)

    return [System.IntPtr]::Add($Ptr, $sid_bytes.Length)
}