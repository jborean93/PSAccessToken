# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-TokenSource {
    <#
    .SYNOPSIS
    Gets the source logon name and ID of the access token.

    .DESCRIPTION
    Gets the TokenSource info class of an access token which refers to the name of the registered logon provider and
    its unique ID that created the access token.

    .PARAMETER Token
    An explicit token to use when running the scriptblock, falls back to the current thread/process if omitted.

    .PARAMETER ProcessId
    Opens the access token for the process specified, falls back to the current thread/process if omitted.

    .PARAMETER ThreadId
    Opens the thread token for the thread specified, falls back to the current thread/process if omitted.

    .PARAMETER UseProcessToken
    Use the primary process token even if the thread is impersonating another account.

    .OUTPUTS
    [PSAccessToken.TokenSource]
        Name: The ane of the logon provider.
        Id: The LUID representing the unique ID for the logon provider.

    .EXAMPLE Gets the source for the current process
    Get-TokenSource

    .EXAMPLE Gets the source for the process with the id 1234
    Get-TokenSource -ProcessId 1234

    .EXAMPLE Gets the source for an existing token handle
    $h_process = Get-ProcessHandle -ProcessId 1234
    try {
        $h_token = Open-ProcessToken -Process $h_process -Access QuerySource
        try {
            Get-TokenSource -Token $h_token
        } finally {
            $h_token.Dispose()
        }
    } finally {
        $h_process.Dispose()
    }
    #>
    [OutputType('PSAccessToken.TokenSource')]
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

    Get-TokenInformation @PSBoundParameters -TokenInfoClass ([PSAccessToken.TokenInformationClass]::Source) -Process {
        Param ([System.IntPtr]$TokenInfo, [System.UInt32]$TokenInfoLength)

        $token_source = [System.Runtime.InteropServices.Marshal]::PtrToStructure(
            $TokenInfo,
            [Type][PSAccessToken.TOKEN_SOURCE]
        )

        [PSCustomObject]@{
            PSTypeName = 'PSAccessToken.TokenSource'
            Name = (New-Object -TypeName System.String -ArgumentList @(,$token_source.SourceName)).TrimEnd(@("`0"))
            Id = $token_source.SourceIdentifier
        }
    }
}