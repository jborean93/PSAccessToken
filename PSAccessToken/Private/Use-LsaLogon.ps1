# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Use-LsaLogon {
    <#
    .SYNOPSIS
    Invokes a scriptblock with an LSALogon handle.

    .DESCRIPTION
    Invokes a scriptblock with an LSALogon handle that is automatically created and cleaned up on completion.

    .PARAMETER Process
    The scriptblock to run. This should have 2 parameters;
        [System.IntPtr]$LsaHandle - The opened LSA handle.
        [Hashtable]$Variables - The variables passed in through the -Variables parameter.

    .PARAMETER Variables
    Variables to pass into the scriptblock invocation to ensure they aren't lost in the scope.

    .PARAMETER Trusted
    Only create a trusted connection, do not fall back to an untrusted connection.

    .EXAMPLE
    Use-LsaLogon -Process {
        Param ([System.IntPtr]$LsaHandle, [Hashtable]$Variables)
    }

    .NOTES
    The SeTcbPrivilege is required to open a trusted connection to LSA. Some, but not all, functions require a trusted
    connection to work which is why the -Trusted switch will only attempt a trusted connection.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [ScriptBlock]
        $Process,

        [Hashtable]
        $Variables = @{},

        [Switch]
        $Trusted
    )

    $lsa_handle = [System.IntPtr]::Zero

    $has_tcb = Get-TokenPrivileges | Where-Object { $_.Name -eq 'SeTcbPrivilege' }
    if ($null -eq $has_tcb) {
        if ($Trusted) {
            throw "Cannot open a trusted LSA connection as the caller does not have the SeTcbPrivilege"
        }

        $type = 'untrusted'
        $res = [PSAccessToken.NativeMethods]::LsaConnectUntrusted(
            [Ref]$lsa_handle
        )
    } else {
        $type = 'trusted'
        $process_name = New-Object -TypeName PSAccessToken.LSA_STRING
        $process_name.Buffer = 'PSAccessToken'
        $process_name.Length = $process_name.Buffer.Length
        $process_name.MaximumLength = $process_name.Buffer.Length + 1

        $security_mode = [System.IntPtr]::Zero

        $old_state = Set-TokenPrivileges -Name SeTcbPrivilege -Attributes Enabled
        try {
            $res = [PSAccessToken.NativeMethods]::LsaRegisterLogonProcess(
                $process_name,
                [Ref]$lsa_handle,
                [Ref]$security_mode
            )
        } finally {
            $old_state | Set-TokenPrivileges > $null
        }
    }

    if ($res -ne 0) {
        $msg = Get-Win32ErrorFromLsaStatus -ErrorCode $res
        throw "Failed to register $type LSA logon process: $msg"
    }

    try {
        &$Process -LsaHandle $lsa_handle -Variables $Variables
    } finally {
        [Void][PSAccessToken.NativeMethods]::LsaDeregisterLogonProcess($lsa_handle)
    }
}