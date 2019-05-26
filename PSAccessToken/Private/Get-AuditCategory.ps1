# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-AuditCategory {
    <#
    .SYNOPSIS
    Gets all audit categories and their sub categories.

    .NOTES
    The ordering is quite importing for Get-TokenAuditPolicy to return the correct information.
    #>
    [OutputType('PSAccessToken.AuditCategory')]
    [CmdletBinding()]
    Param ()

    $guid_ptr = [System.IntPtr]::Zero
    $category_count = 0
    [Void][PSAccessToken.NativeMethods]::AuditEnumerateCategories(
        [Ref]$guid_ptr,
        [Ref]$category_count
    )

    try {
        $category_guid_ptr = $guid_ptr
        for ($i = 0; $i -lt $category_count; $i++) {
            $category_guid = [System.Runtime.InteropServices.Marshal]::PtrToStructure(
                $category_guid_ptr, [Type][System.Guid]
            )

            $category_name = Get-AuditCategoryName -Guid $category_guid

            [PSCustomObject]@{
                PSTypeName = 'PSAccessToken.AuditCategory'
                Name = $category_name
                Guid = $category_guid
                SubCategories = (Get-AuditSubCategory -Category $category_guid)
            }

            $category_guid_ptr = [System.IntPtr]::Add(
                $category_guid_ptr, [System.Runtime.InteropServices.Marshal]::SizeOf([Type][System.Guid])
            )
        }
    } finally {
        [PSAccessToken.NativeMethods]::AuditFree($guid_ptr)
    }
}