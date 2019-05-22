# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Open-ProcessToken {
    <#
    .SYNOPSIS
    Opens the access token associated with a process handle.

    .PARAMETER Process
    The handle to the process to retrieve the access token for. If omitted then the current process is used.

    .PARAMETER Access
    The level of access to the process token.

    .EXAMPLE
    $h_token = Open-ProcessToken
    $h_token.Dispose()

    .NOTES
    The token should be closed by calling the .Dispose() method when finished.
    #>
    [OutputType([PInvokeHelper.SafeNativeHandle])]
    [CmdletBinding()]
    Param (
        [System.IntPtr]
        $Process,

        [System.Security.Principal.TokenAccessLevels]
        $Access = [System.Security.Principal.TokenAccessLevels]::Query
    )

    if ($null -eq $Process) {
        $Process = Get-ProcessHandle
    }

    $h_token = New-Object -TypeName PInvokeHelper.SafeNativeHandle
    $res = [PSAccessToken.NativeMethods]::OpenProcessToken(
        $Process,
        $Access,
        [Ref]$h_token
    ); $err_code = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()

    if (-not $res) {
        $msg = Get-Win32ErrorMessage -ErrorCode $err_code
        Write-Error -Message "Failed to open process token: $msg"
        return
    }

    return $h_token
}