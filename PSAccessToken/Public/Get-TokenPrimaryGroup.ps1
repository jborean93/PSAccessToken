# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-TokenPrimaryGroup {
    <#
    .SYNOPSIS
    Get the primary group of the access token.

    .DESCRIPTION
    Gets the primary gorup of an access token, this is the default SID applied to the group entry on a newly created
    object.

    .PARAMETER Token
    An explicit token to use when running the scriptblock, falls back to the current thread/process if omitted.

    .PARAMETER ProcessId
    Opens the access token for the process specified, falls back to the current thread/process if omitted.

    .PARAMETER ThreadId
    Opens the thread token for the thread specified, falls back to the current thread/process if omitted.

    .PARAMETER UseProcessToken
    Use the primary process token even if the thread is impersonating another account.

    .OUTPUTS
    The NTAccount of the primary group of the access token.

    .EXAMPLE Gets the primary group for the current process
    Get-TokenPrimaryGroup

    .EXAMPLE Gets the primary group for the process with the id 1234
    Get-TokenPrimaryGroup -ProcessId 1234

    .EXAMPLE Gets the primary group for an existing token handle
    $h_process = Get-ProcessHandle -ProcessId 1234
    try {
        $h_token = Open-ProcessToken -Process $h_process
        try {
            Get-TokenPrimaryGroup -Token $h_token
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
        $ThreadId,

        [Parameter(ParameterSetName="ProcessToken")]
        [Switch]
        $UseProcessToken
    )

    Get-TokenInformation @PSBoundParameters -TokenInfoClass ([PSAccessToken.TokenInformationClass]::PrimaryGroup) -Process {
        Param ([System.IntPtr]$TokenInfo, [System.UInt32]$TokenInfoLength)

        $token_group = [System.Runtime.InteropServices.Marshal]::PtrToStructure(
            $TokenInfo, [Type][PSAccessToken.TOKEN_PRIMARY_GROUP]
        )
        $sid = ConvertTo-SecurityIdentifier -InputObject $token_group.PrimaryGroup
        ConvertFrom-SecurityIdentifier -Sid $sid -ErrorBehaviour PassThru
    }
}