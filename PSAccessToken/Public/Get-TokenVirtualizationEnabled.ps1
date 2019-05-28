# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-TokenVirtualizationEnabled {
    <#
    .SYNOPSIS
    Check if UAC virtualization is enabled for the token.

    .DESCRIPTION
    Check if UAC virtualization is enabled for the token. Virtualization is a feature of UAC that allows per-machine
    file and registry operations to target virtual, per-user file and registry locations than the actual per-machine
    locations.

    .PARAMETER Token
    An explicit token to use when running the scriptblock, falls back to the current thread/process if omitted.

    .PARAMETER ProcessId
    Opens the access token for the process specified, falls back to the current thread/process if omitted.

    .PARAMETER ThreadId
    Opens the thread token for the thread specified, falls back to the current thread/process if omitted.

    .PARAMETER UseProcessToken
    Use the primary process token even if the thread is impersonating another account.

    .OUTPUTS
    [System.Boolean] Whether virtualization is enabled for the token.

    .EXAMPLE Gets the virtualization enabled status for the current process
    Get-TokenVirtualizationAllowed

    .EXAMPLE Gets the virtualization enabled status for the process with the id 1234
    Get-TokenVirtualizationAllowed -ProcessId 1234

    .EXAMPLE Gets the virtualization enabled status for an existing token handle
    $h_process = Get-ProcessHandle -ProcessId 1234
    try {
        $h_token = Open-ProcessToken -Process $h_process
        try {
            Get-TokenVirtualizationAllowed -Token $h_token
        } finally {
            $h_token.Dispose()
        }
    } finally {
        $h_process.Dispose()
    }
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
        $ThreadId
    )

    Get-TokenInformation @PSBoundParameters -TokenInfoClass ([PSAccessToken.TokenInformationClass]::VirtualizationEnabled) -Process {
        Param ([System.IntPtr]$TokenInfo, [System.UInt32]$TokenInfoLength)

        $enabled_bytes = New-Object -TypeName System.Byte[] -ArgumentList $TokenInfoLength
        [System.Runtime.InteropServices.Marshal]::Copy(
            $TokenInfo, $enabled_bytes, 0, $enabled_bytes.Length
        )
        return [System.BitConverter]::ToBoolean($enabled_bytes, 0)
    }
}