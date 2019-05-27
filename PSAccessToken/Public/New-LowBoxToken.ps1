# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function New-LowBoxToken {
    <#
    .SYNOPSIS
    Create a Low Box access token from an existing token.

    .DESCRIPTION
    Create a Low Box access token for use in an AppContainer process. This will take a copy of an existing access
    token, set the Low integrity level to the duplicate and add capabilities to the token.

    .PARAMETER Token
    Copies the explicit token, falls back to the current thread/process if omitted.

    .PARAMETER ProcessId
    Copies the access token for the process specified, falls back to the current thread/process if omitted.

    .PARAMETER ThreadId
    Copies the thread token for the thread specified, falls back to the current thread/process if omitted.

    .PARAMETER AppContainer
    The name of an AppContainer package or an explicit SID to use as the package identifier of the Low Box token.

    .PARAMETER Capabilities
    A list of Windows Capabilities or SIDs to set on the Low Box token.

    .PARAMETER Handles
    A list of handles to set on the Low Box token.

    .PARAMETER Access
    The access level to open the new access token with.

    .EXAMPLE
    An example

    .NOTES
    This uses an undocumented NT function, it should be stable but it may change in the future.
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

        [Parameter(Mandatory=$true)]
        [System.String]
        $AppContainer,

        [Parameter(Mandatory=$true)]
        [AllowEmptyCollection()]
        [Object[]]
        $Capabilities,

        [AllowNull()]
        [System.IntPtr[]]
        $Handles = @(),

        [System.Security.Principal.TokenAccessLevels]
        $Access = [System.Security.Principal.TokenAccessLevels]0  # Same as the existing token
    )

    $variables = @{
        app_container = $AppContainer
        capabilities = $Capabilities
        handles = $Handles
        access = $Access
    }

    Use-ImplicitToken @PSBoundParameters -Variables $variables -Process {
        Param ([PInvokeHelper.SafeNativeHandle]$Token, [Hashtable]$Variables)

        $Variables.token = $Token

        $tg_pointer_params = @{
            DefaultAttributes = [PSAccessToken.TokenGroupAttributes]::Enabled
            NullAsEmpty = $true
            ForceDefaultAttributes = $true
            OmitTokenGroups = $true
            Variables = $Variables
        }
        $Variables.capabilities | Use-TokenGroupsPointer @tg_pointer_params -Process {
            Param ([System.IntPtr]$Ptr, [Hashtable]$Variables)

            $Variables.capability_and_attr = $Ptr

            try {
                $app_container_sid = [System.Security.Principal.SecurityIdentifier]$Variables.app_container
            } catch [System.Management.Automation.PSInvalidCastException] {
                $app_container_sid = Get-AppContainerSecurityIdentifier -Name $Variables.app_container
            }
            $Variables.app_container_sid = $app_container_sid

            Use-SafePointer -Size $app_container_sid.BinaryLength -Variables $Variables -Process {
                Param ([System.IntPtr]$Ptr, [Hashtable]$Variables)

                Copy-SidToPointer -Ptr $Ptr -Sid $Variables.app_container_sid > $null

                $oa = New-Object -TypeName PSAccessToken.OBJECT_ATTRIBUTES
                $oa.Length = [System.Runtime.InteropServices.Marshal]::SizeOf([Type][PSAccessToken.OBJECT_ATTRIBUTES])
                $low_box_token = New-Object -TypeName PInvokeHelper.SafeNativeHandle

                $handles = $Variables.handles
                if ($handles.Length -eq 0) {
                    $handles = $null
                }

                if (-not $PSCmdlet.ShouldProcess("Access Token", "Create Low Box")) {
                    # -WhatIf was passed in, don't actually duplicate the token.
                    return $null
                }

                $res = [PSAccessToken.NativeMethods]::NtCreateLowBoxToken(
                    [Ref]$low_box_token,
                    $Variables.token,
                    $Variables.access,
                    $oa,
                    $Ptr,
                    $Variables.capabilities.Length,
                    $Variables.capability_and_attr,
                    $Variables.handles.Length,
                    $handles
                )
                if ($res -ne 0) {
                    $msg = Get-Win32ErrorFromNtStatus -ErrorCode $res
                    throw "Failed to create low box token: $msg"
                }

                return $low_box_token
            }
        }
    }
}