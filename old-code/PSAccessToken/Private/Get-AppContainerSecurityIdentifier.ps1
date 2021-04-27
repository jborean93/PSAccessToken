# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-AppContainerSecurityIdentifier {
    <#
    .SYNOPSIS
    Get the SID for the AppContainer name.

    .PARAMETER Name
    The name of the AppContainer package to get the SID for.
    #>
    [OutputType([System.Security.Principal.SecurityIdentifier])]
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [System.String]
        $Name
    )

    $sid_ptr = [System.IntPtr]::Zero
    $res = [PSAccessToken.NativeMethods]::DeriveAppContainerSidFromAppContainerName(
        $Name,
        [Ref]$sid_ptr
    )

    if ($res -ne 0) {
        $msg = Get-Win32ErrorMessage -ErrorCode ($res -band 0x0000FFFF)
        throw "Failed to derive AppContainer SID from name '$Name': $msg"
    }

    try {
        return ConvertTo-SecurityIdentifier -InputObject $sid_ptr
    } finally {
        [PSAccessToken.NativeMethods]::FreeSid($sid_ptr)
    }
}