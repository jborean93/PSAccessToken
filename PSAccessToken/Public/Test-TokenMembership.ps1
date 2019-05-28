# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Test-TokenMembership {
    <#
    .SYNOPSIS
    Tests the membership of an access token.

    .DESCRIPTION
    Tests whether a SID is an enabled member of an access token's groups. This is performed by the Win32 function
    CheckTokenMembership().

    .PARAMETER Token
    An explicit token to use when running the scriptblock, falls back to the current thread/process if omitted.

    .PARAMETER ProcessId
    Opens the access token for the process specified, falls back to the current thread/process if omitted.

    .PARAMETER ThreadId
    Opens the thread token for the thread specified, falls back to the current thread/process if omitted.

    .PARAMETER UseProcessToken
    Use the primary process token even if the thread is impersonating another account.

    .PARAMETER Sid
    The SecurityIdentifier to check the membership of. This must be part of the TokenGroups with the Enabled attribute
    set.

    .PARAMETER IncludeAppContainers
    Runs the check with the flag 'CTMF_INCLUDE_APPCONTAINER' which allows app containers to pass the call.

    .OUTPUTS
    [System.Boolean] Whether the SID is an Enabled member of the token's groups.

    .EXAMPLE Check if the Administrators token is a member
    Test-TokenMembership -Sid 'Administrators'

    .EXAMPLE Check if the Users token is a member of a specific process
    Test-TokenMembership -ProcessId 1234 -Sid 'Users'
    #>
    [OutputType([System.Boolean])]
    [CmdletBinding(DefaultParameterSetName="Token")]
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

        [Parameter(ParameterSetName="ProcessToken")]
        [Switch]
        $UseProcessToken,

        [Parameter(Mandatory=$true)]
        [System.Object]
        $Sid,

        [Switch]
        $IncludeAppContainers
    )

    $variables = @{
        sid = ConvertTo-SecurityIdentifier -InputObject $Sid
        include_app_containers = $IncludeAppContainers.IsPresent
        bound_params = $PSBoundParameters
    }
    Use-SafePointer -Size $Variables.sid.BinaryLength -Variables $variables -Process {
        Param ([System.IntPtr]$Ptr, [Hashtable]$Variables)

        Copy-SidToPointer -Ptr $Ptr -Sid $Variables.sid > $null
        $Variables.sid_ptr = $Ptr

        $bound_params = $Variables.bound_params
        Use-ImplicitToken @bound_params -Variables $Variables -Access Duplicate, Query -Process {
            Param ([PInvokeHelper.SafeNativeHandle]$Token, [Hashtable]$Variables)

            $token_type = Get-TokenType -Token $Token
            $free = $false
            try {
                # CheckTokenMembership requires an Impersonation level token, create a copy of the implicit token if it
                # is not an Impersonation token.
                if ($token_type -ne [PSAccessToken.TokenType]::Impersonation) {
                    $free = $true
                    $Token = Copy-AccessToken -Token $Token -Access Query -ImpersonationLevel Identification
                }

                $is_member = $false

                # CheckTokenMembershipEx was added in Windows 8, only use that if the IncludeAppContainers switch was set
                # so this cmdlet can work on older Windows version.
                if ($Variables.include_app_containers) {
                    $res = [PSAccessToken.NativeMethods]::CheckTokenMembershipEx(
                        $Token,
                        $Variables.sid_ptr,
                        [PSAccessToken.CtmfInclude]::AppContainer,
                        [Ref]$is_member
                    ); $err_code = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
                } else {
                    $res = [PSAccessToken.NativeMethods]::CheckTokenMembership(
                        $Token,
                        $Variables.sid_ptr,
                        [Ref]$is_member
                    ); $err_code = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
                }

                if (-not $res) {
                    $msg = Get-Win32ErrorMessage -ErrorCode $err_code
                    throw "Failed to check token membership for SID: $msg"
                }

                return $is_member
            } finally {
                if ($free) {
                    $Token.Dispose()
                }
            }
        }
    }
}