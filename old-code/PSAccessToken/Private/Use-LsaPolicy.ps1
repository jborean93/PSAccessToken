# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Use-LsaPolicy {
    <#
    .SYNOPSIS
    Invokes a scriptblock with an LSAPolicy handle.

    .DESCRIPTION
    Invokes a scriptblock with an LSAPolicy handle that is automatically created and cleaned up on completion.

    .PARAMETER Process
    The scriptblock to run. This should have 2 parameters;
        [System.IntPtr]$LsaHandle - The opened LSA policy handle.
        [Hashtable]$Variables - The variables passed in through the -Variables parameter.

    .PARAMETER Variables
    Variables to pass into the scriptblock invocation to ensure they aren't lost in the scope.

    .EXAMPLE
    Use-LsaPolicy -Process {
        Param ([System.IntPtr]$LsaHandle, [Hashtable]$Variables)
    }
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [ScriptBlock]
        $Process,

        [Hashtable]
        $Variables = @{},

        [PSAccessToken.LsaAccessMask]
        $Access
    )

    $oa = New-Object -TypeName PSAccessToken.OBJECT_ATTRIBUTES
    $oa.Length = [System.Runtime.InteropServices.Marshal]::SizeOf([Type][PSAccessToken.OBJECT_ATTRIBUTES])

    $lsa_handle = [System.IntPtr]::Zero
    $res = [PSAccessToken.NativeMethods]::LsaOpenPolicy(
        [System.IntPtr]::Zero,
        $oa,
        $Access,
        [Ref]$lsa_handle
    )

    if ($res -ne 0) {
        $msg = Get-Win32ErrorFromLsaStatus -ErrorCode $res
        throw "Failed to open LSA Policy handle: $msg"
    }

    try {
        &$Process -LsaHandle $lsa_handle -Variables $Variables
    } finally {
        [Void][PSAccessToken.NativeMethods]::LsaClose($lsa_handle)
    }
}