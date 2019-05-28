# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-TokenElevation {
    <#
    .SYNOPSIS
    Gets the access token elevation status.

    .DESCRIPTION
    Check if an access token is elevated or not.

    .PARAMETER Token
    An explicit token to use when running the scriptblock, falls back to the current thread/process if omitted.

    .PARAMETER ProcessId
    Opens the access token for the process specified, falls back to the current thread/process if omitted.

    .PARAMETER ThreadId
    Opens the thread token for the thread specified, falls back to the current thread/process if omitted.

    .PARAMETER UseProcessToken
    Use the primary process token even if the thread is impersonating another account.

    .OUTPUTS
    [System.Boolean] Whether the token is elevated or not.

    .EXAMPLE Gets the elevation status for the current process
    Get-TokenElevation

    .EXAMPLE Gets the elevation status for the process with the id 1234
    Get-TokenElevation -ProcessId 1234

    .EXAMPLE Gets the elevation status for an existing token handle
    $h_process = Get-ProcessHandle -ProcessId 1234
    try {
        $h_token = Open-ProcessToken -Process $h_process
        try {
            Get-TokenElevation -Token $h_token
        } finally {
            $h_token.Dispose()
        }
    } finally {
        $h_process.Dispose()
    }
    #>
    [OutputType([System.Boolean])]
    [CmdletBinding(DefaultParameterSetName="Token")]
    Param (
        [Parameter(ParameterSetName="Token")]
        [System.Runtime.InteropServices.SafeHandle]
        $Token,

        [Parameter(ParameterSetName="PID")]
        [System.UInt32]
        $ProcessId,

        [Parameter(ParameterSetName="TID")]
        [System.UInt32]
        $ThreadId,

        [Parameter(ParameterSetName="ProcessToken")]
        [Switch]
        $UseProcessToken
    )

    Get-TokenInformation @PSBoundParameters -TokenInfoClass ([PSAccessToken.TokenInformationClass]::Elevation) -Process {
        Param ([System.IntPtr]$TokenInfo, [System.UInt32]$TokenInfoLength)

        $token_elevation = [System.Runtime.InteropServices.Marshal]::PtrToStructure(
            $TokenInfo, [Type][PSAccessToken.TOKEN_ELEVATION]
        )
        return $token_elevation.TokenIsElevated
    }
}