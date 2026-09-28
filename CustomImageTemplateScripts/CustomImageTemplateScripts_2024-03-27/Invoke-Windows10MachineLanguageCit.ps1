<#
.SYNOPSIS
Stages and runs the Windows 10 language package from AVD Custom Image Templates.

.DESCRIPTION
Use this script as the custom script URI for four Azure Image Builder
PowerShell customizers. StageInputs downloads and verifies one release ZIP,
safely extracts the exact package contract, optionally stages deterministic
CAB/MSU media, and writes a durable manifest. After an AIB restart,
InstallAndService re-verifies the immutable staged content and invokes the
packaged AIB wrapper using only durable local paths. Later phases re-verify the
same content, manifest, and orchestrator state before continuing.

Private Azure Blob downloads can use the build VM managed identity. Public
HTTPS and HTTPS SAS URIs are also accepted, but SAS values must be handled as
secrets by the deployment system and are never written to the staging manifest.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('StageInputs', 'InstallAndService', 'ApplyMachineLanguage', 'Validate')]
    [string]$Phase,

    [Parameter(Mandatory = $true)]
    [ValidateScript({
        try {
            $culture = [Globalization.CultureInfo]::GetCultureInfo($_)
        }
        catch {
            throw "'$_' is not a recognized Windows culture tag."
        }
        if ($culture.IsNeutralCulture -or [string]::IsNullOrWhiteSpace($culture.Name)) {
            throw "'$_' is not a specific Windows culture tag."
        }
        $true
    })]
    [string]$LanguageTag,

    [uri]$ReleasePackageUri,

    [ValidatePattern('^[A-Fa-f0-9]{64}$')]
    [string]$ReleasePackageSha256,

    [uri]$LanguagePackCabUri,

    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$LanguagePackCabPath,

    [ValidatePattern('^[A-Fa-f0-9]{64}$')]
    [string]$LanguagePackCabSha256,

    [switch]$DownloadLanguagePack,

    [uri]$LcuPackageUri,

    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$LcuPackagePath,

    [ValidatePattern('^[A-Fa-f0-9]{64}$')]
    [string]$LcuPackageSha256,

    [switch]$UseWindowsUpdate,

    [switch]$UseManagedIdentityForDownloads,

    [switch]$RequireRdp,

    [switch]$AllowRecognizedNonServicingPendingFileRenames,

    [ValidateRange(30, 7200)]
    [int]$DownloadTimeoutSeconds = 1800,

    [ValidateScript({ [IO.Path]::IsPathRooted($_) })]
    [string]$StagingRoot = 'C:\ProgramData\Windows10MachineLanguageCit',

    [ValidateScript({ [IO.Path]::IsPathRooted($_) })]
    [string]$WorkingDirectory = 'C:\ProgramData\Windows10MachineLanguageAib'
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$StagingRoot = [IO.Path]::GetFullPath($StagingRoot)
$WorkingDirectory = [IO.Path]::GetFullPath($WorkingDirectory)

$expectedArchiveFiles = @(
    'Aib-Customizers.example.json',
    'Aib-Customizers.TwoRestartCandidate.example.json',
    'Copy-UserInternationalSettingsToSystemCompat.ps1',
    'Invoke-Windows10MachineLanguageAib.ps1',
    'Invoke-Windows10MachineLanguageCit.ps1',
    'README.md',
    'Set-Windows10MachineLanguage.ps1',
    'setDefaultLang.ps1',
    'SHA256SUMS.txt',
    'Test-Windows10MachineLanguageHealth.ps1',
    'Tests\SetDefaultLang.Static.Tests.ps1',
    'Windows10-Language-Servicing.txt'
)
$manifestPath = Join-Path $StagingRoot 'staging-manifest.json'
$contractPath = Join-Path $StagingRoot 'staging-contract.json'
$archivePath = Join-Path $StagingRoot 'ReleasePackage.zip'
$packageRoot = Join-Path $StagingRoot 'Package'
$mediaRoot = Join-Path $packageRoot 'Media'

function Get-NormalizedSha256 {
    param([Parameter(Mandatory = $true)][string]$Value)

    return $Value.Trim().ToUpperInvariant()
}

function Get-FileSha256 {
    param([Parameter(Mandatory = $true)][string]$Path)

    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Assert-FileHash {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$ExpectedSha256,
        [Parameter(Mandatory = $true)][string]$Description
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "$Description was not found at '$Path'."
    }

    $actual = Get-FileSha256 -Path $Path
    $expected = Get-NormalizedSha256 -Value $ExpectedSha256
    if ($actual -ne $expected) {
        throw "$Description SHA-256 mismatch. Expected $expected but found $actual."
    }
}

function Get-SafeUriDisplay {
    param([Parameter(Mandatory = $true)][uri]$Uri)

    return $Uri.GetLeftPart([UriPartial]::Path)
}

function Assert-HttpsUri {
    param(
        [Parameter(Mandatory = $true)][uri]$Uri,
        [Parameter(Mandatory = $true)][string]$Description
    )

    if (-not $Uri.IsAbsoluteUri -or $Uri.Scheme -ne 'https') {
        throw "$Description must be an absolute HTTPS URI."
    }
    if (-not [string]::IsNullOrWhiteSpace($Uri.UserInfo)) {
        throw "$Description must not contain URI user information."
    }
}

function Get-StorageAccessToken {
    $tokenUri = 'http://169.254.169.254/metadata/identity/oauth2/token' +
        '?api-version=2018-02-01&resource=https%3A%2F%2Fstorage.azure.com%2F'
    try {
        $response = Invoke-RestMethod -Method Get -Uri $tokenUri -Headers @{ Metadata = 'true' } `
            -TimeoutSec 30 -UseBasicParsing
    }
    catch {
        throw "The build VM managed identity could not obtain an Azure Storage token: $($_.Exception.Message)"
    }

    if ([string]::IsNullOrWhiteSpace([string]$response.access_token)) {
        throw 'The managed identity response did not contain the expected token.'
    }
    return [string]$response.access_token
}

function Save-HttpsFile {
    param(
        [Parameter(Mandatory = $true)][uri]$Uri,
        [Parameter(Mandatory = $true)][string]$Destination,
        [Parameter(Mandatory = $true)][string]$Description,
        [switch]$UseManagedIdentity
    )

    Assert-HttpsUri -Uri $Uri -Description $Description
    $displayUri = Get-SafeUriDisplay -Uri $Uri
    $headers = @{}
    if ($UseManagedIdentity) {
        $storageSuffixes = @(
            '.blob.core.windows.net',
            '.blob.core.usgovcloudapi.net',
            '.blob.core.cloudapi.de',
            '.blob.core.chinacloudapi.cn'
        )
        $isStorageHost = $false
        foreach ($suffix in $storageSuffixes) {
            if ($Uri.DnsSafeHost.EndsWith($suffix, [StringComparison]::OrdinalIgnoreCase)) {
                $isStorageHost = $true
                break
            }
        }
        if (-not $isStorageHost) {
            throw "Managed identity downloads are restricted to recognized Azure Blob HTTPS endpoints. URI: $displayUri"
        }
        if (-not [string]::IsNullOrWhiteSpace($Uri.Query)) {
            throw "Do not combine a SAS query with managed identity authentication. URI: $displayUri"
        }
        $headers.Authorization = 'Bearer ' + (Get-StorageAccessToken)
        $headers.'x-ms-version' = '2023-11-03'
    }

    try {
        Invoke-WebRequest -Uri $Uri.AbsoluteUri -Headers $headers -OutFile $Destination `
            -TimeoutSec $DownloadTimeoutSeconds -UseBasicParsing
    }
    catch {
        throw "Failed to download $Description from '$displayUri'. The HTTPS request did not complete successfully."
    }
}

function Set-RestrictedDirectoryAcl {
    param([Parameter(Mandatory = $true)][string]$Path)

    $acl = New-Object Security.AccessControl.DirectorySecurity
    $acl.SetAccessRuleProtection($true, $false)
    $inheritance = [Security.AccessControl.InheritanceFlags]'ContainerInherit, ObjectInherit'
    $propagation = [Security.AccessControl.PropagationFlags]::None
    $allow = [Security.AccessControl.AccessControlType]::Allow
    foreach ($identityValue in @('S-1-5-18', 'S-1-5-32-544')) {
        $identity = New-Object Security.Principal.SecurityIdentifier($identityValue)
        $rule = New-Object Security.AccessControl.FileSystemAccessRule(
            $identity,
            [Security.AccessControl.FileSystemRights]::FullControl,
            $inheritance,
            $propagation,
            $allow
        )
        [void]$acl.AddAccessRule($rule)
    }
    Set-Acl -LiteralPath $Path -AclObject $acl
}

function Read-PackageHashManifest {
    param([Parameter(Mandatory = $true)][string]$Path)

    $result = @{}
    foreach ($line in Get-Content -LiteralPath $Path) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }
        if ($line -notmatch '^([A-Fa-f0-9]{64})  (.+)$') {
            throw "Invalid SHA256SUMS entry: '$line'."
        }
        $relativePath = $Matches[2].Replace('/', '\')
        if ($result.ContainsKey($relativePath)) {
            throw "Duplicate SHA256SUMS entry: '$relativePath'."
        }
        $result[$relativePath] = Get-NormalizedSha256 -Value $Matches[1]
    }
    return $result
}

function Get-VerifiedPackageHashes {
    param([Parameter(Mandatory = $true)][string]$Root)

    $hashManifestPath = Join-Path $Root 'SHA256SUMS.txt'
    $hashManifest = Read-PackageHashManifest -Path $hashManifestPath
    $hashedFiles = @($expectedArchiveFiles | Where-Object { $_ -ne 'SHA256SUMS.txt' })
    if ($hashManifest.Count -ne $hashedFiles.Count) {
        throw 'SHA256SUMS.txt does not describe the exact packaged payload.'
    }
    foreach ($relativePath in $hashedFiles) {
        if (-not $hashManifest.ContainsKey($relativePath)) {
            throw "SHA256SUMS.txt is missing '$relativePath'."
        }
        Assert-FileHash -Path (Join-Path $Root $relativePath) `
            -ExpectedSha256 $hashManifest[$relativePath] -Description "Packaged file '$relativePath'"
    }
    return $hashManifest
}

function Expand-ValidatedReleasePackage {
    param(
        [Parameter(Mandatory = $true)][string]$ZipPath,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $temporaryDestination = $Destination + '.extracting'
    if (Test-Path -LiteralPath $temporaryDestination) {
        Remove-Item -LiteralPath $temporaryDestination -Recurse -Force
    }
    [void](New-Item -ItemType Directory -Path $temporaryDestination)

    $archive = [IO.Compression.ZipFile]::OpenRead($ZipPath)
    try {
        $mappedEntries = @{}
        $archiveRoot = $null
        $usesArchiveRoot = $null
        foreach ($entry in $archive.Entries) {
            $entryName = $entry.FullName.Replace('\', '/')
            if ([string]::IsNullOrWhiteSpace($entry.Name)) {
                continue
            }
            if ($entryName.StartsWith('/') -or $entryName.Contains(':')) {
                throw "Release ZIP contains an unsafe rooted entry '$entryName'."
            }
            $segments = $entryName.Split('/')
            if ($segments -contains '..' -or $segments -contains '.') {
                throw "Release ZIP contains an unsafe traversal entry '$entryName'."
            }

            $relativePath = $entryName.Replace('/', '\')
            $entryUsesArchiveRoot = $false
            if ($expectedArchiveFiles -notcontains $relativePath) {
                $firstSeparator = $entryName.IndexOf('/')
                if ($firstSeparator -lt 1) {
                    throw "Release ZIP contains unexpected file '$entryName'."
                }
                $entryRoot = $entryName.Substring(0, $firstSeparator)
                $relativePath = $entryName.Substring($firstSeparator + 1).Replace('/', '\')
                $entryUsesArchiveRoot = $true
            }
            if ($expectedArchiveFiles -notcontains $relativePath) {
                throw "Release ZIP contains unexpected file '$entryName'."
            }
            if ($null -eq $usesArchiveRoot) {
                $usesArchiveRoot = $entryUsesArchiveRoot
                if ($entryUsesArchiveRoot) {
                    $archiveRoot = $entryRoot
                }
            }
            elseif ([bool]$usesArchiveRoot -ne $entryUsesArchiveRoot -or
                ($entryUsesArchiveRoot -and $archiveRoot -ne $entryRoot)) {
                throw 'Release ZIP files must be at the archive root or under one common top-level folder.'
            }
            if ($mappedEntries.ContainsKey($relativePath)) {
                throw "Release ZIP contains duplicate package path '$relativePath'."
            }
            $mappedEntries[$relativePath] = $entry
        }

        foreach ($expectedPath in $expectedArchiveFiles) {
            if (-not $mappedEntries.ContainsKey($expectedPath)) {
                throw "Release ZIP is missing required package file '$expectedPath'."
            }
        }
        if ($mappedEntries.Count -ne $expectedArchiveFiles.Count) {
            throw 'Release ZIP file count does not match the exact package contract.'
        }

        $destinationPrefix = [IO.Path]::GetFullPath($temporaryDestination)
        if (-not $destinationPrefix.EndsWith([IO.Path]::DirectorySeparatorChar)) {
            $destinationPrefix += [IO.Path]::DirectorySeparatorChar
        }
        foreach ($relativePath in $expectedArchiveFiles) {
            $targetPath = [IO.Path]::GetFullPath((Join-Path $temporaryDestination $relativePath))
            if (-not $targetPath.StartsWith($destinationPrefix, [StringComparison]::OrdinalIgnoreCase)) {
                throw "Release ZIP entry escapes the extraction root: '$relativePath'."
            }
            $targetDirectory = Split-Path -Parent $targetPath
            if (-not (Test-Path -LiteralPath $targetDirectory -PathType Container)) {
                [void](New-Item -ItemType Directory -Path $targetDirectory)
            }
            $inputStream = $mappedEntries[$relativePath].Open()
            try {
                $outputStream = [IO.File]::Open(
                    $targetPath,
                    [IO.FileMode]::CreateNew,
                    [IO.FileAccess]::Write,
                    [IO.FileShare]::None
                )
                try {
                    $inputStream.CopyTo($outputStream)
                }
                finally {
                    $outputStream.Dispose()
                }
            }
            finally {
                $inputStream.Dispose()
            }
        }
    }
    catch {
        if (Test-Path -LiteralPath $temporaryDestination) {
            Remove-Item -LiteralPath $temporaryDestination -Recurse -Force
        }
        throw
    }
    finally {
        $archive.Dispose()
    }

    try {
        $hashManifest = Get-VerifiedPackageHashes -Root $temporaryDestination

        if (Test-Path -LiteralPath $Destination) {
            throw "Durable package directory already exists without a reusable manifest: '$Destination'."
        }
        Move-Item -LiteralPath $temporaryDestination -Destination $Destination
        return $hashManifest
    }
    catch {
        if (Test-Path -LiteralPath $temporaryDestination) {
            Remove-Item -LiteralPath $temporaryDestination -Recurse -Force
        }
        throw
    }
}

function Stage-VerifiedMedia {
    param(
        [Parameter(Mandatory = $true)][string]$Description,
        [Parameter(Mandatory = $true)][string]$DestinationName,
        [uri]$Uri,
        [string]$SourcePath,
        [Parameter(Mandatory = $true)][string]$ExpectedSha256
    )

    $destination = Join-Path $mediaRoot $DestinationName
    if (Test-Path -LiteralPath $destination -PathType Leaf) {
        Assert-FileHash -Path $destination -ExpectedSha256 $ExpectedSha256 `
            -Description "Previously staged $Description"
        return @{
            Path = "Media\$DestinationName"
            Sha256 = Get-NormalizedSha256 -Value $ExpectedSha256
        }
    }
    if ($Uri) {
        $partialPath = $destination + '.downloading'
        if (Test-Path -LiteralPath $partialPath) {
            Remove-Item -LiteralPath $partialPath -Force
        }
        Save-HttpsFile -Uri $Uri -Destination $partialPath -Description $Description `
            -UseManagedIdentity:$UseManagedIdentityForDownloads
        Assert-FileHash -Path $partialPath -ExpectedSha256 $ExpectedSha256 -Description $Description
        Move-Item -LiteralPath $partialPath -Destination $destination
    }
    else {
        Assert-FileHash -Path $SourcePath -ExpectedSha256 $ExpectedSha256 -Description $Description
        Copy-Item -LiteralPath $SourcePath -Destination $destination
        Assert-FileHash -Path $destination -ExpectedSha256 $ExpectedSha256 -Description "Staged $Description"
    }

    return @{
        Path = "Media\$DestinationName"
        Sha256 = Get-NormalizedSha256 -Value $ExpectedSha256
    }
}

function Write-StagingManifest {
    param([Parameter(Mandatory = $true)][hashtable]$Value)

    $temporaryPath = $manifestPath + '.writing'
    $json = $Value | ConvertTo-Json -Depth 8
    [IO.File]::WriteAllText($temporaryPath, $json, (New-Object Text.UTF8Encoding($false)))
    Move-Item -LiteralPath $temporaryPath -Destination $manifestPath
}

function Get-SourceIdentity {
    param(
        [uri]$Uri,
        [string]$Path,
        [Parameter(Mandatory = $true)][string]$DefaultValue
    )

    if ($Uri) {
        return 'Uri:' + (Get-SafeUriDisplay -Uri $Uri)
    }
    if (-not [string]::IsNullOrWhiteSpace($Path)) {
        return 'Path:' + [IO.Path]::GetFullPath($Path)
    }
    return $DefaultValue
}

function Get-RequestedStagingContract {
    $languagePackMode = if ($LanguagePackCabUri -or $LanguagePackCabPath) {
        'Package'
    }
    elseif ($DownloadLanguagePack) {
        'MicrosoftDownload'
    }
    else {
        'AlreadyInstalled'
    }
    $lcuMode = if ($LcuPackageUri -or $LcuPackagePath) {
        'Package'
    }
    else {
        'WindowsUpdate'
    }

    return @{
        SchemaVersion = 1
        LanguageTag = $LanguageTag
        StagingRoot = [IO.Path]::GetFullPath($StagingRoot)
        WorkingDirectory = [IO.Path]::GetFullPath($WorkingDirectory)
        ReleasePackageSource = Get-SourceIdentity -Uri $ReleasePackageUri `
            -DefaultValue 'Missing'
        ReleasePackageSha256 = Get-NormalizedSha256 -Value $ReleasePackageSha256
        LanguagePackMode = $languagePackMode
        LanguagePackSource = Get-SourceIdentity -Uri $LanguagePackCabUri `
            -Path $LanguagePackCabPath -DefaultValue $languagePackMode
        LanguagePackSha256 = if ($languagePackMode -eq 'Package') {
            Get-NormalizedSha256 -Value $LanguagePackCabSha256
        }
        else {
            ''
        }
        LcuMode = $lcuMode
        LcuSource = Get-SourceIdentity -Uri $LcuPackageUri -Path $LcuPackagePath `
            -DefaultValue $lcuMode
        LcuSha256 = if ($lcuMode -eq 'Package') {
            Get-NormalizedSha256 -Value $LcuPackageSha256
        }
        else {
            ''
        }
        UseManagedIdentityForDownloads = [bool]$UseManagedIdentityForDownloads
        RequireRdp = [bool]$RequireRdp
        AllowRecognizedNonServicingPendingFileRenames = [bool]$AllowRecognizedNonServicingPendingFileRenames
        DownloadTimeoutSeconds = $DownloadTimeoutSeconds
    }
}

function Write-StagingContract {
    param([Parameter(Mandatory = $true)][hashtable]$Value)

    $temporaryPath = $contractPath + '.writing'
    $json = $Value | ConvertTo-Json -Depth 4
    [IO.File]::WriteAllText($temporaryPath, $json, (New-Object Text.UTF8Encoding($false)))
    Move-Item -LiteralPath $temporaryPath -Destination $contractPath
}

function Read-StagingContract {
    if (-not (Test-Path -LiteralPath $contractPath -PathType Leaf)) {
        throw "Durable CIT staging contract was not found at '$contractPath'."
    }
    $contract = Get-Content -LiteralPath $contractPath -Raw | ConvertFrom-Json
    if ([int]$contract.SchemaVersion -ne 1) {
        throw "Unsupported CIT staging contract schema '$($contract.SchemaVersion)'."
    }
    return $contract
}

function Assert-StagingContract {
    param(
        [Parameter(Mandatory = $true)]$Actual,
        [Parameter(Mandatory = $true)][hashtable]$Expected
    )

    foreach ($propertyName in @(
        'LanguageTag',
        'StagingRoot',
        'WorkingDirectory',
        'ReleasePackageSource',
        'ReleasePackageSha256',
        'LanguagePackMode',
        'LanguagePackSource',
        'LanguagePackSha256',
        'LcuMode',
        'LcuSource',
        'LcuSha256',
        'UseManagedIdentityForDownloads',
        'RequireRdp',
        'AllowRecognizedNonServicingPendingFileRenames',
        'DownloadTimeoutSeconds'
    )) {
        if ([string]$Actual.$propertyName -ne [string]$Expected[$propertyName]) {
            throw "The retry value for '$propertyName' does not match the durable staging contract."
        }
    }
}

function Read-AndVerifyStagingManifest {
    param([switch]$RequireOrchestratorState)

    $contract = Read-StagingContract
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        throw "Durable CIT staging manifest was not found at '$manifestPath'. Run StageInputs first."
    }
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    if ([int]$manifest.SchemaVersion -ne 1) {
        throw "Unsupported CIT staging manifest schema '$($manifest.SchemaVersion)'."
    }
    if ([string]$manifest.LanguageTag -ne $LanguageTag) {
        throw "Staged language '$($manifest.LanguageTag)' does not match requested '$LanguageTag'."
    }
    if ([string]$manifest.WorkingDirectory -ne $WorkingDirectory) {
        throw "Staged working directory '$($manifest.WorkingDirectory)' does not match requested '$WorkingDirectory'."
    }
    foreach ($propertyName in @(
        'LanguageTag',
        'WorkingDirectory',
        'ReleasePackageSource',
        'ReleasePackageSha256',
        'LanguagePackMode',
        'LanguagePackSource',
        'LcuMode',
        'LcuSource',
        'RequireRdp',
        'AllowRecognizedNonServicingPendingFileRenames'
    )) {
        if ([string]$manifest.$propertyName -ne [string]$contract.$propertyName) {
            throw "Staging manifest property '$propertyName' does not match the durable staging contract."
        }
    }

    Assert-FileHash -Path $archivePath -ExpectedSha256 ([string]$manifest.ReleasePackageSha256) `
        -Description 'Durable release ZIP'
    $seenPackageFiles = @{}
    foreach ($file in $manifest.PackageFiles) {
        $relativePath = [string]$file.Path
        if ($expectedArchiveFiles -notcontains $relativePath -or $relativePath -eq 'SHA256SUMS.txt') {
            throw "Staging manifest contains unexpected package file '$relativePath'."
        }
        if ($seenPackageFiles.ContainsKey($relativePath)) {
            throw "Staging manifest contains duplicate package file '$relativePath'."
        }
        $seenPackageFiles[$relativePath] = $true
        Assert-FileHash -Path (Join-Path $packageRoot $relativePath) `
            -ExpectedSha256 ([string]$file.Sha256) -Description "Durable package file '$relativePath'"
    }
    if (@($manifest.PackageFiles).Count -ne ($expectedArchiveFiles.Count - 1)) {
        throw 'Staging manifest package file count does not match the package contract.'
    }
    foreach ($media in @($manifest.MediaFiles)) {
        Assert-FileHash -Path (Join-Path $packageRoot ([string]$media.Path)) `
            -ExpectedSha256 ([string]$media.Sha256) -Description "Durable media '$($media.Path)'"
    }
    if ($RequireOrchestratorState -and
        -not (Test-Path -LiteralPath (Join-Path $WorkingDirectory 'state.json') -PathType Leaf)) {
        throw "The underlying AIB phase state is missing from '$WorkingDirectory'."
    }
    return $manifest
}

function Assert-InstallInputs {
    if (-not $ReleasePackageUri -or [string]::IsNullOrWhiteSpace($ReleasePackageSha256)) {
        throw 'StageInputs and InstallAndService require -ReleasePackageUri and -ReleasePackageSha256.'
    }

    $languageSources = @(
        @(
            [bool]$LanguagePackCabUri,
            -not [string]::IsNullOrWhiteSpace($LanguagePackCabPath),
            [bool]$DownloadLanguagePack
        ) | Where-Object { $_ }
    )
    if ($languageSources.Count -gt 1) {
        throw 'Specify only one language-pack source: URI, local path, or -DownloadLanguagePack.'
    }
    if (($LanguagePackCabUri -or $LanguagePackCabPath) -and
        [string]::IsNullOrWhiteSpace($LanguagePackCabSha256)) {
        throw 'A staged language-pack CAB requires -LanguagePackCabSha256.'
    }

    $lcuSources = @(
        @(
            [bool]$LcuPackageUri,
            -not [string]::IsNullOrWhiteSpace($LcuPackagePath),
            [bool]$UseWindowsUpdate
        ) | Where-Object { $_ }
    )
    if ($lcuSources.Count -ne 1) {
        throw 'Specify exactly one LCU source: URI, local path, or -UseWindowsUpdate.'
    }
    if (($LcuPackageUri -or $LcuPackagePath) -and [string]::IsNullOrWhiteSpace($LcuPackageSha256)) {
        throw 'A staged LCU package requires -LcuPackageSha256.'
    }
}

function Assert-RetryContract {
    param([Parameter(Mandatory = $true)]$Manifest)

    if ((Get-NormalizedSha256 -Value $ReleasePackageSha256) -ne
        (Get-NormalizedSha256 -Value ([string]$Manifest.ReleasePackageSha256))) {
        throw 'The retry release ZIP SHA-256 does not match the durable staging manifest.'
    }

    $requestedLanguagePackMode = if ($LanguagePackCabUri -or $LanguagePackCabPath) {
        'Package'
    }
    elseif ($DownloadLanguagePack) {
        'MicrosoftDownload'
    }
    else {
        'AlreadyInstalled'
    }
    if ($requestedLanguagePackMode -ne [string]$Manifest.LanguagePackMode) {
        throw "The retry language-pack mode '$requestedLanguagePackMode' does not match the staged mode '$($Manifest.LanguagePackMode)'."
    }

    $requestedLcuMode = if ($LcuPackageUri -or $LcuPackagePath) {
        'Package'
    }
    else {
        'WindowsUpdate'
    }
    if ($requestedLcuMode -ne [string]$Manifest.LcuMode) {
        throw "The retry LCU mode '$requestedLcuMode' does not match the staged mode '$($Manifest.LcuMode)'."
    }
    if ([bool]$RequireRdp -ne [bool]$Manifest.RequireRdp) {
        throw "The retry RequireRdp value '$([bool]$RequireRdp)' does not match the staged value '$([bool]$Manifest.RequireRdp)'."
    }
    if (
        [bool]$AllowRecognizedNonServicingPendingFileRenames -ne
        [bool]$Manifest.AllowRecognizedNonServicingPendingFileRenames
    ) {
        throw (
            'The retry AllowRecognizedNonServicingPendingFileRenames value does not match ' +
            'the staged value.'
        )
    }

    if ($requestedLanguagePackMode -eq 'Package') {
        $languageMedia = @($Manifest.MediaFiles | Where-Object { $_.Path -eq 'Media\LanguagePack.cab' })
        if ($languageMedia.Count -ne 1 -or
            (Get-NormalizedSha256 -Value $LanguagePackCabSha256) -ne
            (Get-NormalizedSha256 -Value ([string]$languageMedia[0].Sha256))) {
            throw 'The retry language-pack CAB SHA-256 does not match the durable staging manifest.'
        }
    }
    if ($requestedLcuMode -eq 'Package') {
        $lcuMedia = @($Manifest.MediaFiles | Where-Object { $_.Path -like 'Media\LcuPackage.*' })
        if ($lcuMedia.Count -ne 1 -or
            (Get-NormalizedSha256 -Value $LcuPackageSha256) -ne
            (Get-NormalizedSha256 -Value ([string]$lcuMedia[0].Sha256))) {
            throw 'The retry LCU package SHA-256 does not match the durable staging manifest.'
        }
    }
}

function Initialize-StagingRoot {
    if (-not (Test-Path -LiteralPath $StagingRoot -PathType Container)) {
        [void](New-Item -ItemType Directory -Path $StagingRoot)
    }
    Set-RestrictedDirectoryAcl -Path $StagingRoot
}

function Invoke-StageInputs {
    Assert-InstallInputs
    Initialize-StagingRoot

    $requestedContract = Get-RequestedStagingContract
    if (Test-Path -LiteralPath $contractPath -PathType Leaf) {
        $stagingContract = Read-StagingContract
        Assert-StagingContract -Actual $stagingContract -Expected $requestedContract
    }
    else {
        Write-StagingContract -Value $requestedContract
        $stagingContract = Read-StagingContract
        Assert-StagingContract -Actual $stagingContract -Expected $requestedContract
    }

    if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
        $stagingManifest = Read-AndVerifyStagingManifest
        Assert-RetryContract -Manifest $stagingManifest
        return $stagingManifest
    }

    if (Test-Path -LiteralPath $archivePath -PathType Leaf) {
        Assert-FileHash -Path $archivePath -ExpectedSha256 $ReleasePackageSha256 `
            -Description 'Previously downloaded release package'
    }
    else {
        $partialArchivePath = $archivePath + '.downloading'
        Save-HttpsFile -Uri $ReleasePackageUri -Destination $partialArchivePath `
            -Description 'release package' -UseManagedIdentity:$UseManagedIdentityForDownloads
        Assert-FileHash -Path $partialArchivePath -ExpectedSha256 $ReleasePackageSha256 `
            -Description 'Release package'
        Move-Item -LiteralPath $partialArchivePath -Destination $archivePath
    }

    if (Test-Path -LiteralPath $packageRoot -PathType Container) {
        $packageHashes = Get-VerifiedPackageHashes -Root $packageRoot
    }
    else {
        $packageHashes = Expand-ValidatedReleasePackage -ZipPath $archivePath -Destination $packageRoot
    }
    if (-not (Test-Path -LiteralPath $mediaRoot -PathType Container)) {
        [void](New-Item -ItemType Directory -Path $mediaRoot)
    }

    $mediaFiles = @()
    $languagePackMode = 'AlreadyInstalled'
    if ($LanguagePackCabUri -or $LanguagePackCabPath) {
        $languagePackMode = 'Package'
        $mediaFiles += Stage-VerifiedMedia -Description 'language-pack CAB' `
            -DestinationName 'LanguagePack.cab' -Uri $LanguagePackCabUri `
            -SourcePath $LanguagePackCabPath -ExpectedSha256 $LanguagePackCabSha256
    }
    elseif ($DownloadLanguagePack) {
        $languagePackMode = 'MicrosoftDownload'
    }

    $lcuMode = 'WindowsUpdate'
    if ($LcuPackageUri -or $LcuPackagePath) {
        $lcuMode = 'Package'
        $lcuExtension = if ($LcuPackageUri) {
            [IO.Path]::GetExtension($LcuPackageUri.AbsolutePath)
        }
        else {
            [IO.Path]::GetExtension($LcuPackagePath)
        }
        if ($lcuExtension -notin @('.msu', '.cab')) {
            throw "The staged LCU package must have a .msu or .cab extension, not '$lcuExtension'."
        }
        $mediaFiles += Stage-VerifiedMedia -Description 'LCU package' `
            -DestinationName ('LcuPackage' + $lcuExtension.ToLowerInvariant()) `
            -Uri $LcuPackageUri -SourcePath $LcuPackagePath -ExpectedSha256 $LcuPackageSha256
    }

    $packageFiles = @()
    foreach ($relativePath in ($expectedArchiveFiles | Where-Object { $_ -ne 'SHA256SUMS.txt' })) {
        $packageFiles += @{
            Path = $relativePath
            Sha256 = $packageHashes[$relativePath]
        }
    }
    $manifestValue = @{
        SchemaVersion = 1
        CreatedUtc = [DateTime]::UtcNow.ToString('o')
        LanguageTag = $LanguageTag
        WorkingDirectory = $WorkingDirectory
        ReleasePackageSource = Get-SourceIdentity -Uri $ReleasePackageUri `
            -DefaultValue 'Missing'
        ReleasePackageSha256 = Get-NormalizedSha256 -Value $ReleasePackageSha256
        LanguagePackMode = $languagePackMode
        LanguagePackSource = Get-SourceIdentity -Uri $LanguagePackCabUri `
            -Path $LanguagePackCabPath -DefaultValue $languagePackMode
        LcuMode = $lcuMode
        LcuSource = Get-SourceIdentity -Uri $LcuPackageUri -Path $LcuPackagePath `
            -DefaultValue $lcuMode
        RequireRdp = [bool]$RequireRdp
        AllowRecognizedNonServicingPendingFileRenames = [bool]$AllowRecognizedNonServicingPendingFileRenames
        PackageFiles = $packageFiles
        MediaFiles = $mediaFiles
    }
    Write-StagingManifest -Value $manifestValue
    return Read-AndVerifyStagingManifest
}

function Get-VerifiedStagingForInstall {
    Assert-InstallInputs
    $requestedContract = Get-RequestedStagingContract
    $stagingContract = Read-StagingContract
    Assert-StagingContract -Actual $stagingContract -Expected $requestedContract
    $stagingManifest = Read-AndVerifyStagingManifest
    Assert-RetryContract -Manifest $stagingManifest
    return $stagingManifest
}

function Get-StagedInstallArguments {
    param([Parameter(Mandatory = $true)]$Manifest)

    $arguments = @{
        Phase = 'InstallAndService'
        LanguageTag = $LanguageTag
        WorkingDirectory = $WorkingDirectory
        RequireRdp = [bool]$Manifest.RequireRdp
        AllowRecognizedNonServicingPendingFileRenames = (
            [bool]$Manifest.AllowRecognizedNonServicingPendingFileRenames
        )
    }
    if ([string]$Manifest.LanguagePackMode -eq 'Package') {
        $arguments.LanguagePackCabPath = Join-Path $packageRoot 'Media\LanguagePack.cab'
    }
    elseif ([string]$Manifest.LanguagePackMode -eq 'MicrosoftDownload') {
        $arguments.DownloadLanguagePack = $true
    }
    if ([string]$Manifest.LcuMode -eq 'Package') {
        $lcuMedia = @($Manifest.MediaFiles | Where-Object { $_.Path -like 'Media\LcuPackage.*' })
        if ($lcuMedia.Count -ne 1) {
            throw 'The durable staging manifest must contain exactly one LCU package.'
        }
        $arguments.LcuPackagePath = Join-Path $packageRoot ([string]$lcuMedia[0].Path)
    }
    else {
        $arguments.UseWindowsUpdate = $true
    }
    return $arguments
}

$stagingInputParameters = @(
    'ReleasePackageUri',
    'ReleasePackageSha256',
    'LanguagePackCabUri',
    'LanguagePackCabPath',
    'LanguagePackCabSha256',
    'DownloadLanguagePack',
    'LcuPackageUri',
    'LcuPackagePath',
    'LcuPackageSha256',
    'UseWindowsUpdate',
    'UseManagedIdentityForDownloads',
    'RequireRdp',
    'AllowRecognizedNonServicingPendingFileRenames',
    'DownloadTimeoutSeconds'
)

if ($Phase -in @('ApplyMachineLanguage', 'Validate')) {
    foreach ($parameterName in $stagingInputParameters) {
        if ($PSBoundParameters.ContainsKey($parameterName)) {
            throw "CIT phase '$Phase' does not accept staging parameter '-$parameterName'."
        }
    }

    $stagingManifest = Read-AndVerifyStagingManifest -RequireOrchestratorState
    $wrapperPath = Join-Path $packageRoot 'Invoke-Windows10MachineLanguageAib.ps1'
    & $wrapperPath -Phase $Phase -LanguageTag $LanguageTag -WorkingDirectory $WorkingDirectory
    return
}

if ($Phase -eq 'StageInputs') {
    [void](Invoke-StageInputs)
    return
}

$stagingManifest = Get-VerifiedStagingForInstall
$wrapperPath = Join-Path $packageRoot 'Invoke-Windows10MachineLanguageAib.ps1'
$wrapperArguments = Get-StagedInstallArguments -Manifest $stagingManifest
& $wrapperPath @wrapperArguments
