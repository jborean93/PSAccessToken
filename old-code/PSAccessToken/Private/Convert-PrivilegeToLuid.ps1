# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Convert-PrivilegeToLuid {
    <#
    .SYNOPSIS
    Gets the LUID from a privilege name.

    .PARAMETER Name
    The privilege to convert.
    #>
    [OutputType([PSAccessToken.LUID])]
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [System.String]
        $Name
    )

    $luid = New-Object -TypeName PSAccessToken.LUID
    $res = [PSAccessToken.NativeMethods]::LookupPrivilegeValueW(
        [NullString]::Value,
        $Name,
        [Ref]$luid
    ); $err_code = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()

    if (-not $res) {
        $msg = Get-Win32ErrorMessage -ErrorCode $err_code
        throw "Failed to get LUID value for privilege '$Name': $msg"
    }

    return $luid
}