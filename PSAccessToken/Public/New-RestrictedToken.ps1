# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function New-RestrictedToken {
    <#
    .SYNOPSIS
    Creates a new access token that is a restricted version of an existing token.

    .DESCRIPTION
    Creates a restricted access token that can have disabled SIDs, deleted privileges, and list of restricting SIDs.

    .PARAMETER Token
    An explicit token to use when running the scriptblock, falls back to the current thread/process if omitted.

    .PARAMETER ProcessId
    Opens the access token for the process specified, falls back to the current thread/process if omitted.

    .PARAMETER ThreadId
    Opens the thread token for the thread specified, falls back to the current thread/process if omitted.

    .PARAMETER RemovedSids
    A list of SIDs or accounts to disable from the token. These SIDs are set as a deny only SID and are used to
    validate deny only DACL access.

    .PARAMETER RestrictedSids
    A list of SIDs or accounts to add to the restricted SIDs list of the new token.

    .PARAMETER RemovedPrivileges
    A list of privilege names to remove on the restricted token.

    .PARAMETER DisableMaxPrivilege
    Remove all privileges except the 'SeChangeNotifyPrivilege'. Setting this switch will ignore the RemovedPrivileges
    parameter.

    .PARAMETER SandboxInert
    Adds the SANDBOX_INERT flag to the access token. This is only valid for systems with AppLocker.

    .PARAMETER LuaToken
    Creates a limited user access (LUA) token, this is the limited token that UAC will generate.

    .PARAMETER WriteRestricted
    The RestrictedSids will only be evaluated for write access.

    .OUTPUTS
    [PInvokeHelper.SafeNativeHandle] The creates restricted token, the .Dispose() function should be called once this
    is no longer needed.

    .EXAMPLE Create a restricted token without the Administrators group
    $h_token = New-RestrictedToken -RemovedSids 'Administrators'
    $h_token.Dispose()

    .EXAMPLE Create restricted token without the SeRestore and SeBackup privilege
    $h_token = New-RestrictedToken -RemovedPrivileges SeRestorePrivilege, SeBackupPrivilege
    $h_token.Dispose()

    .EXAMPLE Create a limited user account token
    $h_token = New-RestrictedToken -LuaToken
    $h_token.Dispose()

    .NOTES
    See https://docs.microsoft.com/en-us/windows/desktop/api/securitybaseapi/nf-securitybaseapi-createrestrictedtoken
    for more info.
    #>
    [OutputType([PInvokeHelper.SafeNativeHandle])]
    [CmdletBinding(DefaultParameterSetName="Token", SupportsShouldProcess=$true)]
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

        [Object[]]
        $DisabledSids = @(),

        [Object[]]
        $RestrictedSids = @(),

        [Object[]]
        $RemovedPrivileges = @(),

        [Switch]
        $DisableMaxPrivilege,

        [Switch]
        $SandboxInert,

        [Switch]
        $LuaToken,

        [Switch]
        $WriteRestricted
    )

    $DisabledSids = ConvertTo-SecurityIdentifier -InputObject $DisabledSids
    $RestrictedSids = ConvertTo-SecurityIdentifier -InputObject $RestrictedSids

    # Start with blank flags
    $flags = [PSAccessToken.RestrictedTokenFlags]0
    if ($DisableMaxPrivilege.IsPresent) {
        $flags = $flags -bor [PSAccessToken.RestrictedTokenFlags]::DisableMaxPrivilege

        # Ignore the RemovedPrivileges param is -DisableMaxPrivilege is set.
        $RemovedPrivileges = @()
    }

    if ($SandboxInert) {
        $flags = $flags -bor [PSAccessToken.RestrictedTokenFlags]::SandboxInert
    }

    if ($LuaToken) {
        $flags = $flags -bor [PSAccessToken.RestrictedTokenFlags]::LuaToken
    }

    if ($WriteRestricted) {
        $flags = $flags -bor [PSAccessToken.RestrictedTokenFlags]::WriteRestricted
    }

    # Calculate the size of the Groups and Privileges structures
    $sid_and_attributes_size = [System.Runtime.InteropServices.Marshal]::SizeOf(
        [Type][PSAccessToken.SID_AND_ATTRIBUTES]
    )
    $luid_and_attributes_size = [System.Runtime.InteropServices.Marshal]::SizeOf(
        [Type][PSAccessToken.LUID_AND_ATTRIBUTES]
    )

    $removed_privileges_size = $luid_and_attributes_size * $RemovedPrivileges.Length
    $disabled_sids_size = $sid_and_attributes_size * $DisabledSids.Length
    foreach ($group in $DisabledSids) {
        $disabled_sids_size += $group.BinaryLength
    }

    $restricted_sids_size = $sid_and_attributes_size * $RestrictedSids.Length
    foreach ($group in $RestrictedSids) {
        $restricted_sids_size += $group.BinaryLength
    }

    $variables = @{
        flags = $flags
    }
    Use-ImplicitToken @PSBoundParameters -Variables $variables -Process {
        Param ([PInvokeHelper.SafeNativeHandle]$Token, [Hashtable]$Variables)

        # Create a pointer for the DisabledSids SID_AND_ATTRIBUTES[] array.
        Use-SafePointer -Size $disabled_sids_size -Variables $Variables -Process {
            Param ([System.IntPtr]$Ptr, [Hashtable]$Variables)

            # Copy the DisabledSids SID_AND_ATTRIBUTES[] array to the pointer.
            Copy-SidToSidAndAttributesPtr -Ptr $Ptr -Sids $DisabledSids
            $Variables.disabled_sids = $Ptr

            # Create a pointer for the RemovedPrivileges LUID_AND_ATTRIBUTES[] array.
            Use-SafePointer -Size $removed_privileges_size -Variables $Variables -Process {
                Param ([System.IntPtr]$Ptr, [Hashtable]$Variables)

                # Copy the RemovedPrivileges LUID_AND_ATTRIBUTES[] array to the pointer.
                Copy-PrivilegeToLuidAndAttributesPtr -Ptr $Ptr -Privileges $RemovedPrivileges
                $Variables.removed_privileges = $Ptr

                # Create a pointer for the RestrictedSids SID_AND_ATTRIBUTES[] array.
                Use-SafePointer -Size $restricted_sids_size -Variables $Variables -Process {
                    Param ([System.IntPtr]$Ptr, [Hashtable]$Variables)

                    # Copy the RestrictedSids SID_AND_ATTRIBUTES[] array to the pointer.
                    Copy-SidToSidAndAttributesPtr -Ptr $Ptr -Sids $RestrictedSids

                    # Return if in -WhatIf
                    if (-not $PSCmdlet.ShouldProcess("Restricted Access Token", "Create")) {
                        return
                    }

                    $res_token = New-Object -TypeName PInvokeHelper.SafeNativeHandle
                    $res = [PSAccessToken.NativeMethods]::CreateRestrictedToken(
                        $Token,
                        $Variables.flags,
                        $DisabledSids.Length,
                        $Variables.disabled_sids,
                        $RemovedPrivileges.Length,
                        $Variables.removed_privileges,
                        $RestrictedSids.Length,
                        $Ptr,
                        [Ref]$res_token
                    ); $err_code = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()

                    if (-not $res) {
                        $msg = Get-Win32ErrorMessage -ErrorCode $err_code
                        throw "Failed to create restricted token: $msg"
                    }

                    return $res_token
                }
            }
        }
    }
}