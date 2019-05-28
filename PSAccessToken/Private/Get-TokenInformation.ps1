# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-TokenInformation {
    <#
    .SYNOPSIS
    Calls the GetTokenInformation method on an access token.

    .DESCRIPTION
    Calls GetTokenInformation with the info class specified and safely de-allocated the buffer once the process
    has finished with it. The ScriptBlock that is passed in should have the logic to convert the unmanaged memory to
    a managed .NET object.

    .PARAMETER Token
    An explicit token to use when running the scriptblock, falls back to the current thread/process if omitted.

    .PARAMETER ProcessId
    Opens the access token for the process specified, falls back to the current thread/process if omitted.

    .PARAMETER ThreadId
    Opens the thread token for the thread specified, falls back to the current thread/process if omitted.

    .PARAMETER UseProcessToken
    Use the primary process token even if the thread is impersonating another account.

    .PARAMETER TokenInfoClass
    The class of information to retrieve.

    .PARAMETER Process
    A ScriptBlock that processes the output buffer and creates a managed .NET object from the unmanaged memory. The
    ScriptBlock is invoked with 2 parameter:
        [System.IntPtr]$TokenInfo - A pointer to the output buffer.
        [System.UInt32]$TokenInfoLength - The number of bytes allocated.

    .EXAMPLE
    Get-TokenInformation -Token $h_token -TokenInfoClass [PSAccessToken.TokenInformationClass]::User -Process {
        Param ([System.IntPtr]$TokenInfo, [System.UInt32]$TokenInfoLength)

        $token_user = [System.Runtime.InteropServices.Marshal]::PtrToStructure(
            $TokenInfo,
            [Type][PSAccessToken.TOKEN_USER]
        )
        New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList $token_user.User.Sid
    }
    #>
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
        [PSAccessToken.TokenInformationClass]
        $TokenInfoClass,

        [Parameter(Mandatory=$true)]
        [ScriptBlock]
        $Process
    )

    # Explicitly set the access mask required for the info being retrieved.
    if ($TokenInfoClass -eq [PSAccessToken.TokenInformationClass]::Source) {
        $access_mask = [System.Security.Principal.TokenAccessLevels]::QuerySource
    } else {
        $access_mask = [System.Security.Principal.TokenAccessLevels]::Query
    }

    $process_vars = @{
        process = $Process
    }
    $PSBoundParameters.Remove('Process') > $null
    $PSBoundParameters.Remove('Access') > $null
    Use-ImplicitToken @PSBoundParameters -Access $access_mask -Variables $process_vars -Process {
        Param ([PInvokeHelper.SafeNativeHandle]$Token, [Hashtable]$Variables)

        $get_token_info = {
            Param (
                [System.IntPtr]$Buffer,
                [System.UInt32]$Length,
                [System.Int32[]]$ValidErrors = @(0)
            )

            $res = [PSAccessToken.NativeMethods]::GetTokenInformation(
                $Token,
                $TokenInfoClass,
                $Buffer,
                $Length,
                [Ref]$Length
            ); $err = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()

            if (-not $res -and $err -notin $ValidErrors) {
                $msg = Get-Win32ErrorMessage -ErrorCode $err
                throw "GetTokenInformation($($TokenInfoClass.ToString())) failed: $msg"
            }

            return $Length
        }

        # Run GetTokenInformation with a length of 0 to get the actual info length
        # Most classes return ERROR_INSUFFICIENT_BUFFER but some also return ERROR_BAD_LENGTH
        $token_l = &$get_token_info -Buffer ([System.IntPtr]::Zero) -Length 0 -ValidErrors @(24, 122)

        Use-SafePointer -Size $token_l -Process {
            Param ([System.IntPtr]$Ptr)

            &$get_token_info -Buffer $Ptr -Length $token_l > $null

            # Run the process ScriptBlock that deal with the dynamic data and outputs the managed memory object before we
            # free the unmanaged memory in the finally block.
            &$Variables.process -TokenInfo $Ptr -TokenInfoLength $token_l
        }.GetNewClosure()
    }
}