# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-TokenStatistics {
    <#
    .SYNOPSIS
    Get the statistics of the access token.

    .DESCRIPTION
    Gets the TokenStatistics info class of an access token which contains various statistics about the access token.

    .PARAMETER Token
    An explicit token to use when running the scriptblock, falls back to the current thread/process if omitted.

    .PARAMETER ProcessId
    Opens the access token for the process specified, falls back to the current thread/process if omitted.

    .PARAMETER ThreadId
    Opens the thread token for the thread specified, falls back to the current thread/process if omitted.

    .PARAMETER UseProcessToken
    Use the primary process token even if the thread is impersonating another account.

    .OUTPUTS
    [PSAccessToken.TokenStatistics]
        TokenId - LUID the identifies the access token.
        AuthenticationId: The LSA Logon ID that represents the locally unique identifier of the logon session.
        ExpirationTime - When the token expires (this is not currently supported by Windows)
        ImpersonationLevel - Whether the token is a primary or impersonation token, and the type of impersonation used.
        DynamicCharged - The number of bytes in memory for storing the default protection and primary group id.
        DynamicAvailable - The number of bytes free in the dynamic array above.
        GroupCount - The number of groups in the token.
        PrivilegeCount - The number of privileges in the token.
        ModifiedId - A LUID that changes every time the token is modified.

    .EXAMPLE Gets the statistics for the current process
    Get-TokenStatistics

    .EXAMPLE Gets the statistics for the process with the id 1234
    Get-TokenStatistics -ProcessId 1234

    .EXAMPLE Gets the statistics for an existing token handle
    $h_process = Get-ProcessHandle -ProcessId 1234
    try {
        $h_token = Open-ProcessToken -Process $h_process
        try {
            Get-TokenStatistics -Token $h_token
        } finally {
            $h_token.Dispose()
        }
    } finally {
        $h_process.Dispose()
    }
    #>
    [OutputType('PSAccessToken.TokenStatistics')]
    [CmdletBinding(DefaultParameterSetName="Token")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSUseSingularNouns", "",
        Justification="The actual object is called TOKEN_STATISTICS"
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

    Get-TokenInformation @PSBoundParameters -TokenInfoClass ([PSAccessToken.TokenInformationClass]::Statistics) -Process {
        Param ([System.IntPtr]$TokenInfo, [System.UInt32]$TokenInfoLength)

        $token_statistics = [System.Runtime.InteropServices.Marshal]::PtrToStructure(
            $TokenInfo, [Type][PSAccessToken.TOKEN_STATISTICS]
        )

        $imp_level = Get-ImpersonationLevel -TokenType $token_statistics.TokenType -SecurityImpersonationLevel $token_statistics.ImpersonationLevel
        [PSCustomObject]@{
            PSTypeName = 'PSAccessToken.TokenStatistics'
            TokenId = $token_statistics.TokenId
            AuthenticationId = $token_statistics.AuthenticationId
            ExpirationTime = $token_statistics.ExpirationTime
            ImpersonationLevel = $imp_level
            DynamicCharged = $token_statistics.DynamicCharged
            DynamicAvailable = $token_statistics.DynamicAvailable
            GroupCount = $token_statistics.GroupCount
            PrivilegeCount = $token_statistics.PrivilegeCount
            ModifiedId = $token_statistics.ModifiedId
        }
    }
}