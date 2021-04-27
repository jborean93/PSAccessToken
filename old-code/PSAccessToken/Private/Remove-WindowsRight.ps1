# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Remove-WindowsRight {
    <#
    .SYNOPSIS
    Removes all rights on the account specified.

    .PARAMETER LsaHandle
    An opened handle to LSA.

    .PARAMETER SidBytes
    The bytes of the SID to remove all rights from.
    #>
    [CmdletBinding(SupportsShouldProcess=$false)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSUseShouldProcessForStateChangingFunctions", "",
        Justification="This is an internal function, not designed to be exposed publically"
    )]
    Param (
        [Parameter(Mandatory=$true)]
        [System.IntPtr]
        $LsaHandle,

        [Parameter(Mandatory=$true)]
        [System.Byte[]]
        $SidBytes
    )

    $res = [PSAccessToken.NativeMethods]::LsaRemoveAccountRights(
        $LsaHandle,
        $SidBytes,
        $true,
        $null,
        0
    )

    if ($res -ne 0) {
        $msg = Get-Win32ErrorFromLsaStatus -ErrorCode $res
        throw "Failed to remove account rights: $msg"
    }
}