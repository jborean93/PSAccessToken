# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-TokenLogonSid {
    <#
    .SYNOPSIS
    Get the Logon SID of the access token.

    .DESCRIPTION
    Gets the Logon SID of the access token that is used to uniquely identify the logon session on the current host.

    .PARAMETER Token
    An explicit token to use when running the scriptblock, falls back to the current thread/process if omitted.

    .PARAMETER ProcessId
    Opens the access token for the process specified, falls back to the current thread/process if omitted.

    .PARAMETER ThreadId
    Opens the thread token for the thread specified, falls back to the current thread/process if omitted.

    .PARAMETER UseProcessToken
    Use the primary process token even if the thread is impersonating another account.

    .OUTPUTS
    [PSAccessToken.TokenLogonSid]
        Account - The human name of the Sid.
        Sid - The SecurityIdentifier of the logon SID level.
        Attributes - Further attributes of the logon SID group.

    .EXAMPLE Gets the logon SID for the current process
    Get-TokenLogonSid

    .EXAMPLE Gets the logon SID for the process with the id 1234
    Get-TokenLogonSid -ProcessId 1234

    .EXAMPLE Gets the logon SID for an existing token handle
    $h_process = Get-ProcessHandle -ProcessId 1234
    try {
        $h_token = Open-ProcessToken -Process $h_process
        try {
            Get-TokenLogonSid -Token $h_token
        } finally {
            $h_token.Dispose()
        }
    } finally {
        $h_process.Dispose()
    }

    .NOTES
    This is not the same as the Logon ID (or Authentication ID) that is LSA logon session identifier.
    #>
    [OutputType('PSAccessToken.TokenLogonSid')]
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

    Get-TokenInformation @PSBoundParameters -TokenInfoClass ([PSAccessToken.TokenInformationClass]::LogonSid) -Process {
        Param ([System.IntPtr]$TokenInfo, [System.UInt32]$TokenInfoLength)

        $token_groups = Convert-PointerToTokenGroups -Ptr $TokenInfo
        [PSCustomObject]@{
            PSTypeName = 'PSAccessToken.TokenLogonSid'
            Account = $token_groups.Account
            Sid = $token_groups.Sid
            Attributes = $token_groups.Attributes
        }
    }
}