# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-TokenAppContainerSid {
    <#
    .SYNOPSIS
    Get the SID of the AppContainer associated with the access token.

    .DESCRIPTION
    Get the SID of the AppContainer associated with the access token. If not AppContainer is associated, this will
    return $null.

    .PARAMETER Token
    An explicit token to use when running the scriptblock, falls back to the current thread/process if omitted.

    .PARAMETER ProcessId
    Opens the access token for the process specified, falls back to the current thread/process if omitted.

    .PARAMETER ThreadId
    Opens the thread token for the thread specified, falls back to the current thread/process if omitted.

    .OUTPUTS
    [System.Security.Principal.SecurityIdentifier] The AppContainer SID associated with the access token.

    .EXAMPLE Gets the AppContainer SID for the current process
    Get-TokenAppContainerSid

    .EXAMPLE Gets the AppContainer SID for the process with the id 1234
    Get-TokenAppContainerSid -ProcessId 1234

    .EXAMPLE Gets the AppContainer SID for an existing token handle
    $h_process = Get-ProcessHandle -ProcessId 1234
    try {
        $h_token = Open-ProcessToken -Process $h_process
        try {
            Get-TokenAppContainerSid -Token $h_token
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

    Get-TokenInformation @PSBoundParameters -TokenInfoClass ([PSAccessToken.TokenInformationClass]::AppContainerSid) -Process {
        Param ([System.IntPtr]$TokenInfo, [System.UInt32]$TokenInfoLength)

        $token_app_info = [System.Runtime.InteropServices.Marshal]::PtrToStructure(
            $TokenInfo, [Type][PSAccessTOken.TOKEN_APPCONTAINER_INFORMATION]
        )
        ConvertTo-SecurityIdentifier -InputObject $token_app_info.TokenAppContainer
    }
}