# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-TokenOrigin {
    <#
    .SYNOPSIS
    Gets the logon ID of the logon that created the access token.

    .DESCRIPTION
    Gets the logon ID of the logon session that created it. This will only return a logon ID of access tokens that
    have been created with explicit credentials and are not a network logon.

    .PARAMETER Token
    An explicit token to use when running the scriptblock, falls back to the current thread/process if omitted.

    .PARAMETER ProcessId
    Opens the access token for the process specified, falls back to the current thread/process if omitted.

    .PARAMETER ThreadId
    Opens the thread token for the thread specified, falls back to the current thread/process if omitted.

    .OUTPUTS
    The SecurityIdentifier of the originating logon ID.

    .EXAMPLE Gets the origin for the current process
    Get-TokenOrigin

    .EXAMPLE Gets the origin for the process with the id 1234
    Get-TokenOrigin -ProcessId 1234

    .EXAMPLE Gets the origin for an existing token handle
    $h_process = Get-ProcessHandle -ProcessId 1234
    try {
        $h_token = Open-ProcessToken -Process $h_process
        try {
            Get-TokenOrigin -Token $h_token
        } finally {
            $h_token.Dispose()
        }
    } finally {
        $h_process.Dispose()
    }
    #>
    [OutputType([System.Security.Principal.SecurityIdentifier])]
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

    Get-TokenInformation @PSBoundParameters -TokenInfoClass ([PSAccessToken.TokenInformationClass]::Origin) -Process {
        Param ([System.IntPtr]$TokenInfo, [System.UInt32]$TokenInfoLength)

        $token_origin = [System.Runtime.InteropServices.Marshal]::PtrToStructure(
            $TokenInfo, [Type][PSAccessToken.TOKEN_ORIGIN]
        )
        $origin_id_sid = "S-1-5-5-$($token_origin.OriginatingLogonSession.HighPart)-$($token_origin.OriginatingLogonSession.LowPart)"
        New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList $origin_id_sid
    }
}