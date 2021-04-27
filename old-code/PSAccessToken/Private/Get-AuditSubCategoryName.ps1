# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-AuditSubCategoryName {
    <#
    .SYNOPSIS
    Gets the string representation for an audit policy subcategory guid.

    .PARAMETER Guid
    The GUID that represents the sub category.
    #>
    [OutputType([System.String])]
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [System.Guid]
        $Guid
    )

    $name_ptr = [System.IntPtr]::Zero
    $res = [PSAccessToken.NativeMethods]::AuditLookupSubCategoryNameW(
        $Guid,
        [Ref]$name_ptr
    ); $err_code = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()

    if (-not $res) {
        $msg = Get-Win32ErrorMessage -ErrorCode $err_code
        throw "Failed to get audit sub category name for guid '$Guid': $msg"
    }

    try {
        return [System.Runtime.InteropServices.Marshal]::PtrToStringUni($name_ptr)
    } finally {
        [PSAccessToken.NativeMethods]::AuditFree($name_ptr)
    }
}