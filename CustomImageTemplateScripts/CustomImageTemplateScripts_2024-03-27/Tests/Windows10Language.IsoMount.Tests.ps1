[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$publicationRoot = Split-Path -Parent $PSScriptRoot
$orchestratorPath = Join-Path $publicationRoot 'Set-Windows10MachineLanguage.ps1'
$tokens = $null
$parseErrors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile(
    $orchestratorPath,
    [ref]$tokens,
    [ref]$parseErrors
)
if ($parseErrors.Count -gt 0) {
    throw "Cannot load ISO regression targets: $($parseErrors -join '; ')"
}

foreach ($functionName in @(
    'Get-IsoVolumeIdentity',
    'Get-AssociatedIsoVolumes',
    'Get-UnusedTemporaryDriveLetter',
    'Get-LanguagePacksFromMicrosoft'
)) {
    $functionAst = $ast.Find({
        param($node)
        $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
        $node.Name -eq $functionName
    }, $true)
    if ($null -eq $functionAst) {
        throw "Required function '$functionName' was not found."
    }
    . ([scriptblock]::Create($functionAst.Extent.Text))
}

$script:passed = 0
$script:failures = New-Object System.Collections.Generic.List[string]
$script:WorkingDirectory = 'C:\work'
$script:ExpectedIsoLength = 6000000000

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if ($Condition) {
        $script:passed++
    }
    else {
        $script:failures.Add($Message)
    }
}

function New-TestVolume {
    param(
        [string]$DriveLetter,
        [string]$DriveType = 'CD-ROM',
        [string]$FileSystem = 'UDF',
        [string]$UniqueId = 'ISO-VOLUME-1'
    )

    [pscustomobject]@{
        Kind = 'Volume'
        DriveLetter = $DriveLetter
        DriveType = $DriveType
        FileSystem = $FileSystem
        UniqueId = $UniqueId
        ObjectId = "Object-$UniqueId"
        Path = "\\?\Volume{$UniqueId}\"
    }
}

function Write-Operation {
    param([Parameter(Mandatory = $true)][string]$Message)
    $script:Logs.Add($Message)
}

function Get-Date {
    $script:ClockTick++
    return ([datetime]'2026-09-28T00:00:00Z').AddSeconds($script:ClockTick * 10)
}

function Get-PSDrive {
    [CmdletBinding()]
    param([string]$Name, [string]$PSProvider)
    if ($PSBoundParameters.ContainsKey('Name')) {
        return [pscustomobject]@{ Name = $Name; Free = 20GB }
    }
    return [pscustomobject]@{ Name = 'C' }
}

function Test-Path {
    param([string]$LiteralPath, [string]$PathType)
    return $LiteralPath -like '*.iso'
}

function Get-Item {
    param([string]$LiteralPath)
    if ($LiteralPath -like '*.iso') {
        return [pscustomobject]@{ Length = $script:ExpectedIsoLength }
    }
    return [pscustomobject]@{ Length = 2MB }
}

function Mount-DiskImage {
    [CmdletBinding()]
    param([string]$ImagePath, [switch]$PassThru)
    $script:MountCount++
    return [pscustomobject]@{ Kind = 'DiskImage'; ImagePath = $ImagePath }
}

function Get-DiskImage {
    [CmdletBinding()]
    param([string]$ImagePath)
    return [pscustomobject]@{ Kind = 'DiskImage'; ImagePath = $ImagePath }
}

function Get-Disk {
    param(
        [Parameter(ValueFromPipeline = $true)]$InputObject
    )
    process {
        if ($script:ScenarioName -eq 'AmbiguousDisk') {
            return @(
                [pscustomobject]@{ Kind = 'Disk'; Number = 7 },
                [pscustomobject]@{ Kind = 'Disk'; Number = 8 }
            )
        }
        return [pscustomobject]@{ Kind = 'Disk'; Number = 7 }
    }
}

function Get-Partition {
    [CmdletBinding()]
    param([int]$DiskNumber)
    if ($script:ScenarioName -eq 'AmbiguousPartition') {
        return @(
            [pscustomobject]@{ Kind = 'Partition'; DiskNumber = $DiskNumber; PartitionNumber = 1 },
            [pscustomobject]@{ Kind = 'Partition'; DiskNumber = $DiskNumber; PartitionNumber = 2 }
        )
    }
    return [pscustomobject]@{
        Kind = 'Partition'
        DiskNumber = $DiskNumber
        PartitionNumber = 1
    }
}

function Get-Volume {
    param(
        [Parameter(ValueFromPipeline = $true)]$InputObject
    )
    process {
        if (-not $PSBoundParameters.ContainsKey('InputObject')) {
            $script:AllocationCallCount++
            $letters = @('C')
            if ($script:ScenarioName -eq 'NoSafeLetter') {
                $letters = @(
                    foreach ($codePoint in ([int][char]'D')..([int][char]'Z')) {
                        [string][char]$codePoint
                    }
                )
            }
            elseif (
                $script:ScenarioName -eq 'ConcurrentClaim' -and
                $script:AllocationCallCount -ge 2
            ) {
                $letters += 'Z'
            }
            return @(
                foreach ($letter in $letters) {
                    New-TestVolume `
                        -DriveLetter $letter `
                        -DriveType 'Fixed' `
                        -FileSystem 'NTFS' `
                        -UniqueId "ALLOC-$letter"
                }
            )
        }

        if ($InputObject.Kind -eq 'Partition') {
            if ($script:ScenarioName -eq 'PartitionDoesNotOwnVolume') {
                return New-TestVolume -DriveLetter $null -UniqueId 'OTHER-VOLUME'
            }
            return New-TestVolume -DriveLetter $null
        }

        $script:AssociatedCallCount++
        switch ($script:ScenarioName) {
            'Timeout' { return @() }
            'AmbiguousVolume' {
                return @(
                    (New-TestVolume -DriveLetter 'R' -UniqueId 'ISO-VOLUME-1'),
                    (New-TestVolume -DriveLetter 'S' -UniqueId 'ISO-VOLUME-2')
                )
            }
            'UnexpectedMedia' {
                return New-TestVolume -DriveLetter 'R' -DriveType 'Fixed'
            }
            'UnexpectedFileSystem' {
                return New-TestVolume -DriveLetter 'R' -FileSystem 'NTFS'
            }
            'DelayedLetter' {
                if ($script:AssociatedCallCount -eq 1) {
                    return New-TestVolume -DriveLetter $null
                }
                return New-TestVolume -DriveLetter 'R'
            }
            default {
                if ($null -ne $script:AddedDriveLetter) {
                    if ($script:ScenarioName -eq 'OwnershipVerificationFailure') {
                        return New-TestVolume `
                            -DriveLetter $script:AddedDriveLetter `
                            -UniqueId 'OTHER-VOLUME'
                    }
                    return New-TestVolume -DriveLetter $script:AddedDriveLetter
                }
                if ($script:ScenarioName -eq 'ImmediateLetter') {
                    return New-TestVolume -DriveLetter 'R'
                }
                return New-TestVolume -DriveLetter $null
            }
        }
    }
}

function Start-Sleep {
    param([int]$Seconds)
}

function Add-PartitionAccessPath {
    [CmdletBinding()]
    param(
        [int]$DiskNumber,
        [int]$PartitionNumber,
        [string]$AccessPath
    )
    $script:AddCount++
    if ($script:ScenarioName -eq 'AddFailure') {
        throw 'simulated add failure'
    }
    $script:AddedDriveLetter = $AccessPath.Substring(0, 1)
}

function Remove-PartitionAccessPath {
    [CmdletBinding()]
    param(
        [int]$DiskNumber,
        [int]$PartitionNumber,
        [string]$AccessPath
    )
    $script:RemoveAccessCount++
    if ($script:ScenarioName -in @('RemoveFailure', 'CombinedFailure')) {
        throw 'simulated remove failure'
    }
}

function Get-ChildItem {
    [CmdletBinding()]
    param(
        [string]$LiteralPath,
        [string]$Filter,
        [switch]$File,
        [switch]$Recurse
    )
    $script:SearchRoots.Add($LiteralPath)
    if ($script:ScenarioName -in @('CabMissing', 'CombinedFailure')) {
        return $null
    }
    return [pscustomobject]@{
        FullName = "$LiteralPath$Filter"
        Name = $Filter
    }
}

function Copy-Item {
    param([string]$LiteralPath, [string]$Destination, [switch]$Force)
}

function Dismount-DiskImage {
    [CmdletBinding()]
    param([string]$ImagePath)
    $script:DismountCount++
    if ($script:ScenarioName -eq 'DismountFailure') {
        throw 'simulated dismount failure'
    }
}

function Remove-Item {
    [CmdletBinding()]
    param([string]$LiteralPath, [switch]$Force)
    if ($LiteralPath -like '*.iso') {
        $script:DeleteCount++
        if ($script:ScenarioName -eq 'DeleteFailure') {
            throw 'simulated delete failure'
        }
    }
}

function Invoke-IsoScenario {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [string[]]$LanguageTags = @('fr-FR')
    )

    $script:ScenarioName = $Name
    $script:MountCount = 0
    $script:AssociatedCallCount = 0
    $script:AllocationCallCount = 0
    $script:AddCount = 0
    $script:RemoveAccessCount = 0
    $script:DismountCount = 0
    $script:DeleteCount = 0
    $script:SearchRoots = New-Object System.Collections.Generic.List[string]
    $script:Logs = New-Object System.Collections.Generic.List[string]
    $script:AddedDriveLetter = $null
    $script:ClockTick = 0

    $errorText = $null
    $result = $null
    try {
        $result = Get-LanguagePacksFromMicrosoft `
            -TargetLanguageTags $LanguageTags `
            -IsoUri 'https://software-download.microsoft.com/test.iso' `
            -ExpectedIsoLength $script:ExpectedIsoLength
    }
    catch {
        $errorText = $_.Exception.Message
    }

    [pscustomobject]@{
        Name = $Name
        Error = $errorText
        Result = $result
        MountCount = $script:MountCount
        AssociatedCallCount = $script:AssociatedCallCount
        AddCount = $script:AddCount
        RemoveAccessCount = $script:RemoveAccessCount
        DismountCount = $script:DismountCount
        DeleteCount = $script:DeleteCount
        SearchRoots = @($script:SearchRoots)
        Logs = @($script:Logs)
    }
}

$immediate = Invoke-IsoScenario -Name 'ImmediateLetter'
Assert-True ($null -eq $immediate.Error) 'Immediate existing drive-letter path failed.'
Assert-True ($immediate.AddCount -eq 0) 'Immediate existing path added a temporary letter.'
Assert-True ($immediate.RemoveAccessCount -eq 0) 'Immediate existing path removed a pre-existing path.'
Assert-True ($immediate.SearchRoots -contains 'R:\') 'Immediate existing path did not search only R:\.'

$delayed = Invoke-IsoScenario -Name 'DelayedLetter'
Assert-True ($null -eq $delayed.Error) 'Delayed automatic drive-letter path failed.'
Assert-True ($delayed.AssociatedCallCount -ge 2) 'Delayed drive-letter path was not polled.'
Assert-True ($delayed.AddCount -eq 0) 'Delayed automatic letter was replaced unnecessarily.'

$recovered = Invoke-IsoScenario -Name 'UnletteredRecovery'
Assert-True ($null -eq $recovered.Error) 'Safe unlettered-volume recovery failed.'
Assert-True ($recovered.AddCount -eq 1) 'Safe recovery did not add exactly one access path.'
Assert-True ($recovered.RemoveAccessCount -eq 1) 'Safe recovery did not remove its access path.'
Assert-True ($recovered.SearchRoots -contains 'Z:\') 'Safe recovery did not search only its verified root.'
Assert-True (
    ($recovered.Logs -join "`n") -match 'Observed mounted.+ISO volume' -and
    ($recovered.Logs -join "`n") -match 'Added temporary access path' -and
    ($recovered.Logs -join "`n") -match 'Verified temporary access path' -and
    ($recovered.Logs -join "`n") -match 'Removed temporary ISO access path'
) 'Safe recovery diagnostic logging is incomplete.'

$multiple = Invoke-IsoScenario `
    -Name 'UnletteredRecovery' `
    -LanguageTags @('fr-FR', 'de-DE')
Assert-True ($null -eq $multiple.Error) 'Multiple-language extraction failed.'
Assert-True ($multiple.MountCount -eq 1) 'Multiple languages mounted the ISO more than once.'
Assert-True ($multiple.SearchRoots.Count -eq 2) 'Multiple languages did not share one mounted root.'

$failureCases = @(
    @{ Name = 'Timeout'; Pattern = 'within 30 seconds' },
    @{ Name = 'AmbiguousVolume'; Pattern = 'exactly one is required' },
    @{ Name = 'AmbiguousDisk'; Pattern = 'maps to 2 disks' },
    @{ Name = 'AmbiguousPartition'; Pattern = 'maps to 2 partitions' },
    @{ Name = 'PartitionDoesNotOwnVolume'; Pattern = 'maps to 0 partitions' },
    @{ Name = 'UnexpectedMedia'; Pattern = "DriveType='Fixed'" },
    @{ Name = 'UnexpectedFileSystem'; Pattern = "FileSystem='NTFS'" },
    @{ Name = 'NoSafeLetter'; Pattern = 'No unused drive letter' },
    @{ Name = 'ConcurrentClaim'; Pattern = 'claimed concurrently' },
    @{ Name = 'AddFailure'; Pattern = 'simulated add failure' },
    @{ Name = 'OwnershipVerificationFailure'; Pattern = 'not verified as owned' },
    @{ Name = 'RemoveFailure'; Pattern = 'ISO cleanup failed' },
    @{ Name = 'DismountFailure'; Pattern = 'dismount' },
    @{ Name = 'DeleteFailure'; Pattern = 'delete' },
    @{ Name = 'CombinedFailure'; Pattern = 'Cleanup also failed' }
)
foreach ($failureCase in $failureCases) {
    $failure = Invoke-IsoScenario -Name $failureCase.Name
    Assert-True (
        -not [string]::IsNullOrWhiteSpace($failure.Error)
    ) "Scenario '$($failureCase.Name)' did not fail closed."
    Assert-True (
        $failure.Error -match $failureCase.Pattern
    ) "Scenario '$($failureCase.Name)' did not preserve the expected diagnostic."
    Assert-True (
        $failure.DismountCount -eq 1 -and $failure.DeleteCount -eq 1
    ) "Scenario '$($failureCase.Name)' did not attempt exact ISO cleanup."
}

$addFailure = Invoke-IsoScenario -Name 'AddFailure'
Assert-True (
    $addFailure.RemoveAccessCount -eq 0
) 'An access path was removed even though this invocation did not create it.'

$combined = Invoke-IsoScenario -Name 'CombinedFailure'
Assert-True (
    $combined.Error -match 'does not contain' -and
    $combined.Error -match 'simulated remove failure'
) 'Combined primary and cleanup errors were not both preserved.'

if ($script:failures.Count -gt 0) {
    throw "ISO mount regression validation failed ($($script:failures.Count) failure(s), $script:passed passed):`n - $($script:failures -join "`n - ")"
}

Write-Host "ISO mount regression validation passed: $script:passed assertions."
