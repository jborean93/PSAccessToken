# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-TokenRestrictedSids {
    <#
    .SYNOPSIS
    Get the restricted SIDs of the access token.

    .DESCRIPTION
    Gets the TokenRestrictedSids info class of an access token which contains a list of restricted groups and
    attributes that are assigned to the token.

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
        Sid - The security identifier of the group that is restricted.
        Attributes - Attributes of the group referenced by the Sid.

    .EXAMPLE Gets the restricted sids for the current process
    Get-TokenRestrictedSids

    .EXAMPLE Gets the restricted sids for the process with the id 1234
    Get-TokenRestrictedSids -ProcessId 1234

    .EXAMPLE Gets the restricted sids for an existing token handle
    $h_process = Get-ProcessHandle -ProcessId 1234
    try {
        $h_token = Open-ProcessToken -Process $h_process
        try {
            Get-TokenRestrictedSids -Token $h_token
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
        Justification="The actual object is called TOKEN_GROUPS"
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

    Get-TokenInformation @PSBoundParameters -TokenInfoClass ([PSAccessToken.TokenInformationClass]::RestrictedSids) -Process {
        Param ([System.IntPtr]$TokenInfo, [System.UInt32]$TokenInfoLength)

        Convert-PointerToTokenGroups -Ptr $TokenInfo
    }
}