# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-TokenBnoIsolation {
    <#
    .SYNOPSIS
    Gets the BNO Isolation information on a token.

    .DESCRIPTION
    Get the status of BaseNameObject isolation and the prefix of the BNO if isolation is enabled.

    .PARAMETER Token
    An explicit token to use when running the scriptblock, falls back to the current thread/process if omitted.

    .PARAMETER ProcessId
    Opens the access token for the process specified, falls back to the current thread/process if omitted.

    .PARAMETER ThreadId
    Opens the thread token for the thread specified, falls back to the current thread/process if omitted.

    .OUTPUTS
    [System.Boolean] Whether there is a restricted token available or not.

    .EXAMPLE Gets the Bno Isolation for the current process
    Get-TokenBnoIsolation

    .EXAMPLE Gets the Bno Isolation for the process with the id 1234
    Get-TokenBnoIsolation -ProcessId 1234

    .EXAMPLE Gets the Bno Isolation for an existing token handle
    $h_process = Get-ProcessHandle -ProcessId 1234
    try {
        $h_token = Open-ProcessToken -Process $h_process
        try {
            Get-TokenBnoIsolation -Token $h_token
        } finally {
            $h_token.Dispose()
        }
    } finally {
        $h_process.Dispose()
    }
    #>
    [OutputType('PSAccessToken.TokenBnoIsolation')]
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

    Get-TokenInformation @PSBoundParameters -TokenInfoClass ([PSAccessToken.TokenInformationClass]::BnoIsolation) -Process {
        Param ([System.IntPtr]$TokenInfo, [System.UInt32]$TokenInfoLength)

        $bno_isolation = [System.Runtime.InteropServices.Marshal]::PtrToStructure(
            $TokenInfo, [Type][PSAccessToken.TOKEN_BNO_ISOLATION_INFORMATION]
        )
        [PSCustomObject]@{
            PSTypeName = 'PSAccessToken.TokenBnoIsolation'
            Prefix = $bno_isolation.IsolationPrefix
            Enabled = $bno_isolation.IsolationEnabled
        }
    }
}