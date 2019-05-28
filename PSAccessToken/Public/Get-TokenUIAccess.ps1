# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-TokenUIAccess {
    <#
    .SYNOPSIS
    Check if the access token has the UIAccess flag set.

    .DESCRIPTION
    Check if the access token has the UIAccess flag set.

    .PARAMETER Token
    An explicit token to use when running the scriptblock, falls back to the current thread/process if omitted.

    .PARAMETER ProcessId
    Opens the access token for the process specified, falls back to the current thread/process if omitted.

    .PARAMETER ThreadId
    Opens the thread token for the thread specified, falls back to the current thread/process if omitted.

    .PARAMETER UseProcessToken
    Use the primary process token even if the thread is impersonating another account.

    .OUTPUTS
    [System.Boolean] Whether the token is elevated or not.

    .EXAMPLE Gets the UIAccess status for the current process
    Get-TokenUIAccess

    .EXAMPLE Gets the UIAccess status for the process with the id 1234
    Get-TokenUIAccess -ProcessId 1234

    .EXAMPLE Gets the UIAccess status for an existing token handle
    $h_process = Get-ProcessHandle -ProcessId 1234
    try {
        $h_token = Open-ProcessToken -Process $h_process
        try {
            Get-TokenUIAccess -Token $h_token
        } finally {
            $h_token.Dispose()
        }
    } finally {
        $h_process.Dispose()
    }

    .NOTES
    UIAccess is a flag that allows a token to bypass the User Interface Privilege Isolation (UIPI) restrictions when
    an application is elevated from a standard user to an administrator. When set, the token can interchange
    information with applications that are running at a higher privilege level, such as logon prompts and UAC prompts.
    #>
    [OutputType([System.Boolean])]
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

    Get-TokenInformation @PSBoundParameters -TokenInfoClass ([PSAccessToken.TokenInformationClass]::UIAccess) -Process {
        Param ([System.IntPtr]$TokenInfo, [System.UInt32]$TokenInfoLength)

        $ui_access = New-Object -TypeName byte[] -ArgumentList $TokenInfoLength
        [System.Runtime.InteropServices.Marshal]::Copy($TokenInfo, $ui_access, 0, $ui_access.Length)
        [System.BitConverter]::ToBoolean($ui_access, 0)
    }
}