# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-Win32ErrorFromLsaStatus {
    <#
    .SYNOPSIS
    Get the Win32 error message from an LSA NtStatus code.

    .PARAMETER ErrorCode
    The LSA NtStatus code.
    #>
    [OutputType([System.String])]
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [System.UInt32]
        $ErrorCode
    )

    $win32_code = [PSAccessToken.NativeMethods]::LsaNtStatusToWinError($ErrorCode)
    if ($win32_code -eq 0x0000013D) {  # ERROR_MR_MID_NOT_FOUND (No valid mapping)
        ("Unknown LsaNtStatus Error (ErrorCode {0} - 0x{0:X8})" -f $ErrorCode)
    } else {
        Get-Win32ErrorMessage -ErrorCode $win32_code
    }
}