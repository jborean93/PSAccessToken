# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-ThreadHandle {
    <#
    .SYNOPSIS
    Gets a handle on the thread specified.

    .PARAMETER ThreadId
    The thread id of the thread to get the handle for. Omit this parameter to open a handle of the current thread.

    .PARAMETER Access
    The desired access level for the thread object. If ThreadId is not set then this is always set to AllAccess.

    .OUTPUTS
    The safe native handle for the thread specified.

    .EXAMPLE
    Get-ThreadHandle

    Get-ThreadHandle -ThreadId 666

    .NOTES
    The handle should be closed when not needed by calling the .Dispose() method.
    #>
    [OutputType([PInvokeHelper.SafeNativeHandle])]
    [CmdletBinding()]
    Param (
        [System.UInt32]
        $ThreadId,

        [PSAccessToken.ThreadAccessFlags]
        $Access = [PSAccessToken.ThreadAccessFlags]::QueryInformation
    )

    # We need to know whether ThreadId was actually passed in or not
    if ($PSBoundParameters.ContainsKey('ThreadId')) {
        $h_thread = [PSAccessToken.NativeMethods]::OpenThread(
            $Access,
            $false,
            $ThreadId
        ); $err_code = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()

        if ($h_thread.IsInvalid) {
            $msg = Get-Win32ErrorMessage -ErrorCode $err_code
            Write-Error -Message "Failed to open thread '$ThreadId': $msg"
            return
        }
    } else {
        $h_thread = [PSAccessToken.NativeMethods]::GetCurrentThread()
    }

    return $h_thread
}