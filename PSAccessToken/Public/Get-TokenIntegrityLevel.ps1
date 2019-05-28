# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-TokenIntegrityLevel {
    <#
    .SYNOPSIS
    Gets the integrity level of the access token.

    .DESCRIPTION
    Gets the integrity level of the access token. This level is used during access checks by Windows based on the
    TokenMandatoryPolicy of the token.

    .PARAMETER Token
    An explicit token to use when running the scriptblock, falls back to the current thread/process if omitted.

    .PARAMETER ProcessId
    Opens the access token for the process specified, falls back to the current thread/process if omitted.

    .PARAMETER ThreadId
    Opens the thread token for the thread specified, falls back to the current thread/process if omitted.

    .PARAMETER UseProcessToken
    Use the primary process token even if the thread is impersonating another account.

    .OUTPUTS
    [PSAccessToken.TokenIntegrityLevel]
        Sid - The SecurityIdentifier of the integrity level.
        Label - The human name of the Sid.
        Attributes - Further attributes of the integrity level group.

    .EXAMPLE Gets the integrity level for the current process
    Get-TokenIntegrityLevel

    .EXAMPLE Gets the integrity level for the process with the id 1234
    Get-TokenIntegrityLevel -ProcessId 1234

    .EXAMPLE Gets the integrity level for an existing token handle
    $h_process = Get-ProcessHandle -ProcessId 1234
    try {
        $h_token = Open-ProcessToken -Process $h_process -Access QuerySource
        try {
            Get-TokenIntegrityLevel -Token $h_token
        } finally {
            $h_token.Dispose()
        }
    } finally {
        $h_process.Dispose()
    }
    #>
    [OutputType('PSAccessToken.TokenIntegrityLevel')]
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

    Get-TokenInformation @PSBoundParameters -TokenInfoClass ([PSAccessToken.TokenInformationClass]::IntegrityLevel) -Process {
        Param ([System.IntPtr]$TokenInfo, [System.UInt32]$TokenInfoLength)

        $token_mandatory_label = [System.Runtime.InteropServices.Marshal]::PtrToStructure(
            $TokenInfo, [Type][PSAccessToken.TOKEN_MANDATORY_LABEL]
        )

        $sid = ConvertTo-SecurityIdentifier -InputObject $token_mandatory_label.Label.Sid
        [PSCustomObject]@{
            PSTypeName = 'PSAccessToken.TokenIntegrityLevel'
            Sid = $sid
            Label = ConvertFrom-SecurityIdentifier -Sid $sid -ErrorBehaviour PassThru
            Attributes = $token_mandatory_label.Label.Attributes
        }
    }
}