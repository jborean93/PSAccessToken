# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-TokenSandboxInert {
    <#
    .SYNOPSIS
    Get the SandboxInert flag of the access token.

    .DESCRIPTION
    Gets the SandboxInert flags of an access token. This is set when using the New-RestrictedToken with the
    -SandboxInert switch.

    .PARAMETER Token
    An explicit token to use when running the scriptblock, falls back to the current thread/process if omitted.

    .PARAMETER ProcessId
    Opens the access token for the process specified, falls back to the current thread/process if omitted.

    .PARAMETER ThreadId
    Opens the thread token for the thread specified, falls back to the current thread/process if omitted.

    .PARAMETER UseProcessToken
    Use the primary process token even if the thread is impersonating another account.

    .OUTPUTS
    [System.Boolean] Whether the flag is set or not.

    .EXAMPLE Gets the sandbox inert flag for the current process
    Get-TokenSandboxInert

    .EXAMPLE Gets the sandbox inert flag for the process with the id 1234
    Get-TokenSandboxInert -ProcessId 1234

    .EXAMPLE Gets the sandbox inert flag for an existing token handle
    $h_process = Get-ProcessHandle -ProcessId 1234
    try {
        $h_token = Open-ProcessToken -Process $h_process
        try {
            Get-TokenSandboxInert -Token $h_token
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
        $ThreadId,

        [Parameter(ParameterSetName="ProcessToken")]
        [Switch]
        $UseProcessToken
    )

    Get-TokenInformation @PSBoundParameters -TokenInfoClass ([PSAccessToken.TokenInformationClass]::SandBoxInert) -Process {
        Param ([System.IntPtr]$TokenInfo, [System.UInt32]$TokenInfoLength)

        $sandbox_inert_bytes = New-Object -TypeName System.Byte[] -ArgumentList $TokenInfoLength
        [System.Runtime.InteropServices.Marshal]::Copy(
            $TokenInfo, $sandbox_inert_bytes, 0, $sandbox_inert_bytes.Length
        )
        return [System.BitConverter]::ToBoolean($sandbox_inert_bytes, 0)
    }
}