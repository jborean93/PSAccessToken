# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-TokenAppContainerNumber {
    <#
    .SYNOPSIS
    Gets the AppContainer number for the AppContainer associated with the access token.

    .DESCRIPTION
    Gets the AppContainer number for the AppContainer associated with the access token. For tokens without an
    AppContainer association, the value is 0.

    .PARAMETER Token
    An explicit token to use when running the scriptblock, falls back to the current thread/process if omitted.

    .PARAMETER ProcessId
    Opens the access token for the process specified, falls back to the current thread/process if omitted.

    .PARAMETER ThreadId
    Opens the thread token for the thread specified, falls back to the current thread/process if omitted.

    .OUTPUTS
    [System.UInt32] The AppContainer number of the access token.

    .EXAMPLE Gets the AppContainer number for the current process
    Get-TokenAppContainerNumber

    .EXAMPLE Gets the AppContainer number for the process with the id 1234
    Get-TokenAppContainerNumber -ProcessId 1234

    .EXAMPLE Gets the AppContainer number for an existing token handle
    $h_process = Get-ProcessHandle -ProcessId 1234
    try {
        $h_token = Open-ProcessToken -Process $h_process -Access QuerySource
        try {
            Get-TokenAppContainerNumber -Token $h_token
        } finally {
            $h_token.Dispose()
        }
    } finally {
        $h_process.Dispose()
    }
    #>
    [OutputType([System.UInt32])]
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
        $ThreadId
    )

    Get-TokenInformation @PSBoundParameters -TokenInfoClass ([PSAccessToken.TokenInformationClass]::AppContainerNumber) -Process {
        Param ([System.IntPtr]$TokenInfo, [System.UInt32]$TokenInfoLength)

        Convert-PointerToUInt32 -Ptr $TokenInfo
    }
}