# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-TokenAccessInformation {
    <#
    .SYNOPSIS
    Gets the access information of the access token.

    .DESCRIPTION
    Gets all the token components that are necessary to perform an access check.

    .PARAMETER Token
    An explicit token to use when running the scriptblock, falls back to the current thread/process if omitted.

    .PARAMETER ProcessId
    Opens the access token for the process specified, falls back to the current thread/process if omitted.

    .PARAMETER ThreadId
    Opens the thread token for the thread specified, falls back to the current thread/process if omitted.

    .OUTPUTS
    [PSAccessToken.TokenAccessInformation]
        SidHash: Contains the following keys
            Hash: The hash value of Sids, this is UInt32 array of 32 elements.
            Sids: A PSAccessToken.SidAndAttributes object of the tokens groups.
        RestrictedSidHash:
            Hash: The hash value of Sids, this is UInt32 array of 32 elements.
            Sids: A PSAccessToken.SidAndAttributes object of the tokens restricted groups.
        Privileges: A PSAccessToken.PrivilegeAndAttributes of the tokens privileges.
        AuthenticationId: The LSA Logon ID that represents the locally unique identifier of the logon session.
        ImpersonationLevel: The tokens type and impersonation level.
        MandatoryPolicy: The tokens mandatory policy level.
        AppContainerNumber: The tokens AppContainer number, set to 0 if not an AppContainer.
        PackageSid: The AppContainer package SID.
        CapabilitiesHash:
            Hash: The hash value of Sids, this is UInt32 array of 32 elements.
            Sids: A PSAccessToken.SidAndAttributes object of the tokens capabilities.
        TrustLevelSid: The protected process trust level of the token.

    .EXAMPLE Gets the access information for the current process
    Get-TokenAccessInformation

    .EXAMPLE Gets the access information for the process with the id 1234
    Get-TokenAccessInformation -ProcessId 1234

    .EXAMPLE Gets the access information for an existing token handle
    $h_process = Get-ProcessHandle -ProcessId 1234
    try {
        $h_token = Open-ProcessToken -Process $h_process
        try {
            Get-TokenAccessInformation -Token $h_token
        } finally {
            $h_token.Dispose()
        }
    } finally {
        $h_process.Dispose()
    }
    #>
    [OutputType('PSAccessToken.TokenAccessInformation')]
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
        $ThreadId
    )

    Get-TokenInformation @PSBoundParameters -TokenInfoClass ([PSAccessToken.TokenInformationClass]::AccessInformation) -Process {
        Param ([System.IntPtr]$TokenInfo, [System.UInt32]$TokenInfoLength)

        $token_ai = [System.Runtime.InteropServices.Marshal]::PtrToStructure(
            $TokenInfo, [Type][PSAccessToken.TOKEN_ACCESS_INFORMATION]
        )

        $sid_hash = Convert-PointerToSidAndAttributesHash -Ptr $token_ai.SidHash
        $restricted_sid_hash = Convert-PointerToSidAndAttributesHash -Ptr $token_ai.RestrictedSidHash
        $token_privileges = Convert-PointerToTokenPrivileges -Ptr $token_ai.Privileges
        $imp_level = Get-ImpersonationLevel -TokenType $token_ai.TokenType -SecurityImpersonationLevel $token_ai.ImpersonationLevel
        $package_sid = ConvertTo-SecurityIdentifier -InputObject $token_ai.PackageSid
        $capabilities_hash = Convert-PointerToSidAndAttributesHash -Ptr $token_ai.CapabilitiesHash
        $trust_level_sid = ConvertTo-SecurityIdentifier -InputObject $token_ai.TrustLevelSid

        [PSCustomObject]@{
            PSTypeName = 'PSAccessToken.TokenAccessInformation'
            SidHash = $sid_hash
            RestrictedSidHash = $restricted_sid_hash
            Privileges = $token_privileges
            AuthenticationId = $token_ai.AuthenticationId
            ImpersonationLevel = $imp_level
            MandatoryPolicy = $token_ai.MandatoryPolicy
            AppContainerNumber = $token_ai.AppContainerNumber
            PackageSid = $package_sid
            CapabilitiesHash = $capabilities_hash
            TrustLevelSid = $trust_level_sid
        }
    }
}