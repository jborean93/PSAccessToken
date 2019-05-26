# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Convert-SidToLogonId {
    <#
    .SYNOPSIS
    Converts the SecurityIdentifier Logon ID to the native LUID object.

    .PARAMETER InputObject
    The security identifier to convert, must match the pattern 'S-1-5-5-{High}-{Low}'.
    #>
    [OutputType([PSAccessToken.LUID])]
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [System.Security.Principal.SecurityIdentifier]
        $InputObject
    )

    if ($InputObject.Value -notmatch '^S-1-5-5-(?<High>\d+)-(?<Low>\d+)$') {
        throw "The input SID '$InputObject' does not match the pattern 'S-1-5-5-{High}-{Low}', not a valid LogonID."
    }

    $logon_id = New-Object -TypeName PSAccessToken.LUID
    $logon_id.LowPart = $Matches.Low
    $logon_id.HighPart = $Matches.High

    return $logon_id
}