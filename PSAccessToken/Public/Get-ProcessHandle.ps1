# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-ProcessHandle {
    <#
    .SYNOPSIS
    Gets a handle on the process specified.

    .PARAMETER ProcessId
    The process id of the process to get the handle for. Omit this parameter to open a handle of the current process.

    .PARAMETER Access
    The desired access level for the process object. If ProcessId is not set then this is always set to AllAccess.

    .OUTPUTS
    The safe native handle for the process specified.

    .EXAMPLE
    Get-ProcessHandle

    Get-ProcessHandle -ProcessId 666

    .NOTES
    The handle should be closed when not needed by calling the .Dispose() method.
    #>
    [OutputType([PInvokeHelper.SafeNativeHandle])]
    [CmdletBinding()]
    Param (
        [System.UInt32]
        $ProcessId,

        [PSAccessToken.ProcessAccessFlags]
        $Access = [PSAccessToken.ProcessAccessFlags]::QueryInformation
    )

    # We need to know whether ProcessId was actually passed in or not
    if ($PSBoundParameters.ContainsKey('ProcessId')) {
        $h_process = [PSAccessToken.NativeMethods]::OpenProcess(
            $Access,
            $false,
            $ProcessId
        ); $err_code = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()

        if ($h_process.IsInvalid) {
            $msg = Get-Win32ErrorMessage -ErrorCode $err_code
            Write-Error -Message "Failed to open process '$ProcessId': $msg"
            return
        }
    } else {
        $h_process = [PSAccessToken.NativeMethods]::GetCurrentProcess()
    }

    return $h_process
}