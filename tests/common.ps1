$moduleName   = (Get-Item ([IO.Path]::Combine($PSScriptRoot, '..', 'module', '*.psd1'))).BaseName
$manifestPath = [IO.Path]::Combine($PSScriptRoot, '..', 'output', $moduleName)
Import-Module $manifestPath

Function Get-ProcessForUser {
    [OutputType([Diagnostics.Process])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]
        $UserName
    )

    Get-Process -IncludeUserName | Where-Object {
        if ($_.UserName -ne $UserName) {
            return $false
        }

        try {
            $null = Get-ProcessToken -ProcessId $_.Id -ErrorAction Stop
            return $true
        }
        catch {
            return $false
        }
    }
}
