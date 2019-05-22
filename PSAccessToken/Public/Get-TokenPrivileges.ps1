# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-TokenPrivileges {
    <#
    .SYNOPSIS
    Get the privileges of the access token.

    .DESCRIPTION
    Gets the TokenPrivileges info class of an access token which contains a list of privileges and attributes that are
    assigned to the token.

    .PARAMETER Token
    An explicit token to use when running the scriptblock, falls back to the current thread/process if omitted.

    .PARAMETER ProcessId
    Opens the access token for the process specified, falls back to the current thread/process if omitted.

    .PARAMETER ThreadId
    Opens the thread token for the thread specified, falls back to the current thread/process if omitted.

    .OUTPUTS
    [PSAccessToken.PrivilegeAndAttributes]
        Name - The name of the privileges
        Attributes - Attributes of the privileges referenced by the Name

    .EXAMPLE Gets the privileges for the current process
    Get-TokenPrivileges

    .EXAMPLE Gets the privileges for the process with the id 1234
    Get-TokenPrivileges -ProcessId 1234

    .EXAMPLE Gets the privileges for an existing token handle
    $h_process = Get-ProcessHandle -ProcessId 1234
    try {
        $h_token = Open-ProcessToken -Process $h_process
        try {
            Get-TokenPrivileges -Token $h_token
        } finally {
            $h_token.Dispose()
        }
    } finally {
        $h_process.Dispose()
    }
    #>
    [OutputType('PSAccessToken.PrivilegeAndAttributes')]
    [CmdletBinding(DefaultParameterSetName="Token")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSUseSingularNouns", "",
        Justification="The actual object is called TOKEN_PRIVILEGES"
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
        $ThreadId
    )

    Get-TokenInformation @PSBoundParameters -TokenInfoClass ([PSAccessToken.TokenInformationClass]::Privileges) -Process {
        Param ([System.IntPtr]$TokenInfo, [System.UInt32]$TokenInfoLength)

        Convert-PointerToTokenPrivileges -Ptr $TokenInfo
    }
}