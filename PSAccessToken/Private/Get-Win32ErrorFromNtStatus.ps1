# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-Win32ErrorFromNtStatus {
    [OutputType([System.String])]
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [System.UInt32]
        $ErrorCode
    )

    $win32_code = [PSAccessToken.NativeMethods]::RtlNtStatusToDosError($ErrorCode)
    if ($win32_code -eq 0x0000013D) {  # ERROR_MR_MID_NOT_FOUND (No valid mapping)3
        ("Unknown NtStatus Error (ErrorCode {0} - 0x{0:X8})" -f $ErrorCode)
    } else {
        Get-Win32ErrorMessage -ErrorCode $win32_code
    }
}