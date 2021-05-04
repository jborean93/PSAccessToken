[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Release')]
    [string]
    $Configuration = 'Debug'
)

$modulePath = [IO.Path]::Combine($PSScriptRoot, 'module')
$manifestItem = Get-Item ([IO.Path]::Combine($modulePath, '*.psd1'))

$ModuleName = $manifestItem.BaseName
$Manifest = Test-ModuleManifest -Path $manifestItem.FullName -ErrorAction Ignore -WarningAction Ignore
$Version = $Manifest.Version
$BuildPath = [IO.Path]::Combine($PSScriptRoot, 'build')
$PowerShellPath = [IO.Path]::Combine($PSScriptRoot, 'module')
$CSharpPath = [IO.Path]::Combine($PSScriptRoot, 'src')
$ReleasePath = [IO.Path]::Combine($BuildPath, $ModuleName, $Version)
$IsUnix = $PSEdition -eq 'Core' -and -not $IsWindows

[xml]$csharpProjectInfo = Get-Content ([IO.Path]::Combine($CSharpPath, '*.csproj'))
$TargetFrameworks = @($csharpProjectInfo.Project.PropertyGroup.TargetFrameworks[0].Split(
    ';', [StringSplitOptions]::RemoveEmptyEntries))

$PSFramework = if ($PSVersionTable.PSVersion.Major -eq 5) {
    $csharpProjectInfo.Project.PropertyGroup.PSWinFramework[0]
}
else {
    $csharpProjectInfo.Project.PropertyGroup.PSFramework[0]
}


task Clean {
    if (Test-Path $ReleasePath) {
        Remove-Item $ReleasePath -Recurse -Force
    }

    New-Item -ItemType Directory $ReleasePath | Out-Null
}

task BuildDocs {
    $helpParams = @{
        Path = [IO.Path]::Combine($PSScriptRoot, 'docs', 'en-US')
        OutputPath = [IO.Path]::Combine($ReleasePath, 'en-US')
    }
    New-ExternalHelp @helpParams | Out-Null
}

task BuildManaged {
    Push-Location -Path $CSharpPath
    $arguments = @(
        'publish'
        '--configuration', $Configuration
        '--verbosity', 'q'
        '-nologo'
        "-p:Version=$Version"
    )
    try {
        foreach ($framework in $TargetFrameworks) {
            dotnet @arguments --framework $framework
        }
    }
    finally {
        Pop-Location
    }
}

task CopyToRelease {
    $copyParams = @{
        Path = [IO.Path]::Combine($PowerShellPath, '*')
        Destination = $ReleasePath
        Recurse = $true
        Force = $true
    }
    Copy-Item @copyParams

    foreach ($framework in $TargetFrameworks) {
        $buildFolder = [IO.Path]::Combine($CSharpPath, 'bin', $Configuration, $framework, 'publish')
        $binFolder = [IO.Path]::Combine($ReleasePath, 'bin', $framework)
        if (-not (Test-Path -LiteralPath $binFolder)) {
            New-Item -Path $binFolder -ItemType Directory | Out-Null
        }
        Copy-Item ([IO.Path]::Combine($buildFolder, "*")) -Destination $binFolder
    }
}

task Package {
    $nupkgPath = [IO.Path]::Combine($BuildPath, "$ModuleName.$Version.nupkg")
    if (Test-Path $nupkgPath) {
        Remove-Item $nupkgPath -Force
    }

    $repoParams = @{
        Name = 'LocalRepo'
        SourceLocation = $BuildPath
        PublishLocation = $BuildPath
        InstallationPolicy = 'Trusted'
    }
    if (Get-PSRepository -Name $repoParams.Name -ErrorAction SilentlyContinue) {
        Unregister-PSRepository -Name $repoParams.Name
    }

    Register-PSRepository @repoParams
    try {
        Publish-Module -Path $ReleasePath -Repository $repoParams.Name
    } finally {
        Unregister-PSRepository -Name $repoParams.Name
    }
}

task Analyze {
    $pssaSplat = @{
        Path = $ReleasePath
        Settings = [IO.Path]::Combine($PSScriptRoot, 'ScriptAnalyzerSettings.psd1')
        Recurse = $true
        ErrorAction = 'SilentlyContinue'
    }
    $results = Invoke-ScriptAnalyzer @pssaSplat
    if ($null -ne $results) {
        $results | Out-String
        throw "Failed PsScriptAnalyzer tests, build failed"
    }
}

task DoTest {
    $resultsPath = [IO.Path]::Combine($BuildPath, 'TestResults')
    if (-not (Test-Path $resultsPath)) {
        New-Item $resultsPath -ItemType Directory -ErrorAction Stop | Out-Null
    }

    $resultsFile = [IO.Path]::Combine($resultsPath, 'Pester.xml')
    if (Test-Path $resultsFile) {
        Remove-Item $resultsFile -ErrorAction Stop -Force
    }

    $coverageOutputFile = [IO.Path]::Combine($resultsPath, 'CoverageOutput.txt')
    if (Test-Path $coverageOutputFile) {
        Remove-Item $coverageOutputFile -ErrorAction Stop -Force
    }

    $processScript = [IO.Path]::Combine($PSScriptRoot, 'tools', 'ProcessRunspace.ps1')
    $processPidFile = $processScript + '.pid'
    $pwsh = [Environment]::GetCommandLineArgs()[0] -replace '\.dll$', ''
    $arguments = @(
        '-NoProfile'
        '-NonInteractive'
        if (-not $IsUnix) {
            '-ExecutionPolicy', 'Bypass'
        }
        '-File'
        $processScript
    )

    $runspace = $null
    $proc = $null
    try {
        $procSplat = if ($Configuration -eq 'Debug') {
            # We use coverlet to collect code coverage of our binary
            @{
                FilePath = 'coverlet'
                ArgumentList = @(
                    '"{0}"' -f ([IO.Path]::Combine($ReleasePath, 'bin', $PSFramework))
                    '--target', '"{0}"' -f $pwsh
                    '--targetargs', '"{0}"' -f ($arguments -join " ")
                    '--output', '"{0}"' -f ([IO.Path]::Combine($resultsPath, 'Coverage.xml'))
                    '--format', 'cobertura'
                )
                RedirectStandardOutput = $coverageOutputFile
            }
        }
        else {
            @{
                FilePath = $pwsh
                ArgumentList = $arguments
            }
        }
        $procSplat.PassThru = $true
        if (-not $IsUnix) {
            $procSplat.WindowStyle = 'Hidden'
        }

        $fsWatcher = [IO.FileSystemWatcher]::new((Split-Path $processPidFile -Parent),
            (Split-Path $processPidFile -Leaf))
        try {
            $fsWatcher.IncludeSubDirectories = $false
            $fsWatcher.NotifyFilter = 'LastWrite'

            # Start the process and wait until the pwsh target is online and ready
            $proc = Start-Process @procSplat
            [void]$fsWatcher.WaitForChanged('Changed')
        }
        finally {
            $fsWatcher.Dispose()
        }

        $procPid = [Int32](Get-Content $processPidFile).Trim()
        $connInfo = [System.Management.Automation.Runspaces.NamedPipeConnectionInfo]::new($procPid)
        $runspace = [RunspaceFactory]::CreateRunspace($connInfo, $Host, $null)
        $runspace.Open()

        $ps = [PowerShell]::Create()
        $ps.Runspace = $runspace
        [void]$ps.AddScript({

            [CmdletBinding()]
            param (
                [Parameter(Mandatory)]
                [String]
                $PesterPath,

                [Parameter(Mandatory)]
                [String]
                $TestPath,

                [Parameter(Mandatory)]
                [String]
                $OutputFile
            )

            try {
                [PSCustomObject]$PSVersionTable |
                    Select-Object -Property *, @{N='Architecture';E={
                        switch ([IntPtr]::Size) {
                            4 { 'x86' }
                            8 { 'x64' }
                            default { 'Unknown' }
                        }
                    }} |
                    Format-List |
                    Out-Host

                Import-Module -Name $PesterPath -Force

                $configuration = [PesterConfiguration]::Default
                $configuration.Output.Verbosity = 'Detailed'
                $configuration.Run.PassThru = $true
                $configuration.Run.Path = $TestPath
                $configuration.TestResult.Enabled = $true
                $configuration.TestResult.OutputPath = $OutputFile
                $configuration.TestResult.OutputFormat = 'NUnitXml'

                Invoke-Pester -Configuration $configuration -WarningAction Ignore
            }
            finally {
                # Signals the process to exit now the test is done
                [Control]::Finished.Set()
            }

        }.ToString()).AddParameters(@{
            PesterPath = [IO.Path]::Combine($PSScriptRoot, 'tools', 'Modules', 'Pester')
            TestPath = [IO.Path]::Combine($PSScriptRoot, 'tests')
            OutputFile = $resultsFile
        })

        $result = $ps.Invoke()

        $ps.Streams.Error | ForEach-Object { Write-Error -ErrorRecord $_ -ErrorAction Continue }
    }
    finally {
        if ($runspace) { $runspace.Dispose() }
        if ($proc) { $proc | Wait-Process }
    }

    if (Test-Path $coverageOutputFile) {
        Get-Content $coverageOutputFile | Out-Host
    }

    if(-not $result -or $result.FailedCount -gt 0) {
        $failedCount = if ($result.FailedCount) { $result.FailedCount } else { 'unknown' }
        throw "Pester failed $failedCount tests, build failed"
    }
}

task DoInstall {
    $installBase = $Home
    if ($profile) {
        $installBase = $profile | Split-Path
    }

    $installPath = [IO.Path]::Combine($installBase, 'Modules', $ModuleName, $Version)
    if (-not (Test-Path $installPath)) {
        New-Item $installPath -ItemType Directory | Out-Null
    }

    Copy-Item -Path ([IO.Path]::Combine($ReleasePath, '*')) -Destination $installPath -Force -Recurse
}

<#
task DoPublish {
    if ($env:GALLERY_API_KEY) {
        $apiKey = $env:GALLERY_API_KEY
    } else {
        $userProfile = [Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)
        if (Test-Path $userProfile/.PSGallery/apikey.xml) {
            $apiKey = (Import-Clixml $userProfile/.PSGallery/apikey.xml).GetNetworkCredential().Password
        }
    }

    if (-not $apiKey) {
        throw 'Could not find PSGallery API key!'
    }

    Publish-Module -Name $ReleasePath -NuGetApiKey $apiKey -AllowPrerelease -Force:$Force.IsPresent
}
#>

task Build -Jobs Clean, BuildManaged, CopyToRelease, BuildDocs, Package

# FIXME: Work out why we need the obj and bin folder for coverage to work
task Test -Jobs BuildManaged, Analyze, DoTest

task Install -Jobs DoInstall

#task Publish -Jobs Test, DoPublish

task . Build
