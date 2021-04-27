# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-AuthenticationPackageId {
    <#
    .SYNOPSIS
    Gets the LSA authentication package ID for the human name passed in.

    .PARAMETER Name
    The name of the authentication package.

    .PARAMETER LsaHandle
    An open handle to LSA.
    #>
    [OutputType([System.UInt32])]
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [System.String]
        $Name,

        [Parameter(Mandatory=$true)]
        [System.IntPtr]
        $LsaHandle
    )

    $package_name = New-Object -TypeName PSAccessToken.LSA_STRING
    $package_name.Length = $Name.Length
    $package_name.MaximumLength = $Name.Length + 1
    $package_name.Buffer = $Name
    $auth_id = [System.UInt32]0

    $res = [PSAccessToken.NativeMethods]::LsaLookupAuthenticationPackage(
        $LsaHandle,
        $package_name,
        [Ref]$auth_id
    )

    if ($res -ne 0) {
        $msg = Get-Win32ErrorFromLsaStatus -ErrorCode $res
        throw "Failed to get LSA authentication package ID for '$Name': $msg"
    }

    return $auth_id
}