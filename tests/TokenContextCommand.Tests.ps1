$moduleName   = (Get-Item ([IO.Path]::Combine($PSScriptRoot, '..', 'module', '*.psd1'))).BaseName
$manifestPath = [IO.Path]::Combine($PSScriptRoot, '..', 'build', $moduleName)

Import-Module $manifestPath

Describe "Enter-TokenContext" {

}

Describe "Exit-TokenContext" {

}
