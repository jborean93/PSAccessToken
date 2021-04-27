# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-TokenDefaultDacl {
    <#
    .SYNOPSIS
    Get the default DACL of the access token.

    .DESCRIPTION
    Gets the default DACL of an access token, this is the default DACL applied to the DACL entry on a newly created
    object.

    .PARAMETER Token
    An explicit token to use when running the scriptblock, falls back to the current thread/process if omitted.

    .PARAMETER ProcessId
    Opens the access token for the process specified, falls back to the current thread/process if omitted.

    .PARAMETER ThreadId
    Opens the thread token for the thread specified, falls back to the current thread/process if omitted.

    .PARAMETER UseProcessToken
    Use the primary process token even if the thread is impersonating another account.

    .OUTPUTS
    The RawAcl of the access token applied to new objects.

    .EXAMPLE Gets the default DACL for the current process
    Get-TokenDefaultDacl

    .EXAMPLE Gets the default DACL for the process with the id 1234
    Get-TokenDefaultDacl -ProcessId 1234

    .EXAMPLE Gets the default DACL for an existing token handle
    $h_process = Get-ProcessHandle -ProcessId 1234
    try {
        $h_token = Open-ProcessToken -Process $h_process
        try {
            Get-TokenDefaultDacl -Token $h_token
        } finally {
            $h_token.Dispose()
        }
    } finally {
        $h_process.Dispose()
    }
    #>
    [OutputType([System.Security.AccessControl.RawAcl])]
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

    Get-TokenInformation @PSBoundParameters -TokenInfoClass ([PSAccessToken.TokenInformationClass]::DefaultDacl) -Process {
        Param ([System.IntPtr]$TokenInfo, [System.UInt32]$TokenInfoLength)

        $token_dd = [System.Runtime.InteropServices.Marshal]::PtrToStructure(
            $TokenInfo, [Type][PSAccessToken.TOKEN_DEFAULT_DACL]
        )

        # No DefaultDacl is set
        if ($token_dd.DefaultDacl -eq [System.IntPtr]::Zero) {
            return
        }

        $bytes = New-Object -TypeName System.Byte[] -ArgumentList $TokenInfoLength
        [System.Runtime.InteropServices.Marshal]::Copy($token_dd.DefaultDacl, $bytes, 0, $TokenInfoLength)
        New-Object -TypeName System.Security.AccessControl.RawAcl -ArgumentList @($bytes, 0)
    }
}