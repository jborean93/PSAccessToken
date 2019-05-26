# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

@{
    RootModule = 'PSAccessToken.psm1'
    ModuleVersion = '0.1.0'
    GUID = '95c97fa5-ff78-4703-b485-642518518a4c'
    Author = 'Jordan Borean'
    Copyright = 'Copyright (c) 2019 by Jordan Borean, Red Hat, licensed under MIT.'
    Description = "Manages a Windows access token.`nSee https://github.com/jborean93/PSAccessToken for more info"
    PowerShellVersion = '3.0'
    RequiredModules = @(
        'PInvokeHelper'
    )
    FunctionsToExport = @(
        'Copy-AccessToken',
        'Get-LogonSessionData',
        'Get-ProcessHandle',
        'Get-ThreadHandle',
        'Get-TokenAuditPolicy',
        'Get-TokenDefaultDacl',
        'Get-TokenElevationType',
        'Get-TokenGroups',
        'Get-TokenGroupsAndPrivileges',
        'Get-TokenImpersonationLevel',
        'Get-TokenOrigin',
        'Get-TokenOwner',
        'Get-TokenPrimaryGroup',
        'Get-TokenPrivileges',
        'Get-TokenRestrictedSids',
        'Get-TokenSandboxInert',
        'Get-TokenSessionId',
        'Get-TokenSource',
        'Get-TokenStatistics',
        'Get-TokenType',
        'Get-TokenUser',
        'Invoke-LogonUser',
        'Invoke-WithImpersonation',
        'New-AccessToken',
        'New-RestrictedToken',
        'Open-ProcessToken',
        'Open-ThreadToken',
        'Set-TokenPrivileges'
    )
    PrivateData = @{
        PSData = @{
            Tags = @(
                "DevOps",
                "Access",
                "Token",
                "Windows"
            )
            LicenseUri = 'https://github.com/jborean93/PSAccessToken/blob/master/LICENSE'
            ProjectUri = 'https://github.com/jborean93/PSAccessToken'
            ReleaseNotes = 'See https://github.com/jborean93/PSAccessToken/blob/master/CHANGELOG.md'
        }
    }
}