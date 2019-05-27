# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-TokenLinkedToken {
    <#
    .SYNOPSIS
    Gets the linked token of access token.

    .DESCRIPTION
    Gets the linked token of an access token. When the access token is a limited token, the linked token is the full
    token for that user. The opposite is true for a full access token.

    .PARAMETER Token
    An explicit token to use when running the scriptblock, falls back to the current thread/process if omitted.

    .PARAMETER ProcessId
    Opens the access token for the process specified, falls back to the current thread/process if omitted.

    .PARAMETER ThreadId
    Opens the thread token for the thread specified, falls back to the current thread/process if omitted.

    .OUTPUTS
    [PInvokeHelper.SafeNativeHandle] The handle to the linked access token. The .Dispose() method should be called
    when this is no longer needed.

    .EXAMPLE Gets the linked token for the current process
    Get-TokenLinkedToken

    .EXAMPLE Gets the linked token for the process with the id 1234
    Get-TokenLinkedToken -ProcessId 1234

    .EXAMPLE Gets the linked token for an existing token handle
    $h_process = Get-ProcessHandle -ProcessId 1234
    try {
        $h_token = Open-ProcessToken -Process $h_process -Access QuerySource
        try {
            Get-TokenLinkedToken -Token $h_token
        } finally {
            $h_token.Dispose()
        }
    } finally {
        $h_process.Dispose()
    }

    .NOTES
    The SeTcbPrivilege privilege is required to be able to get an Impersonation token, if the privilege is not
    available, then only an Identification token is returned.
    #>
    [OutputType([PInvokeHelper.SafeNativeHandle])]
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

    Get-TokenInformation @PSBoundParameters -TokenInfoClass ([PSAccessToken.TokenInformationClass]::LinkedToken) -Process {
        Param ([System.IntPtr]$TokenInfo, [System.UInt32]$TokenInfoLength)

        $token_linked_token = [System.Runtime.InteropServices.Marshal]::PtrToStructure(
            $TokenInfo, [Type][PSAccessToken.TOKEN_LINKED_TOKEN]
        )
        New-Object -TypeName PInvokeHelper.SafeNativeHandle -ArgumentList $token_linked_token.LinkedToken
    }
}