# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-TokenElevationType {
    <#
    .SYNOPSIS
    Gets the elevation type the access token.

    .DESCRIPTION
    Gets the TokenElevationType of an access token states whether the token is elevated, limited, or no filtering has
    been applied.

    .PARAMETER Token
    An explicit token to use when running the scriptblock, falls back to the current thread/process if omitted.

    .PARAMETER ProcessId
    Opens the access token for the process specified, falls back to the current thread/process if omitted.

    .PARAMETER ThreadId
    Opens the thread token for the thread specified, falls back to the current thread/process if omitted.

    .PARAMETER UseProcessToken
    Use the primary process token even if the thread is impersonating another account.

    .OUTPUTS
    [PSAccessToken.TokenElevationType]
        Default - No UAC is applied to the token, either a standard user account or UAC is not applied.
        Full - An admin token with all the groups and privileges available.
        Limited - An admin token but with limited groups and privileges available.

    .EXAMPLE Gets the elevation type for the current process
    Get-TokenElevationType

    .EXAMPLE Gets the elevation type for the process with the id 1234
    Get-TokenElevationType -ProcessId 1234

    .EXAMPLE Gets the elevation type for an existing token handle
    $h_process = Get-ProcessHandle -ProcessId 1234
    try {
        $h_token = Open-ProcessToken -Process $h_process -Access QuerySource
        try {
            Get-TokenElevationType -Token $h_token
        } finally {
            $h_token.Dispose()
        }
    } finally {
        $h_process.Dispose()
    }

    .NOTES
    Having an elevation type of Default does not mean this is an admin token, a standard user account will have the
    type of Default. You can use Get-TokenLinkedToken to get the Full token from a Limited token and vice versa.
    #>
    [OutputType([PSAccessToken.TokenElevationType])]
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

    Get-TokenInformation @PSBoundParameters -TokenInfoClass ([PSAccessToken.TokenInformationClass]::ElevationType) -Process {
        Param ([System.IntPtr]$TokenInfo, [System.UInt32]$TokenInfoLength)

        [PSAccessToken.TokenElevationType](Convert-PointerToUInt32 -Ptr $TokenInfo)
    }
}