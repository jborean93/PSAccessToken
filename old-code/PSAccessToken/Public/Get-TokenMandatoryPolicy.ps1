# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-TokenMandatoryPolicy {
    <#
    .SYNOPSIS
    Gets the mandatory policy applied to the access token.

    .DESCRIPTION
    Gets the TokenMandatoryPolicy of an access token that controls the access checks for the token integrity label and
    actions it can perform on a securable object.
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
    [PSAccessToken.TokenMandatoryPolicy]
        Off - No policy is enforced for the token.
        NoWriteUp - Processes associated with this token cannot write to objects that have a greater integrity level.
        NewProcessMin - Processes created by this token will have an integrity level that is the same or lower than it.

    .EXAMPLE Gets the mandatory policy for the current process
    Get-TokenMandatoryPolicy

    .EXAMPLE Gets the mandatory policy for the process with the id 1234
    Get-TokenMandatoryPolicy -ProcessId 1234

    .EXAMPLE Gets the mandatory policy for an existing token handle
    $h_process = Get-ProcessHandle -ProcessId 1234
    try {
        $h_token = Open-ProcessToken -Process $h_process -Access QuerySource
        try {
            Get-TokenMandatoryPolicy -Token $h_token
        } finally {
            $h_token.Dispose()
        }
    } finally {
        $h_process.Dispose()
    }
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

    Get-TokenInformation @PSBoundParameters -TokenInfoClass ([PSAccessToken.TokenInformationClass]::MandatoryPolicy) -Process {
        Param ([System.IntPtr]$TokenInfo, [System.UInt32]$TokenInfoLength)

        [PSAccessToken.TokenMandatoryPolicy](Convert-PointerToUInt32 -Ptr $TokenInfo)
    }
}