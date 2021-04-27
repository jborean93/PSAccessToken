# Generic module deployment.
#
# ASSUMPTIONS:
#
# * folder structure either like:
#
#   - RepoFolder
#     - This PSDeploy file
#     - ModuleName
#       - ModuleName.psd1
#
#   OR the less preferable:
#   - RepoFolder
#     - RepoFolder.psd1
#
# * Nuget key in $ENV:NugetApiKey
#
# * Set-BuildEnvironment from BuildHelpers module has populated ENV:BHPSModulePath and related variables

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "",
    Justification="Required in PSDeploy, cannot output to a stream")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSCustomUseLiteralPath", "",
    Justification="We use wildcard chars to find files")]
param()

Function Get-FileFunction {
    param(
        [Parameter(Mandatory=$true)][String]$Path
    )
    $module_code = Get-Content -LiteralPath $Path -Raw

    [ScriptBlock]$predicate = {
        Param ([System.Management.Automation.Language.Ast]$Ast)

        $Ast -is [System.Management.Automation.Language.FunctionDefinitionAst]
    }

    $functions = [ScriptBlock]::Create($module_code).Ast.FindAll($predicate, $false)

    foreach ($function in $functions) {
        [PSCustomObject]@{
            Name = $function.Name
            Code = ($function.Extent.ToString() + [System.Environment]::NewLine)
        }
    }
}

Function Optimize-Project {
    param([String]$Path)

    $repo_name = (Get-ChildItem -LiteralPath $Path -Directory -Exclude @("Tests", "Docs")).Name
    $module_path = Join-Path -Path $Path -ChildPath $repo_name
    if (-not (Test-Path -LiteralPath $module_path -PathType Container)) {
        Write-Error -Message "Failed to find the module at the expected path '$module_path'"
        return
    }

    # Build the initial manifest file and get the current export signature
    $manifest_file_path = Join-Path -Path $module_path -ChildPath "$($repo_name).psm1"
    if (-not (Test-Path -LiteralPath $manifest_file_path -PathType Leaf)) {
        Write-Error -Message "Failed to find the module's psm1 file at the expected path '$manifest_file_path'"
        return
    }

    $manifest_pre_template_lines = [System.Collections.Generic.List`1[String]]@()
    $manifest_template_lines = [System.Collections.Generic.List`1[String]]@()
    $manifest_post_template_lines = [System.Collections.Generic.List`1[String]]@()
    $template_section = $false  # $false == pre, $null == template, $true == post

    foreach ($manifest_file_line in (Get-Content -LiteralPath $manifest_file_path)) {
        if ($manifest_file_line -eq '### TEMPLATED EXPORT FUNCTIONS ###') {
            $template_section = $null
        } elseif ($manifest_file_line -eq '### END TEMPLATED EXPORT FUNCTIONS ###') {
            $template_section = $true
        } elseif ($template_section -eq $false) {
            $manifest_pre_template_lines.Add($manifest_file_line)
        } elseif ($template_section -eq $true) {
            $manifest_post_template_lines.Add($manifest_file_line)
        }
    }

    # Read each public and private function and add it to the manifest template
    $private_functions_path = Join-Path -Path $module_path -ChildPath Private
    if (Test-Path -LiteralPath $private_functions_path) {
        $private_modules = @( Get-ChildItem -Path $private_functions_path\*.ps1 -ErrorAction SilentlyContinue )

        foreach ($private_module in $private_modules) {
            Get-FileFunction -Path $private_module.FullName | ForEach-Object -Process {
                $manifest_template_lines.Add($_.Code)
            }
        }
    }

    $public_module_names = [System.Collections.Generic.List`1[String]]@()
    $public_functions_path = Join-Path -Path $module_path -ChildPath Public
    if (Test-Path -LiteralPath $public_functions_path) {
        $public_modules = @( Get-ChildItem -Path $public_functions_path\*.ps1 -ErrorAction SilentlyContinue )

        foreach ($public_module in $public_modules) {
            Get-FileFunction -Path $public_module.FullName | ForEach-Object -Process {
                $manifest_template_lines.Add($_.Code)
                $public_module_names.Add($_.Name)
            }
        }
    }

    # Make sure we add an array of all the public functions and place it in our template. This is so the
    # Export-ModuleMember line at the end exports the correct functions.
    $manifest_template_lines.Add('$public_functions = @(')
    for ($i = 0; $i -lt $public_module_names.Count - 1; $i++) {
        $manifest_template_lines.Add('    ''{0}'',' -f $public_module_names[$i])
    }
    $manifest_template_lines.Add('    ''{0}''' -f $public_module_names[-1])
    $manifest_template_lines.Add(')')

    # Now build the new manifest file lines by adding the templated and post templated lines to the 1 list.
    $manifest_pre_template_lines.AddRange($manifest_template_lines)
    $manifest_pre_template_lines.AddRange($manifest_post_template_lines)
    $manifest_file = $manifest_pre_template_lines -join [System.Environment]::NewLine

    # Now replace the manifest file with our new copy and remove the public and private folders
    if (Test-Path -LiteralPath $private_functions_path) {
        Remove-Item -LiteralPath $private_functions_path -Force -Recurse
    }
    if (Test-Path -LiteralPath $public_functions_path) {
        Remove-Item -LiteralPath $public_functions_path -Force -Recurse
    }
    Set-Content -LiteralPath $manifest_file_path -Value $manifest_file

    return $module_path
}

# Do nothing if the env variable is not set
if (-not $env:BHProjectPath) {
    return
}

# Create dir to store a copy of the build artifact
$build_path = Join-Path -Path $env:BHProjectPath -ChildPath "Build"
if (Test-Path -LiteralPath $build_path) {
    Remove-Item -LiteralPath $build_path -Force -Recurse
}
New-Item -Path $build_path -ItemType Directory > $null
Copy-Item -LiteralPath $env:BHModulePath -Destination $build_path -Recurse
$module_path = Optimize-Project -Path $build_path

# Verify we can import the module
Import-Module -Name $module_path

# Publish to gallery with a few restrictions
if ($env:BHBuildSystem -ne 'Unknown' -and
    $env:BHBranchName -eq "master" -and
    $env:APPVEYOR_REPO_TAG -eq "true") {

    Deploy Module {
        By PSGalleryModule {
            FromSource $module_path
            To PSGallery
            WithOptions @{
                ApiKey = $ENV:NugetApiKey
                SourceIsAbsolute = $true
            }
        }
    }
} else {
    "Skipping deployment: To deploy, ensure that...`n" +
    "`t* You are in a known build system (Current: $ENV:BHBuildSystem)`n" +
    "`t* You are committing to the master branch (Current: $ENV:BHBranchName) `n" +
    "`t* The commit is a tagged release from github with APPVEYOR_REPO_TAG=true (Current: $ENV:APPVEYOR_REPO_TAG)" | Write-Host
}

# Publish to AppVeyor if we're in AppVeyor
if($env:BHBuildSystem -eq 'AppVeyor') {
    Deploy DeveloperBuild {
        By AppVeyorModule {
            FromSource $module_path
            To AppVeyor
            WithOptions @{
                SourceIsAbsolute = $true
                Version = $env:APPVEYOR_BUILD_VERSION
            }
        }
    }
}
