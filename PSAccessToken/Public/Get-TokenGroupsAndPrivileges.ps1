# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-TokenGroupsAndPrivileges {
    <#
    .SYNOPSIS
    Get the groups and privilegesof the access token.

    .DESCRIPTION
    Gets the TokenGroupsAndPrivileges info class of an access token which contains a list of groups and privileges
    that are assigned to the token.

    .PARAMETER Token
    An explicit token to use when running the scriptblock, falls back to the current thread/process if omitted.

    .PARAMETER ProcessId
    Opens the access token for the process specified, falls back to the current thread/process if omitted.

    .PARAMETER ThreadId
    Opens the thread token for the thread specified, falls back to the current thread/process if omitted.

    .PARAMETER UseProcessToken
    Use the primary process token even if the thread is impersonating another account.

    .OUTPUTS
    [PSAccessToken.TokenGroupsAndPrivileges]

    .EXAMPLE Gets the groups and privileges for the current process
    Get-TokenGroupsAndPrivileges

    .EXAMPLE Gets the groups and privileges for the process with the id 1234
    Get-TokenGroupsAndPrivileges -ProcessId 1234

    .EXAMPLE Gets the groups and privileges for an existing token handle
    $h_process = Get-ProcessHandle -ProcessId 1234
    try {
        $h_token = Open-ProcessToken -Process $h_process
        try {
            Get-TokenGroupsAndPrivileges -Token $h_token
        } finally {
            $h_token.Dispose()
        }
    } finally {
        $h_process.Dispose()
    }
    #>
    [OutputType('PSAccessToken.TokenGroupsAndPrivileges')]
    [CmdletBinding(DefaultParameterSetName="Token")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSUseSingularNouns", "",
        Justification="The actual object is called TOKEN_GROUPS_AND_PRIVILEGES"
    )]
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
        $UseProcessToken
    )

    Get-TokenInformation @PSBoundParameters -TokenInfoClass ([PSAccessToken.TokenInformationClass]::GroupsAndPrivileges) -Process {
        Param ([System.IntPtr]$TokenInfo, [System.UInt32]$TokenInfoLength)

        $token_gap = [System.Runtime.InteropServices.Marshal]::PtrToStructure(
            $TokenInfo, [Type][PSAccessToken.TOKEN_GROUPS_AND_PRIVILEGES]
        )

        $groups = Convert-PointerToSidAndAttributes -Ptr $token_gap.Sids -Count $token_gap.SidCount
        $rsids = Convert-PointerToSidAndAttributes -Ptr $token_gap.RestrictedSids -Count $token_gap.RestrictedSidCount
        $privileges = Convert-PointerToPrivilegeAndAttributes -Ptr $token_gap.Privileges -Count $token_gap.PrivilegeCount

        [PSCustomObject]@{
            PSTypeName = 'PSAccessToken.TokenGroupsAndPrivileges'
            Groups = $groups
            RestrictedSids = $rsids
            Privileges = $privileges
            AuthenticationId = $token_gap.AuthenticationId
        }
    }
}