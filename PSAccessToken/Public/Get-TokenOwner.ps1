# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-TokenOwner {
    <#
    .SYNOPSIS
    Get the owner of the access token.

    .DESCRIPTION
    Gets the owner of an access token, this is the default SID applied to the owner entry on a newly created object.

    .PARAMETER Token
    An explicit token to use when running the scriptblock, falls back to the current thread/process if omitted.

    .PARAMETER ProcessId
    Opens the access token for the process specified, falls back to the current thread/process if omitted.

    .PARAMETER ThreadId
    Opens the thread token for the thread specified, falls back to the current thread/process if omitted.

    .OUTPUTS
    The NTAccount of the owner of the access token.

    .EXAMPLE Gets the owner for the current process
    Get-TokenOwner

    .EXAMPLE Gets the owner for the process with the id 1234
    Get-TokenOwner -ProcessId 1234

    .EXAMPLE Gets the owner for an existing token handle
    $h_process = Get-ProcessHandle -ProcessId 1234
    try {
        $h_token = Open-ProcessToken -Process $h_process
        try {
            Get-TokenOwner -Token $h_token
        } finally {
            $h_token.Dispose()
        }
    } finally {
        $h_process.Dispose()
    }
    #>
    [OutputType([System.Security.Principal.NTAccount])]
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

    Get-TokenInformation @PSBoundParameters -TokenInfoClass ([PSAccessToken.TokenInformationClass]::Owner) -Process {
        Param ([System.IntPtr]$TokenInfo, [System.UInt32]$TokenInfoLength)

        $token_owner = [System.Runtime.InteropServices.Marshal]::PtrToStructure(
            $TokenInfo, [Type][PSAccessToken.TOKEN_OWNER]
        )
        $sid = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList $token_owner.Owner
        ConvertFrom-SecurityIdentifier -Sid $sid -ErrorBehaviour PassThru
    }
}