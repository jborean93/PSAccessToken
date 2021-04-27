# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-LogonSessionData {
    <#
    .SYNOPSIS
    Get the default DACL of the access token.

    .DESCRIPTION
    Gets the default DACL of an access token, this is the default DACL applied to the DACL entry on a newly created
    object.

    .PARAMETER Token
    An explicit token to use when running the scriptblock, falls back to the current thread/process if omitted.

    .PARAMETER ProcessId
    Opens the access token for the process specified, falls back to the current thread/process if omitted.

    .PARAMETER ThreadId
    Opens the thread token for the thread specified, falls back to the current thread/process if omitted.

    .PARAMETER UseProcessToken
    Use the primary process token even if the thread is impersonating another account.

    .PARAMETER LogonId
    Instead of using the current process, you can get the logon session data for a specific logon Id.

    .OUTPUTS
    [PSAccessToken.LogonSessionData]
        LogonId: The LSA Logon ID that represents the locally unique identifier of the logon session.
        LogonType: The logon type that identifies the logon method.
        Session: The Windows session identifier.
        Sid: The SID of the user.
        UserFlags: Special flags set by LSA for the logon session.
        LastSuccessLogon: The time that the session owner most recently logged on successfully.
        LastFailedLogon: The time of the most recent failed attempt to log on.
        FailedAttemptCountSinceLastSuccessfulLogon: The number of failed attempts to log on since the last successful log on.
        LogonTime: Time when the user last logged on.
        LogoffTime: Time when the user should log off.
        KickOffTime: Time when the system should force the user to log off.
        PasswordLastSet: When the password was last changed.
        PasswordCanChange: When a reminder to change the password will occur.
        PasswordMustChange: When the password must be changed by.
        UserName: The account name of the SID that owns the logon session.
        LogonDomain: The name of the domain used to authenticate the owner of the logon sesson.
        AuthenticationPackage: The name of the LSA authentication package used to authenticate the owner of the logon session.
        LogonServer: The name of the server used to authenticate the owner of the logon session.
        DnsDomainName: The DNS domain name part for the owner of the logon session.
        Upn: The user principal name for the owner of the logon session.
        LogonScript: The relative path to the account's logon script.
        ProfilePath: The path to the user's roaming profile folder.
        HomeDirectory: The home directory for the user.
        HomeDirectoryDrive: The drive letter of the home directory.

    .EXAMPLE Gets the logon session data for the current process
    Get-LogonSessionData

    .EXAMPLE Gets the logon session data for the process with the id 1234
    Get-LogonSessionData -ProcessId 1234

    .EXAMPLE Gets the logon session data for an existing token handle
    $h_process = Get-ProcessHandle -ProcessId 1234
    try {
        $h_token = Open-ProcessToken -Process $h_process
        try {
            Get-LogonSessionData -Token $h_token
        } finally {
            $h_token.Dispose()
        }
    } finally {
        $h_process.Dispose()
    }
    #>
    [OutputType('PSAccessToken.LogonSessionData')]
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

        [Parameter(ParameterSetName="LogonId")]
        [PSAccessToken.LUID]
        $LogonId
    )

    if ($PSCmdlet.ParameterSetName -ne "LogonId") {
        # Get the LogonId from the TOKEN_STATISTICS of the access token.
        $LogonId = (Get-TokenStatistics @PSBoundParameters).AuthenticationId
    }

    $session_data_ptr = [System.IntPtr]::Zero
    $res = [PSAccessToken.NativeMethods]::LsaGetLogonSessionData(
        [Ref]$LogonId,
        [Ref]$session_data_ptr
    )

    if ($res -ne 0) {
        $msg = Get-Win32ErrorFromLsaStatus -ErrorCode $res
        throw "Failed to get LSA logon session data: $msg"
    }

    try {
        $session_data = [System.Runtime.InteropServices.Marshal]::PtrToStructure(
            $session_data_ptr, [Type][PSAccessToken.SECURITY_LOGON_SESSION_DATA]
        )

        $output = [PSCustomObject]@{
            PSTypeName = 'PSAccessToken.LogonSessionData'
            LogonId = $session_data.LogonId
            LogonType = $session_data.LogonType
            Session = $session_data.Session
            Sid = ConvertTo-SecurityIdentifier -InputObject $session_data.Sid
            UserFlags = $session_data.UserFlags
        }

        Function Convert-IntToDateTime {
            Param (
                [System.Int64]$InputObject
            )

            $datetime_value = $null

            if ($InputObject -notin @(0, [System.Int64]::MaxValue)) {
                $datetime_value = [System.DateTime]::FromFileTime($InputObject)
            }

            return $datetime_value
        }

        # Convert LARGE_INTEGER objects to a DateTime object and add to the output object.
        @(
            'LogonTime', 'LogoffTime', 'KickOffTime', 'PasswordLastSet', 'PasswordCanChange', 'PasswordMustChange'
        ) | ForEach-Object -Process {
            $output | Add-Member -MemberType NoteProperty -Name $_ -Value (Convert-IntToDateTime -InputObject $session_data.$_)
        }

        $output | Add-Member -MemberType NoteProperty -Name 'LastSuccessfulLogon' -Value (Convert-IntToDateTime -InputObject $session_data.LastLogonInfo.LastSuccessfulLogon)
        $output | Add-Member -MemberType NoteProperty -Name 'LastFailedLogon' -Value (Convert-IntToDateTime -InputObject $session_data.LastLogonInfo.LastFailedLogon)
        $output | Add-Member -MemberType NoteProperty -Name 'FailedAttemptCountSinceLastSuccessfulLogon' -Value $session_data.LastLogonInfo.FailedAttemptCountSinceLastSuccessfulLogon

        # Convert LSA_UNICODE_STRING objects to an actual string and add to the output object.
        @(
            'UserName', 'LogonDomain', 'AuthenticationPackage', 'LogonServer', 'DnsDomainName',
            'Upn', 'LogonScript', 'ProfilePath', 'HomeDirectory', 'HomeDirectoryDrive'
        ) | ForEach-Object -Process {
            $lsa_string = $session_data.$_
            $string_value = $null

            if ($lsa_string.Length -gt 0) {
                $string_value = [System.Runtime.InteropServices.Marshal]::PtrToStringUni(
                    $lsa_string.Buffer, $lsa_string.Length / 2  # Unicode string is 2 bytes per char.
                )
            }

            $output | Add-Member -MemberType NoteProperty -Name $_ -Value $string_value
        }

        return $output
    } finally {
        [void][PSAccessToken.NativeMethods]::LsaFreeReturnBuffer($session_data_ptr)
    }
}