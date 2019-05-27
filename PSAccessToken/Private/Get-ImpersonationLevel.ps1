# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-ImpersonationLevel {
    <#
    .SYNOPSIS
    Gets the TokenImpersonationLevel from the type and level specified.

    .PARAMETER TokenType
    The raw PSAccessToken.TokenType of the token.

    .PARAMETER SecurityImpersonationLevel
    The raw PSAccessToken.SecurityImpersonationLevel of the token.
    #>
    [OutputType([System.Security.Principal.TokenImpersonationLevel])]
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [PSAccessToken.TokenType]
        $TokenType,

        [Parameter(Mandatory=$true)]
        [PSAccessToken.SecurityImpersonationLevel]
        $SecurityImpersonationLevel
    )

    if ($TokenType -eq [PSAccessToken.TokenType]::Primary) {
        return [System.Security.Principal.TokenImpersonationLevel]::None
    } else {
        $imp_level = switch ($SecurityImpersonationLevel) {
            Anonymous { [System.Security.Principal.TokenImpersonationLevel]::Anonymous }
            Identification { [System.Security.Principal.TokenImpersonationLevel]::Identification }
            Impersonation { [System.Security.Principal.TokenImpersonationLevel]::Impersonation }
            Delegation { [System.Security.Principal.TokenImpersonationLevel]::Delegation }
        }
        return $imp_level
    }
}