# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-AuditSubCategory {
    <#
    .SYNOPSIS
    Get the audit sub categories inside a category.

    .PARAMETER Category
    The category to get sub categories of, if omitted then all sub categories are retrieved.
    #>
    [OutputType('PSAccessToken.AuditSubCategory')]
    [CmdletBinding()]
    Param (
        [System.Guid]
        $Category = [System.Guid]::Empty
    )

    $cat_guid_ptr = [System.IntPtr]::Zero
    $category_count = 0
    $res = [PSAccessToken.NativeMethods]::AuditEnumerateSubCategories(
        $Category,
        ($Category -eq [System.Guid]::Empty),
        [Ref]$cat_guid_ptr,
        [Ref]$category_count
    ); $err_code = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()

    if (-not $res) {
        $msg = Get-Win32ErrorMessage -ErrorCode $err_code
        throw "Failed to get audit sub category list: $msg"
    }
    try {
        $sub_category_ptr = $cat_guid_ptr
        for ($i = 0; $i -lt $category_count; $i++) {
            $sub_category_guid = [System.Runtime.InteropServices.Marshal]::PtrToStructure(
                $sub_category_ptr, [Type][System.Guid]
            )

            $sub_category_name = Get-AuditSubCategoryName -Guid $sub_category_guid
            [PSCustomObject]@{
                PSTypeName = 'PSAccessToken.AuditSubCategory'
                Name = $sub_category_name
                Guid = $sub_category_guid
            }

            $sub_category_ptr = [System.IntPtr]::Add(
                $sub_category_ptr, [System.Runtime.InteropServices.Marshal]::SizeOf([Type][System.Guid])
            )
        }
    } finally {
        [PSAccessToken.NativeMethods]::AuditFree($cat_guid_ptr)
    }
}