# Copyright: (c) 2021, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

$importModule = Get-Command -Name Import-Module -Module Microsoft.PowerShell.Core
if (-not ('PSAccessToken.Commands.ProcessHandleCommand' -as [type])) {
    if ($PSVersionTable.PSVersion.Major -eq 5) {
        &$importModule $PSScriptRoot\bin\net471\PSAccessToken.dll -ErrorAction Stop
    } else {
        &$importModule $PSScriptRoot\bin\netcoreapp3.1\PSAccessToken.dll -ErrorAction Stop
    }
} else {
    &$importModule -Force -Assembly ([PSAccessToken.Commands.ProcessHandleCommand].Assembly)
}
