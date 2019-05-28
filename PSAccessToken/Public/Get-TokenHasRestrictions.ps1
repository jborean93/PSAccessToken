# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-TokenHasRestrictions {
    <#
    .SYNOPSIS
    Check if the access token has restrictions applied.

    .DESCRIPTION
    Check if the access token has restrictions applied.

    .PARAMETER Token
    An explicit token to use when running the scriptblock, falls back to the current thread/process if omitted.

    .PARAMETER ProcessId
    Opens the access token for the process specified, falls back to the current thread/process if omitted.

    .PARAMETER ThreadId
    Opens the thread token for the thread specified, falls back to the current thread/process if omitted.

    .PARAMETER UseProcessToken
    Use the primary process token even if the thread is impersonating another account.

    .OUTPUTS
    [System.Boolean] Whether there is a restrictions applied to the token.

    .EXAMPLE Check if token is restricted for the current process
    Get-TokenHasRestrictions

    .EXAMPLE Check if token is restricted for the process with the id 1234
    Get-TokenHasRestrictions -ProcessId 1234

    .EXAMPLE Check if token is restricted for an existing token handle
    $h_process = Get-ProcessHandle -ProcessId 1234
    try {
        $h_token = Open-ProcessToken -Process $h_process
        try {
            Get-TokenHasRestrictions -Token $h_token
        } finally {
            $h_token.Dispose()
        }
    } finally {
        $h_process.Dispose()
    }
    #>
    [OutputType([System.Boolean])]
    [CmdletBinding(DefaultParameterSetName="Token")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSUseSingularNouns", "",
        Justification="The actual object is called TOKEN_RESTRICTIONS"
    )]
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

    Get-TokenInformation @PSBoundParameters -TokenInfoClass ([PSAccessToken.TokenInformationClass]::HasRestrictions) -Process {
        Param ([System.IntPtr]$TokenInfo, [System.UInt32]$TokenInfoLength)

        $hash_rest_bytes = New-Object -TypeName System.Byte[] -ArgumentList $TokenInfoLength
        [System.Runtime.InteropServices.Marshal]::Copy(
            $TokenInfo, $hash_rest_bytes, 0, $hash_rest_bytes.Length
        )
        return [System.BitConverter]::ToBoolean($hash_rest_bytes, 0)
    }
}