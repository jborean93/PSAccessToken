# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Convert-LuidToPrivilege {
    <#
    .SYNOPSIS
    Gets the privilege name from a LUID.

    .DESCRIPTION
    Converts a LUID struct to the privilege constant name as a string.

    .PARAMETER Luid
    The LUID to convert.
    #>
    [OutputType([System.String])]
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [PSAccessToken.LUID]
        $Luid
    )

    $lookup_privilege_name = {
        Param (
            [PSAccessToken.LUID]$Luid,
            [System.Text.StringBuilder]$Name,
            [System.Int32[]]$ValidErrors = @(0)
        )

        $length = $Name.Capacity
        $res = [PSAccessToken.NativeMethods]::LookupPrivilegeNameW(
            $null,
            [Ref]$Luid,
            $Name,
            [Ref]$length
        ); $err_code = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()

        if (-not $res -and $err_code -notin $ValidErrors) {
            $msg = Get-Win32ErrorMessage -ErrorCode $err_code
            throw "LookupPrivilegeNameW() failed: $msg"
        }

        return $length
    }

    $name = New-Object -TypeName System.Text.StringBuilder

    # Call once to get the privilege name length and set the name capacity to that length
    $length = &$lookup_privilege_name -Luid $Luid -Name $name -ValidErrors @(0, 122)
    $name.EnsureCapacity($length) > $null

    # Call again after increasing the stringbuffer capacity
    &$lookup_privilege_name -Luid $luid -Name $name > $null

    return $name.ToString()
}