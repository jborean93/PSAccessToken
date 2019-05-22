# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Copy-PrivilegeToLuidAndAttributesPtr {
    Param (
        [Parameter(Mandatory=$true)]
        [System.IntPtr]
        $Ptr,

        [Parameter(Mandatory=$true)]
        [AllowEmptyCollection()]
        [AllowNull()]
        [System.String[]]
        $Privileges
    )

    if ($null -eq $Privileges -or $Privileges.Length -eq 0) {
        return
    }

    foreach ($privilege in $Privileges) {
        $luid_and_attributes = New-Object -TypeName PSAccessToken.LUID_AND_ATTRIBUTEs
        $luid_and_attributes.Luid = (Convert-PrivilegeToLuid -Name $privilege)
        $Ptr = Copy-StructureToPointer -Ptr $Ptr -Structure $luid_and_attributes
    }
}