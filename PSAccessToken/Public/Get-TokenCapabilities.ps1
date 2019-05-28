# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-TokenCapabilities {
    <#
    .SYNOPSIS
    Get the capabilities associated with the token.

    .DESCRIPTION
    Get the capabilities associated with the token.

    .PARAMETER Token
    An explicit token to use when running the scriptblock, falls back to the current thread/process if omitted.

    .PARAMETER ProcessId
    Opens the access token for the process specified, falls back to the current thread/process if omitted.

    .PARAMETER ThreadId
    Opens the thread token for the thread specified, falls back to the current thread/process if omitted.

    .PARAMETER UseProcessToken
    Use the primary process token even if the thread is impersonating another account.

    .OUTPUTS
    [PSAccessToken.SidAndAttributes]
        Account - The NTAccount representation of the Sid.
        Sid - The security identifier of the capability.
        Attributes - Attributes of the capability referenced by the Sid.

    .EXAMPLE Gets the capabilities for the current process
    Get-TokenCapabilities

    .EXAMPLE Gets the capabilities for the process with the id 1234
    Get-TokenCapabilities -ProcessId 1234

    .EXAMPLE Gets the capabilities for an existing token handle
    $h_process = Get-ProcessHandle -ProcessId 1234
    try {
        $h_token = Open-ProcessToken -Process $h_process
        try {
            Get-TokenCapabilities -Token $h_token
        } finally {
            $h_token.Dispose()
        }
    } finally {
        $h_process.Dispose()
    }
    #>
    [OutputType('PSAccessToken.SidAndAttributes')]
    [CmdletBinding(DefaultParameterSetName="Token")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSUseSingularNouns", "",
        Justification="The actual TokenInfoClass is called TokenCapabilities"
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

    Get-TokenInformation @PSBoundParameters -TokenInfoClass ([PSAccessToken.TokenInformationClass]::Capabilities) -Process {
        Param ([System.IntPtr]$TokenInfo, [System.UInt32]$TokenInfoLength)

        Convert-PointerToTokenGroups -Ptr $TokenInfo
    }
}