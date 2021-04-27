# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Copy-AccessToken {
    <#
    .SYNOPSIS
    Creates a copy of an access token.

    .DESCRIPTION
    Creates a copy of an access token using DuplicateTokenEx. This token is can have a custom type and impersonation
    level set.

    .PARAMETER Token
    An explicit token to use when running the scriptblock, falls back to the current thread/process if omitted.

    .PARAMETER ProcessId
    Opens the access token for the process specified, falls back to the current thread/process if omitted.

    .PARAMETER ThreadId
    Opens the thread token for the thread specified, falls back to the current thread/process if omitted.

    .PARAMETER UseProcessToken
    Use the primary process token even if the thread is impersonating another account.

    .PARAMETER Access
    The TokenAccessLevels that specifies the access rights of the copied access token. Set to 0 (default) to just use
    the existing rights of the current access token.

    .PARAMETER ImpersonationLevel
    Specifies the impersionation level of the duplicated token. Set to None (default) to create a primary token
    instead.

    .OUTPUTS
    [PInvokeHelper.SafeNativeHandle] A handle to the copied token, the .Dispose() method should be called once the
    token is no longer needed.

    .EXAMPLE Copy an access token for the current process
    $h_token = Copy-AccessToken
    $h_token.Dispose()

    .EXAMPLE Copy an access token for explicit PID
    $h_token = Copy-AccessToken -ProcessId 1234
    $h_token.Dispose()

    .EXAMPLE Copy an access token from an explicitly opened token
    $h_process = Get-ProcessHandle -ProcessId 1234
    try {
        $h_token = Open-ProcessToken -Process $h_process -Access Duplicate
        try {
            $dup_token = Copy-AccessToken -Token $h_token
            $dup_token.Dispose()
        } finally {
            $h_token.Dispose()
        }
    } finally {
        $h_process.Dispose()
    }

    .EXAMPLE Create an impersonation token
    $h_token = Copy-AccessToken -ImpersonationLevel Impersonation
    $h_token.Dispose()

    .NOTES
    When copying an explicit token, it will require the Duplicate access mask on the opened token to copy.
    #>
    [OutputType([PInvokeHelper.SafeNativeHandle])]
    [CmdletBinding(DefaultParameterSetName="Token", SupportsShouldProcess=$true)]
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
        $UseProcessToken,

        [System.Security.Principal.TokenAccessLevels]
        $Access = [System.Security.Principal.TokenAccessLevels]0,  # Same as the existing token

        [System.Security.Principal.TokenImpersonationLevel]
        $ImpersonationLevel = [System.Security.Principal.TokenImpersonationLevel]::None
    )

    if ($ImpersonationLevel -eq [System.Security.Principal.TokenImpersonationLevel]::None) {
        $token_type = [PSAccessToken.TokenType]::Primary
        $security_impersonation_level = [PSAccessToken.SecurityImpersonationLevel]::Anonymous  # Doesn't matter for Primary token
    } else {
        $token_type = [PSAccessToken.TokenType]::Impersonation
        $security_impersonation_level = switch ($ImpersonationLevel) {
            Anonymous { [PSAccessToken.SecurityImpersonationLevel]::Anonymous }
            Identification  { [PSAccessToken.SecurityImpersonationLevel]::Identification }
            Impersonation  { [PSAccessToken.SecurityImpersonationLevel]::Impersonation  }
            Delegation  { [PSAccessToken.SecurityImpersonationLevel]::Delegation  }
        }
    }

    $variables = @{
        access = $Access
    }
    $PSBoundParameters.Remove('Process') > $null
    $PSBoundParameters.Remove('Access') > $null

    Use-ImplicitToken @PSBoundParameters -Variables $variables -Process {
        Param ([PInvokeHelper.SafeNativeHandle]$Token, [Hashtable]$Variables)

        if (-not $PSCmdlet.ShouldProcess("Access Token", "Duplicate")) {
            # -WhatIf was passed in, don't actually duplicate the token.
            return $null
        }

        $dup_token = New-Object -TypeName PInvokeHelper.SafeNativeHandle
        $res = [PSAccessToken.NativeMethods]::DuplicateTokenEx(
            $Token,
            $Variables.access,
            [System.IntPtr]::Zero,  # TODO: SecurityAttributes
            $security_impersonation_level,
            $token_type,
            [Ref]$dup_token
        ); $err = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()

        if (-not $res) {
            $msg = Get-Win32ErrorMessage -ErrorCode $err
            throw "DuplicateTokenEx() failed: $msg"
        }

        return $dup_token
    }
}