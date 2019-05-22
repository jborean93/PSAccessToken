# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Open-ThreadToken {
    <#
    .SYNOPSIS
    Opens the access token associated with a thread handle.

    .PARAMETER Thread
    The handle to the thread to retrieve the access token for. If omitted then the current thread is used.

    .PARAMETER Access
    The level of access to the thread token.

    .PARAMETER OpenAsSelf
    The Access check is made against the current process-level security context instead of the current thread-level
    security context. This is required when impersonating an Identification level access token as Identification level
    tokens cannot open executive-level objects.

    .EXAMPLE
    $h_token = Open-ThreadToken
    $h_token.Dispose()

    .NOTES
    The token should be closed by calling the .Dispose() method when finished. This cmdlet will error if the thread is
    not currently impersonating any token. Use Open-ProcessToken instead to open the access token associated with the
    process.
    #>
    [OutputType([PInvokeHelper.SafeNativeHandle])]
    [CmdletBinding()]
    Param (
        [System.IntPtr]
        $Thread,

        [System.Security.Principal.TokenAccessLevels]
        $Access = [System.Security.Principal.TokenAccessLevels]::Query,

        [Switch]
        $OpenAsSelf
    )

    if ($null -eq $Thread) {
        $Thread = Get-ThreadHandle
    }

    $h_token = New-Object -TypeName PInvokeHelper.SafeNativeHandle
    $res = [PSAccessToken.NativeMethods]::OpenThreadToken(
        $Thread,
        $Access,
        $OpenAsSelf.IsPresent,
        [Ref]$h_token
    ); $err_code = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()

    if (-not $res) {
        $msg = Get-Win32ErrorMessage -ErrorCode $err_code
        Write-Error -Message "Failed to open thread token: $msg"
        return
    }

    return $h_token
}