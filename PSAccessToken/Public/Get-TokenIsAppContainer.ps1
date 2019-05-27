# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-TokenIsAppContainer {
    <#
    .SYNOPSIS
    Check if current token is an app container token.

    .DESCRIPTION
    Check if current token is an app container token. Any callers who check the TokenIsAppContainer value and have
    it return $false should also verify that the caller token is not an Identity level impersonation level. If that is
    the case, it should return AccessDenied.

    .PARAMETER Token
    An explicit token to use when running the scriptblock, falls back to the current thread/process if omitted.

    .PARAMETER ProcessId
    Opens the access token for the process specified, falls back to the current thread/process if omitted.

    .PARAMETER ThreadId
    Opens the thread token for the thread specified, falls back to the current thread/process if omitted.

    .OUTPUTS
    [System.Boolean] Whether the token is an app container token.

    .EXAMPLE Gets the IsAppContainer status for the current process
    Get-TokenIsAppContainer

    .EXAMPLE Gets the IsAppContainer status for the process with the id 1234
    Get-TokenIsAppContainer -ProcessId 1234

    .EXAMPLE Gets the IsAppContainer status for an existing token handle
    $h_process = Get-ProcessHandle -ProcessId 1234
    try {
        $h_token = Open-ProcessToken -Process $h_process
        try {
            Get-TokenIsAppContainer -Token $h_token
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
        $ThreadId
    )

    Get-TokenInformation @PSBoundParameters -TokenInfoClass ([PSAccessToken.TokenInformationClass]::IsAppContainer) -Process {
        Param ([System.IntPtr]$TokenInfo, [System.UInt32]$TokenInfoLength)

        $is_container = New-Object -TypeName System.Byte[] -ArgumentList $TokenInfoLength
        [System.Runtime.InteropServices.Marshal]::Copy(
            $TokenInfo, $is_container, 0, $is_container.Length
        )
        return [System.BitConverter]::ToBoolean($is_container, 0)
    }
}