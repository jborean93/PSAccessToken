# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Invoke-WithImpersonation {
    <#
    .SYNOPSIS
    Invokes a scriptblock when impersonating the Token specified.

    .DESCRIPTION
    Runs a command when impersonating the Token specified.

    .PARAMETER Token
    The access token to impersonate when running the ScriptBlock.

    .PARAMETER ScriptBlock
    Specifies the commands to run. Enclose the commands in braces ( { } ) to create a script block. This parameter is
    required.

    .PARAMETER NoNewScope
    Parameter description

    .PARAMETER InputObject
    Specifies input to the command. Enter a variable that contains the objects or type a command or expression that
    gets the objects.

    .PARAMETER ArgumentList
    Supplies the values of local variables in the command as supplied by scriptblock params.

    .EXAMPLE
    $h_process = Get-ProcessHandle -ProcessId 1234
    try {
        $h_token = Open-ProcessToken -Process $h_process -Access Duplicate, Query
        try {
            Invoke-WithImpersonation -Token $h_token -ScriptBlock { [System.Security.Principal.WindowsIdentity]::GetCurrent().User }
        } finally {
            $h_token.Dispose()
        }
    } finally {
        $h_process.Dispose()
    }

    .NOTES
    The Token must have the Duplicate and Query access mask for a primary token, or Impersonate for an impersonation
    token.
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSUseOutputTypeCorrectly", "",
        Justification="Invoke-Command returns anything but PSSA seems to think it's just a boolean."
    )]
    Param (
        [Parameter(Mandatory=$true, Position=0)]
        [PInvokeHelper.SafeNativeHandle]
        $Token,

        [Parameter(Mandatory=$true, Position=1)]
        [ScriptBlock]
        $ScriptBlock,

        [Switch]
        $NoNewScope,

        [PSObject]
        $InputObject,

        [Object[]]
        $ArgumentList
    )

    $res = [PSAccessToken.NativeMethods]::ImpersonateLoggedOnUser(
        $Token
    ); $err_code = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()

    if (-not $res) {
        $msg = Get-Win32ErrorMessage -ErrorCode $err_code
        Write-Error -Message "Failed to impersonate access token: $msg"
        return
    }

    try {
        $PSBoundParameters.Remove('Token') > $null
        Invoke-Command @PSBoundParameters
    } finally {
        [PSAccessToken.NativeMethods]::RevertToSelf() > $null
    }
}