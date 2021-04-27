# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Add-WindowsRight {
    <#
    .SYNOPSIS
    Add a right to the specified account.

    .PARAMETER LsaHandle
    An opened handle to LSA.

    .PARAMETER SidBytes
    The bytes of the SID to add the right to.

    .PARAMETER Name
    The name of the right to add.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [System.IntPtr]
        $LsaHandle,

        [Parameter(Mandatory=$true)]
        [System.Byte[]]
        $SidBytes,

        [Parameter(Mandatory=$true)]
        [System.String]
        $Name
    )

    $right = New-Object -TypeName PSAccessToken.LSA_UNICODE_STRING
    $right.Length = [System.Text.Encoding]::Unicode.GetByteCount($Name)
    $right.MaximumLength = $right.Length

    try {
        $right.Buffer = [System.Runtime.InteropServices.Marshal]::StringToHGlobalUni($Name)

        $res = [PSAccessToken.NativeMethods]::LsaAddAccountRights(
            $LsaHandle,
            $SidBytes,
            @($right),
            1
        )
    } finally {
        [System.Runtime.InteropServices.Marshal]::FreeHGlobal($right.Buffer)
    }

    if ($res -ne 0) {
        $msg = Get-Win32ErrorFromLsaStatus -ErrorCode $res
        throw "Failed to add the '$Name' right: $msg"
    }
}