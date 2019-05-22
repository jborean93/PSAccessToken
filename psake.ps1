[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "",
    Justification="Global vars are used outside of where they are declared")]
Param ()

# PSake makes variables declared here available in other scriptblocks
# Init some things
Properties {
    # Find the build folder based on build system
    $ProjectRoot = $env:BHProjectPath
    if (-not $ProjectRoot) {
        $ProjectRoot = $PSScriptRoot
    }

    $Timestamp = Get-Date -UFormat "%Y%m%d-%H%M%S"
    $PSVersion = $PSVersionTable.PSVersion.Major
    $TestFile = "TestResults_PS$PSVersion`_$TimeStamp.xml"
    $lines = '----------------------------------------------------------------------'

    $Verbose = @{}
    if ($env:BHCommitMessage -match "!verbose") {
        $Verbose = @{ Verbose = $true }
    }
}

Task Default -Depends Deploy

Task Init {
    $lines
    Set-Location -LiteralPath $ProjectRoot
    "Build System Details:"
    Get-Item -Path env:BH*

    $build_path = [System.IO.Path]::Combine($ProjectRoot, "Build")
    if (Test-Path -LiteralPath $build_path) {
        Remove-Item -LiteralPath $build_path -Force -Recurse
    }

    "`n"
}

Task Sanity -Depends Init {
    $lines
    "`n`tSTATUS: Sanity tests with PSScriptAnalyzer"

    $pssa_params = @{
        ErrorAction = "SilentlyContinue"
        Path = "$ProjectRoot$([System.IO.Path]::DirectorySeparatorChar)"
        Recurse = $true
    }
    $results = Invoke-ScriptAnalyzer @pssa_params @verbose
    if ($null -ne $results) {
        $results | Out-String
        Write-Error "Failed PsScriptAnalyzer tests, build failed"
    }
    "`n"
}

Task Test -Depends Sanity  {
    $lines
    "`n`tSTATUS: Testing with PowerShell $PSVersion"

    # Gather test results. Store them in a variable and file
    $public_path = [System.IO.Path]::Combine($env:BHModulePath, "Public")
    $private_path = [System.IO.Path]::Combine($env:BHModulePath, "Private")
    $code_coverage = [System.Collections.Generic.List`1[String]]@()
    if (Test-Path -LiteralPath $public_path) {
        $code_coverage.Add([System.IO.Path]::Combine($public_path, "*.ps1"))
    }
    if (Test-Path -LiteralPath $private_path) {
        $code_coverage.Add([System.IO.Path]::Combine($private_path, "*.ps1"))
    }

    $pester_params = @{
        CodeCoverage = $code_coverage.ToArray()
        OutputFile = [System.IO.Path]::Combine($ProjectRoot, $TestFile)
        OutputFormat = "NUnitXml"
        PassThru = $true
        Path = [System.IO.Path]::Combine($ProjectRoot, "Tests")
    }
    $TestResults = Invoke-Pester @pester_params @Verbose

    # In Appveyor?  Upload our tests! #Abstract this into a function?
    If($Env:BHBuildSystem -eq 'AppVeyor') {
        $web_client = New-Object -TypeName System.Net.WebClient
        $web_client.UploadFIle(
            "https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)",
            [System.IO.Path]::Combine($ProjectRoot, $TestFile)
        )
    }

    Remove-Item -LiteralPath ([System.IO.Path]::Combine($ProjectRoot, $TestFile)) -Force -ErrorAction SilentlyContinue

    # Failed tests?
    # Need to tell psake or it will proceed to the deployment. Danger!
    if($TestResults.FailedCount -gt 0) {
        Write-Error "Failed '$($TestResults.FailedCount)' tests, build failed"
    }
    "`n"
}

Task Deploy -Depends Test {
    $lines

    $deploy_params = @{
        Path = $ProjectRoot
        Force = $true
        Recurse = $false # We keep psdeploy artifacts, avoid deploying those : )
    }
    Invoke-PSDeploy @deploy_params @Verbose
}
