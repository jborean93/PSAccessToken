# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Use-ImplicitToken {
    <#
    .SYNOPSIS
    Invokes a scriptblock with the standard logic in PSAccessToken for getting the access token.

    .DESCRIPTION
    Invokes a scriptblock with an access token passed in through the -Token parameter. This follows the logic when
    getting the access token;
        1. If Token, ProcessId, or ThreadId is not set, get the access token for the current thread/process.
        2. If ProcessId is specified, opens the access token for the process specified.
        3. If ThreadId is specified, opens the access token for the thread specified.
        4. If Token is specified, use that token

    .PARAMETER Token
    An explicit token to use when running the scriptblock, falls back to the current thread/process if omitted.

    .PARAMETER ProcessId
    Opens the access token for the process specified, falls back to the current thread/process if omitted.

    .PARAMETER ThreadId
    Opens the thread token for the thread specified, falls back to the current thread/process if omitted.

    .PARAMETER UseProcessToken
    Use the primary process token even if the thread is impersonating another account.

    .PARAMETER Process
    The scriptblock to execute which has the implicit token passed in with the -Token parameter.

    .PARAMETER Variables
    Custom variables to pass into the Process scriptblock for execution.

    .PARAMETER Access
    The access level used to open the access token, defaults to MaximumAllowed.

    .PARAMETER UnboundParameters
    Extra parameters that store the calling cmdlet params without erroring out.
    #>
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
        $UseProcessToken,

        [Parameter(Mandatory=$true)]
        [ScriptBlock]
        $Process,

        [AllowEmptyCollection()]
        [Hashtable]
        $Variables = @{},

        [System.Security.Principal.TokenAccessLevels]
        $Access = [System.Security.Principal.TokenAccessLevels]::MaximumAllowed,

        # Allow PSBoundParameters from calling cmdlets to be passed through this cmdlet without errors.
        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [Object[]]
        $UnboundParameters
    )

    # Get a handle to the process or thread by using the ID.
    $h_pid_tid = $null
    if ($PSCmdlet.ParameterSetName -eq 'PID') {
        $h_pid_tid = Get-ProcessHandle -ProcessId $ProcessId -ErrorAction Stop
    } elseif ($PSCmdlet.ParameterSetName -eq 'TID') {
        $h_pid_tid = Get-ThreadHandle -ThreadId $ThreadId -ErrorAction Stop
    }

    try {
        # Open a handle to the access token if one was not explicitly passed in.
        $free_token = $false
        if ($null -eq $Token) {
            $open_params = @{
                Access = $Access
                ErrorAction = 'Stop'
            }

            $free_token = $true
            if ($PSCmdlet.ParameterSetName -eq 'PID') {
                $Token = Open-ProcessToken -Process $h_pid_tid @open_params
            } elseif ($PSCmdlet.ParameterSetName -eq 'TID') {
                $Token = Open-ThreadToken -Thread $h_pid_tid @open_params
            } else {
                if (-not $UseProcessToken.IsPresent) {
                    try {
                        $Token = Open-ThreadToken @open_params
                    } catch {
                        # Fallback to opening the process token if the current thread isn't run under impersonation.
                        if (-not $_.Exception.Message.EndsWith('(Win32 ErrorCode 1008 - 0x000003F0)')) {
                            throw $_
                        }
                    }
                }

                if ($null -eq $Token) {
                    $Token = Open-ProcessToken @open_params
                }
            }
        }

        try {
            # Now run the script block with the access token passed in.
            &$Process -Token $Token -Variables $Variables
        } finally {
            # Close the access token handle if it was opened in this cmdlet.
            if ($free_token) {
                $Token.Dispose()
            }
        }
    } finally {
        # Close the opened Process or Thread if it was opened by this cmdlet.
        if ($null -ne $h_pid_tid) {
            $h_pid_tid.Dispose()
        }
    }
}