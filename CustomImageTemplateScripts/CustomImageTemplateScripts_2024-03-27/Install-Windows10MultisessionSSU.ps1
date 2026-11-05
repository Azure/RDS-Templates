<#
.SYNOPSIS
Installs only the November 2025 SSU on Windows 10 multi-session 22H2.
.DESCRIPTION
Run elevated in 64-bit Windows PowerShell 5.1 as a CIT/AIB PowerShell customizer,
before other Windows Update customizers. Supports both Gen1 and Gen2 images.
Other images, and images with an installed SSU >= 10.0.19041.6575, are skipped.

KB5068781 is a combined LCU/SSU package; its SSU is KB5068780. The download is
the Catalog's 776.2 MB Windows 10 22H2 x64 entry, NOT a Dynamic Update package.
Extract and install only the embedded SSU using DISM (no WUSA/WinRM dependency).
The LCU is never installed; the combined package is downloaded only to obtain
the SSU. Installing the SSU alone does not update the OS build/UBR to 6575.
Errors fail the customizer; logs and failed download/extraction artifacts remain.
No restart is initiated. Place an AIB WindowsRestart customizer after this step
and before subsequent servicing or image capture. DISM 3010 is logged as success
with a required restart, so AIB's PowerShell customizer can finish normally.

Console and persistent logs: %ProgramData%\AVDImage\Logs\Install-Windows10MultisessionSSU.
Requires HTTPS access to catalog.s.download.windowsupdate.com, and normal Windows
certificate validation endpoints. This script does not configure ESU licensing.

Catalog: https://www.catalog.update.microsoft.com/Search.aspx?q=KB5068781
Release notes: https://support.microsoft.com/help/5068781
#>

[CmdletBinding()]
param()

function Write-ServicingLog {
    param([string]$Message, [ValidateSet('INFO', 'WARN', 'ERROR')][string]$Level = 'INFO')

    $line = '{0} [{1}] AVD AIB Customization : Windows 10 SSU - {2}' -f (Get-Date).ToUniversalTime().ToString('o'), $Level, $Message
    Write-Host $line
    Add-Content -LiteralPath $script:OperationLog -Value $line -Encoding UTF8 -ErrorAction Stop
}

function Test-TargetImage {
    param($CurrentVersion, $OperatingSystem, [string]$Architecture)

    # Enterprise multi-session is Enterprise for Virtual Desktops (SKU 175).
    # Do not gate on ProductType: multi-session can report server-like values.
    return ($CurrentVersion.CurrentBuildNumber -eq '19045' -and
        $CurrentVersion.DisplayVersion -eq '22H2' -and
        $CurrentVersion.EditionID -eq 'ServerRdsh' -and
        [int]$OperatingSystem.OperatingSystemSKU -eq 175 -and
        $Architecture -eq 'AMD64')
}

function Get-InstalledServicingStackVersion {
    # The servicing package uses the shared 19041 base, even on 19045 (22H2).
    # UBR and Get-HotFix do not reliably indicate the installed SSU version.
    $highestVersion = $null
    $packages = @(Get-WindowsPackage -Online -ErrorAction Stop | Where-Object {
        $_.PackageName -like 'Package_for_ServicingStack*'
    })
    foreach ($package in $packages) {
        Write-ServicingLog "SSU package: $($package.PackageName); state=$($package.PackageState)."
        if ([string]$package.PackageState -eq 'InstallPending') {
            throw 'An SSU installation is pending. Run an AIB WindowsRestart step before retrying.'
        }
        if ([string]$package.PackageState -eq 'Installed' -and
            $package.PackageName -match '~amd64~~(?<Build>\d+)\.(?<Revision>\d+)\.\d+\.\d+$') {
            $version = [version]('10.0.{0}.{1}' -f $Matches.Build, $Matches.Revision)
            if ($null -eq $highestVersion -or $version -gt $highestVersion) {
                $highestVersion = $version
            }
        }
    }
    if ($null -eq $highestVersion) {
        throw 'Cannot determine an installed amd64 SSU version. Refusing to download or service an unknown baseline.'
    }
    Write-ServicingLog "Highest installed SSU version: $highestVersion; required: 10.0.19041.6575."
    return $highestVersion
}

function Save-ServicingUpdate {
    param([string]$Destination)

    # Resolved from Catalog update ID da1498d1-321d-4565-be2b-7ba6a084e55d.
    # Pin the official file and Catalog SHA1, rather than scrape localized HTML
    # or select an ambiguous KB search result at image-build time. TLS provides
    # transport authentication; the published digest detects corrupt downloads.
    $uri = 'https://catalog.s.download.windowsupdate.com/c/msdownload/update/software/secu/2025/11/windows10.0-kb5068781-x64_33b4e6ee5956ae0f4be6a37716b0ef4fd1720e05.msu'
    $expectedSha1 = '33B4E6EE5956AE0F4BE6A37716B0EF4FD1720E05'
    $oldProtocol = [Net.ServicePointManager]::SecurityProtocol
    $oldProgressPreference = $ProgressPreference
    try {
        [Net.ServicePointManager]::SecurityProtocol = $oldProtocol -bor [Net.SecurityProtocolType]::Tls12
        $ProgressPreference = 'SilentlyContinue'
        for ($attempt = 1; $attempt -le 3; $attempt++) {
            try {
                Write-ServicingLog "Download attempt $attempt/3: $uri (22H2 x64, Catalog size 776.2 MB)."
                Invoke-WebRequest -Uri $uri -OutFile "$Destination.partial" -UseBasicParsing -TimeoutSec 1800 -ErrorAction Stop
                $hash = (Get-FileHash -LiteralPath "$Destination.partial" -Algorithm SHA1 -ErrorAction Stop).Hash
                if ($hash -ne $expectedSha1) {
                    throw "Catalog SHA1 mismatch: expected $expectedSha1; actual $hash."
                }
                Move-Item -LiteralPath "$Destination.partial" -Destination $Destination -Force -ErrorAction Stop
                Write-ServicingLog "Download verified: $((Get-Item -LiteralPath $Destination).Length) bytes; SHA1=$hash."
                return
            }
            catch {
                Write-ServicingLog "Download attempt $attempt failed: $($_.Exception.Message)" -Level WARN
                if ($attempt -eq 3) { throw }
            }
        }
    }
    finally {
        [Net.ServicePointManager]::SecurityProtocol = $oldProtocol
        $ProgressPreference = $oldProgressPreference
    }
}

function Invoke-ServicingProcess {
    param([string]$FilePath, [string]$Arguments, [string]$Step, [int[]]$SuccessCodes = @(0))

    $stdout = Join-Path $script:RunLogDirectory "$Step.stdout.log"
    $stderr = Join-Path $script:RunLogDirectory "$Step.stderr.log"
    Write-ServicingLog "Starting ${Step}: $FilePath $Arguments"
    $process = Start-Process -FilePath $FilePath -ArgumentList $Arguments -Wait -PassThru -NoNewWindow `
        -RedirectStandardOutput $stdout -RedirectStandardError $stderr -ErrorAction Stop
    Write-ServicingLog "$Step exit code=$($process.ExitCode); stdout=$stdout; stderr=$stderr."
    if ($process.ExitCode -notin $SuccessCodes) {
        foreach ($path in @($stdout, $stderr)) {
            Get-Content -LiteralPath $path -Tail 30 -ErrorAction SilentlyContinue | ForEach-Object {
                Write-ServicingLog $_ -Level ERROR
            }
        }
        throw "$Step failed with exit code $($process.ExitCode). See $script:RunLogDirectory and %SystemRoot%\Logs\CBS\CBS.log."
    }
    if ($process.ExitCode -eq 3010) {
        Write-ServicingLog "$Step requires a restart. Deferred to the next CIT/AIB WindowsRestart step." -Level WARN
    }
}

function Assert-ServicingHost {
    if (-not [Environment]::Is64BitProcess) {
        throw 'Run this customizer in 64-bit Windows PowerShell.'
    }
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Administrator or SYSTEM privileges are required for online servicing.'
    }
}

function Install-ServicingBaseline {
    $currentVersion = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction Stop
    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
    $architecture = [Environment]::GetEnvironmentVariable('PROCESSOR_ARCHITECTURE', 'Machine')
    Write-ServicingLog "OS=$($os.Caption); build=$($currentVersion.CurrentBuildNumber).$($currentVersion.UBR); displayVersion=$($currentVersion.DisplayVersion); edition=$($currentVersion.EditionID); SKU=$($os.OperatingSystemSKU); architecture=$architecture. Gen1 and Gen2 are both eligible."
    if (-not (Test-TargetImage $currentVersion $os $architecture)) {
        Write-ServicingLog 'SKIP: not a Windows 10 Enterprise multi-session 22H2 x64 image. No download or installation.'
        return
    }

    Assert-ServicingHost
    $requiredVersion = [version]'10.0.19041.6575'
    if ((Get-InstalledServicingStackVersion) -ge $requiredVersion) {
        Write-ServicingLog 'SKIP: SSU 6575 or newer is already installed. No download or installation.'
        return
    }
    if (Test-Path -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') {
        throw 'CBS reports a pending reboot. Run an AIB WindowsRestart step before servicing.'
    }

    $workDirectory = Join-Path $env:TEMP ('AVD-SSU-KB5068781-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $workDirectory -ErrorAction Stop | Out-Null
    Write-ServicingLog "Working directory: $workDirectory."
    $msuPath = Join-Path $workDirectory 'windows10.0-kb5068781-x64.msu'
    Save-ServicingUpdate -Destination $msuPath

    $expand = Join-Path $env:SystemRoot 'System32\expand.exe'
    Invoke-ServicingProcess -FilePath $expand -Arguments "-F:* `"$msuPath`" `"$workDirectory`"" -Step 'Extract-MSU'
    $lcu = @(Get-ChildItem -LiteralPath $workDirectory -Filter 'Windows10.0-KB5068781-x64.cab' -File)
    if ($lcu.Count -ne 1) { throw 'Expected exactly one KB5068781 x64 cumulative update CAB in the MSU.' }
    $ssuDirectory = Join-Path $workDirectory 'SSU'
    New-Item -ItemType Directory -Path $ssuDirectory -ErrorAction Stop | Out-Null
    # Some combined packages expose the SSU directly; others embed it in the LCU.
    $ssu = @(Get-ChildItem -LiteralPath $workDirectory -Filter 'SSU-*-x64.cab' -File)
    if ($ssu.Count -eq 0) {
        Invoke-ServicingProcess -FilePath $expand -Arguments "-F:SSU-*.cab `"$($lcu[0].FullName)`" `"$ssuDirectory`"" -Step 'Extract-SSU'
        $ssu = @(Get-ChildItem -LiteralPath $ssuDirectory -Filter 'SSU-*-x64.cab' -File)
    }
    if ($ssu.Count -ne 1 -or $ssu[0].Name -ne 'SSU-19041.6575-x64.cab') {
        throw "Expected SSU-19041.6575-x64.cab; found: $($ssu.Name -join ', ')."
    }

    $dism = Join-Path $env:SystemRoot 'System32\dism.exe'
    $ssuLog = Join-Path $script:RunLogDirectory 'SSU.dism.log'
    Invoke-ServicingProcess -FilePath $dism -Arguments "/Online /Add-Package /PackagePath:`"$($ssu[0].FullName)`" /Quiet /NoRestart /LogPath:`"$ssuLog`"" -Step 'Install-SSU' -SuccessCodes @(0, 3010)
    # Verify the actual installed stack, not the OS build/UBR. Do not install the LCU.
    if ((Get-InstalledServicingStackVersion) -lt $requiredVersion) {
        throw 'SSU installation returned success, but the installed SSU is still below 6575.'
    }
    Write-ServicingLog 'SUCCESS: SSU KB5068780 (6575 or newer) is installed. The KB5068781 LCU was NOT installed. Schedule an AIB WindowsRestart before further servicing/capture.'

    try {
        Remove-Item -LiteralPath $workDirectory -Recurse -Force -ErrorAction Stop
        Write-ServicingLog 'Removed downloaded and extracted packages; diagnostic logs retained.'
    }
    catch {
        Write-ServicingLog "Package cleanup failed: $($_.Exception.Message)" -Level WARN
    }
}

$runId = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssfffZ') + '-' + [guid]::NewGuid().ToString('N')
$script:RunLogDirectory = Join-Path $env:ProgramData "AVDImage\Logs\Install-Windows10MultisessionSSU\$runId"
New-Item -ItemType Directory -Path $script:RunLogDirectory -Force -ErrorAction Stop | Out-Null
$script:OperationLog = Join-Path $script:RunLogDirectory 'operation.log'
$stopwatch = [Diagnostics.Stopwatch]::StartNew()
try {
    Write-ServicingLog "START: SSU-only installation (KB5068780), extracted from KB5068781. LCU installation is disabled. Logs: $script:RunLogDirectory."
    Install-ServicingBaseline
}
catch {
    Write-ServicingLog "FAILED: $($_.Exception.Message); location=$($_.InvocationInfo.PositionMessage); stack=$($_.ScriptStackTrace)" -Level ERROR
    throw
}
finally {
    $stopwatch.Stop()
    Write-ServicingLog "END: elapsed=$($stopwatch.Elapsed). No automatic reboot was initiated."
}