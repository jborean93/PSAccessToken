# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-TokenImpersonationLevel {
    <#
    .SYNOPSIS
    Gets the token impersonation level of the access token.

    .DESCRIPTION
    Gets the SecurityImpersonationLevel of an access token, that states the type of impersonation token it is.

    .PARAMETER Token
    An explicit token to use when running the scriptblock, falls back to the current thread/process if omitted.

    .PARAMETER ProcessId
    Opens the access token for the process specified, falls back to the current thread/process if omitted.

    .PARAMETER ThreadId
    Opens the thread token for the thread specified, falls back to the current thread/process if omitted.

    .PARAMETER UseProcessToken
    Use the primary process token even if the thread is impersonating another account.

    .OUTPUTS
    [System.Security.Principal.TokenImpersonationLevel]

    .EXAMPLE Gets the token impersonation level for the current process
    Get-TokenImpersonationLevel

    .EXAMPLE Gets the token impersonation level for the process with the id 1234
    Get-TokenImpersonationLevel -ProcessId 1234

    .EXAMPLE Gets the token impersonation level for an existing token handle
    $h_process = Get-ProcessHandle -ProcessId 1234
    try {
        $h_token = Open-ProcessToken -Process $h_process -Access QuerySource
        try {
            Get-TokenImpersonationLevel -Token $h_token
        } finally {
            $h_token.Dispose()
        }
    } finally {
        $h_process.Dispose()
    }
    #>
    [OutputType([System.Security.Principal.TokenImpersonationLevel])]
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

    $get_params = @{
        TokenInfoClass = [PSAccessToken.TokenInformationClass]::ImpersonationLevel
        Process = {
            Param ([System.IntPtr]$TokenInfo, [System.UInt32]$TokenInfoLength)

            # SecurityImpersonationLevel does not match up with TokenImpersonationLevel, manually map it
            $level = [PSAccessToken.SecurityImpersonationLevel](Convert-PointerToUInt32 -Ptr $TokenInfo)
            switch ($level) {
                Anonymous { [System.Security.Principal.TokenImpersonationLevel]::Anonymous }
                Identification { [System.Security.Principal.TokenImpersonationLevel]::Identification }
                Impersonation { [System.Security.Principal.TokenImpersonationLevel]::Impersonation }
                Delegation { [System.Security.Principal.TokenImpersonationLevel]::Delegation }
            }
        }
    }

    try {
        Get-TokenInformation @PSBoundParameters @get_params
    } catch {
        # If the token is not an impersonation token it will fail with invalid parameter, manually return None.
        if ($_.Exception.Message.EndsWith('(Win32 ErrorCode 87 - 0x00000057)')) {
            return [System.Security.Principal.TokenImpersonationLevel]::None
        } else {
            throw $_
        }
    }
}
