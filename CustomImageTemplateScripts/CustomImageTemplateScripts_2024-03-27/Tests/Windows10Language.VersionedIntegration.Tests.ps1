[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$publicationRoot = Split-Path -Parent $PSScriptRoot
$installEntry = Join-Path $publicationRoot 'InstallLanguagePacks.ps1'
$defaultEntry = Join-Path $publicationRoot 'SetDefaultLang.ps1'
$removedEntry = Join-Path $publicationRoot 'SetDefaultLangWin10.ps1'
$orchestrator = Join-Path $publicationRoot 'Set-Windows10MachineLanguage.ps1'
$copyHelper = Join-Path $publicationRoot 'Copy-UserInternationalSettingsToSystemCompat.ps1'
$healthCheck = Join-Path $publicationRoot 'Test-Windows10MachineLanguageHealth.ps1'
$servicingGuide = Join-Path $publicationRoot 'Windows10-Language-Servicing.md'
$removedProductionFiles = @(
    'Aib-Customizers.TwoRestartCandidate.example.json',
    'Invoke-Windows10MachineLanguageAib.ps1',
    'Invoke-Windows10MachineLanguageCit.ps1'
)
$failures = New-Object System.Collections.Generic.List[string]
$passed = 0

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

function Get-NormalizedSha256 {
    param([Parameter(Mandatory = $true)][string]$Text)

    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString(
            $sha.ComputeHash(
                [Text.Encoding]::UTF8.GetBytes($Text.Replace("`r`n", "`n"))
            )
        )).Replace('-', '')
    }
    finally {
        $sha.Dispose()
    }
}

foreach ($path in @(
    $installEntry,
    $defaultEntry,
    $orchestrator,
    $copyHelper,
    $healthCheck,
    $servicingGuide
)) {
    Assert-True (Test-Path -LiteralPath $path -PathType Leaf) "Required file is missing: $path"
}
Assert-True (-not (Test-Path -LiteralPath $removedEntry)) 'The separate Windows 10 entry point still exists.'
foreach ($fileName in $removedProductionFiles) {
    Assert-True (
        -not (Test-Path -LiteralPath (Join-Path $publicationRoot $fileName))
    ) "Removed production phase file still exists: $fileName"
}

foreach ($path in @($installEntry, $defaultEntry, $orchestrator, $copyHelper, $healthCheck)) {
    $tokens = $null
    $parseErrors = $null
    [void][Management.Automation.Language.Parser]::ParseFile(
        $path,
        [ref]$tokens,
        [ref]$parseErrors
    )
    Assert-True ($parseErrors.Count -eq 0) "PowerShell parse errors in $path`: $($parseErrors -join '; ')"
}

$installText = [IO.File]::ReadAllText($installEntry)
$defaultText = [IO.File]::ReadAllText($defaultEntry)
$orchestratorText = [IO.File]::ReadAllText($orchestrator)
$guideText = [IO.File]::ReadAllText($servicingGuide)

$installBodyStart = $installText.IndexOf('function Install-LanguagePack', [StringComparison]::Ordinal)
Assert-True ($installBodyStart -ge 0) 'The Windows 11 InstallLanguagePacks body marker is missing.'
if ($installBodyStart -ge 0) {
    Assert-True (
        (Get-NormalizedSha256 $installText.Substring($installBodyStart)) -eq
        '89260239FEAE261A2D17F9B02E0C8A9B19A70F80A58A83D75511AFED8BA4C16A'
    ) 'The pre-existing Windows 11 InstallLanguagePacks body changed.'
}

$defaultBodyStart = $defaultText.IndexOf('function Get-RegionInfo', [StringComparison]::Ordinal)
Assert-True ($defaultBodyStart -ge 0) 'The Windows 11 SetDefaultLang body marker is missing.'
if ($defaultBodyStart -ge 0) {
    Assert-True (
        (Get-NormalizedSha256 $defaultText.Substring($defaultBodyStart)) -eq
        'F8F81A3789D77CE0DBCB5C72EDD5914E4FEBE426F2149963452DE919CFCC1D9A'
    ) 'The pre-existing Windows 11 SetDefaultLang body changed.'
}

Assert-True (
    $installText -match '\$osBuildForDispatch\s+-in\s+@\(19044,\s*19045\)'
) 'InstallLanguagePacks Windows 10 dispatch is not restricted to builds 19044 and 19045.'
Assert-True (
    $defaultText -match '\$osBuildForDispatch\s+-in\s+@\(19044,\s*19045\)'
) 'SetDefaultLang Windows 10 dispatch is not restricted to builds 19044 and 19045.'
Assert-True (
    $installText -match '&\s+\$windows10OrchestratorPath[\s\S]+-AibPhase InstallAndService[\s\S]+-AllowRecognizedNonServicingPendingFileRenames[\s\S]+return'
) 'InstallLanguagePacks does not invoke the approved install phase with the narrow PFRO opt-in and return.'
Assert-True (
    $defaultText -match '&\s+\$windows10OrchestratorPath[\s\S]+-Resume[\s\S]+-AibPhase ApplyMachineLanguage[\s\S]+-ExpectedLanguageTag \$languageTag[\s\S]+return'
) 'SetDefaultLang does not invoke the persisted apply phase and return.'

Assert-True (
    $installText -match '\[System\.String\[\]\]\$LanguageList'
) 'The existing InstallLanguagePacks LanguageList parameter contract changed.'
Assert-True (
    $defaultText -match '\[string\]\$Language\s*\r?\n\)'
) 'The existing SetDefaultLang Language parameter contract changed.'
Assert-True (
    $installText -match 'List\[string\][\s\S]+HashSet\[string\][\s\S]+foreach \(\$language in \$LanguageList\)[\s\S]+\$seenLanguageTags\.Add\(\$languageTag\)'
) 'Windows 10 language mapping is not deterministic or does not de-duplicate while retaining request order.'
Assert-True (
    $orchestratorText -match "\[Parameter\(Mandatory = \`$true, ParameterSetName = 'OnlineMultiLanguage'\)\][\s\S]+\[string\[\]\]\`$LanguageTags"
) 'The orchestrator multi-language online parameter set is missing.'
Assert-True (
    $orchestratorText -match 'Get-LanguagePacksFromMicrosoft[\s\S]+foreach \(\$targetLanguageTag in \$TargetLanguageTags\)'
) 'The official language media is not shared across all requested languages.'
Assert-True (
    $orchestratorText -match 'foreach \(\$targetLanguageTag in \$targetLanguageTags\) \{[\s\S]+?Install-TargetLanguage'
) 'InstallAndService does not install every requested language deterministically.'
Assert-True (
    $orchestratorText -match 'Get-WindowsUpdateLcuSelection[\s\S]+Cumulative Update for Windows 10[\s\S]+-notmatch ''\\\.NET\|Preview'''
) 'The approved non-preview Windows Update LCU selection path changed.'
Assert-True (
    $orchestratorText -match 'foreach \(\$targetLanguageTag in \$targetLanguageTags\) \{\s*Assert-LanguageServicedToCurrentUbr'
) 'Language/UBR parity is not checked for every requested language.'
Assert-True (
    $orchestratorText -match 'Get-DiskImage -ImagePath \$ImagePath[\s\S]+Get-Volume'
) 'Language media discovery is not scoped to the exact mounted ISO association.'
Assert-True (
    $orchestratorText -match 'AddSeconds\(30\)[\s\S]+Start-Sleep -Seconds 1'
) 'Language media discovery does not use bounded polling.'
Assert-True (
    $orchestratorText -match "\`$candidateDriveType -ne 'CD-ROM'" -and
    $orchestratorText -match "\`$candidateFileSystem -notin @\('UDF', 'CDFS'\)"
) 'Language media discovery does not require the expected optical filesystem.'
Assert-True (
    $orchestratorText -match 'Get-Volume -ErrorAction Stop[\s\S]+Get-PSDrive -PSProvider FileSystem'
) 'Temporary drive-letter allocation does not exclude both volume and filesystem allocations.'
Assert-True (
    $orchestratorText -match "foreach \(\`$codePoint in \[int\]\[char\]'Z'\.\.\[int\]\[char\]'D'\)"
) 'Temporary drive-letter allocation is not restricted to Z through D.'
Assert-True (
    $orchestratorText -match 'Add-PartitionAccessPath[\s\S]+Verified temporary access path'
) 'Temporary ISO access-path assignment is not ownership-verified.'
Assert-True (
    $orchestratorText -match 'Remove-PartitionAccessPath[\s\S]+Dismount-DiskImage -ImagePath \$isoPath[\s\S]+Remove-Item -LiteralPath \$isoPath'
) 'Temporary access path, exact dismount, and ISO deletion cleanup are incomplete.'
Assert-True (
    $orchestratorText -match 'Language-pack ISO processing failed:[\s\S]+Cleanup also failed:'
) 'Primary and cleanup ISO failures are not preserved together.'
Assert-True (
    $orchestratorText -notmatch 'Set-StorageSetting|automount|mountvol'
) 'Language media recovery changes global automount behavior.'
Assert-True (
    $orchestratorText -match 'DeferLanguageSelection[\s\S]+Requested default language[\s\S]+Set-CurrentUserLanguage'
) 'Default language selection is not deferred to SetDefaultLang.'
Assert-True (
    $installText -notmatch '-AibPhase\s+Validate' -and
    $defaultText -notmatch '-AibPhase\s+Validate'
) 'A production entry still invokes the removed Validate phase.'

$orchestratorTokens = $null
$orchestratorParseErrors = $null
$orchestratorAst = [Management.Automation.Language.Parser]::ParseFile(
    $orchestrator,
    [ref]$orchestratorTokens,
    [ref]$orchestratorParseErrors
)
$stateLanguageTagsAst = $orchestratorAst.Find({
    param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
    $node.Name -eq 'Get-StateLanguageTags'
}, $true)
$stateLanguagePackPathAst = $orchestratorAst.Find({
    param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
    $node.Name -eq 'Get-StateLanguagePackPath'
}, $true)
$initialPhaseAst = $orchestratorAst.Find({
    param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
    $node.Name -eq 'Invoke-InitialPhase'
}, $true)
$installAndServicePhaseAst = $orchestratorAst.Find({
    param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
    $node.Name -eq 'Invoke-InstallAndServicePhase'
}, $true)
$servicingReadyStateAst = $orchestratorAst.Find({
    param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
    $node.Name -eq 'Test-ServicingReadyState'
}, $true)
$windowsUpdateFailureDispositionAst = $orchestratorAst.Find({
    param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
    $node.Name -eq 'Get-WindowsUpdateInstallFailureDisposition'
}, $true)
Assert-True ($null -ne $stateLanguageTagsAst) 'Get-StateLanguageTags is missing.'
Assert-True ($null -ne $stateLanguagePackPathAst) 'Get-StateLanguagePackPath is missing.'
Assert-True ($null -ne $initialPhaseAst) 'Invoke-InitialPhase is missing.'
Assert-True ($null -ne $installAndServicePhaseAst) 'Invoke-InstallAndServicePhase is missing.'
Assert-True ($null -ne $servicingReadyStateAst) 'Test-ServicingReadyState is missing.'
Assert-True ($null -ne $windowsUpdateFailureDispositionAst) 'Get-WindowsUpdateInstallFailureDisposition is missing.'
if ($null -ne $stateLanguageTagsAst -and $null -ne $stateLanguagePackPathAst) {
    . ([scriptblock]::Create($stateLanguageTagsAst.Extent.Text))
    . ([scriptblock]::Create($stateLanguagePackPathAst.Extent.Text))

    $liveState = [pscustomobject]@{
        LanguageTags = @('fr-FR', 'de-DE')
        LanguagePackCabPaths = @{
            'fr-FR' = 'C:\staged\fr-FR.cab'
            'de-DE' = 'C:\staged\de-DE.cab'
        }
    }
    Assert-True (
        (@(Get-StateLanguageTags -State $liveState) -join '|') -ceq 'fr-FR|de-DE'
    ) 'Live multi-language state does not preserve deterministic order.'
    Assert-True (
        (Get-StateLanguagePackPath -State $liveState -TargetLanguageTag 'de-DE') -eq
        'C:\staged\de-DE.cab'
    ) 'Live multi-language state does not resolve a staged CAB.'

    $persistedState = $liveState | ConvertTo-Json -Depth 4 | ConvertFrom-Json
    Assert-True (
        (@(Get-StateLanguageTags -State $persistedState) -join '|') -ceq 'fr-FR|de-DE'
    ) 'Persisted multi-language state does not preserve deterministic order.'
    Assert-True (
        (Get-StateLanguagePackPath -State $persistedState -TargetLanguageTag 'fr-FR') -eq
        'C:\staged\fr-FR.cab'
    ) 'Persisted multi-language state does not resolve a staged CAB.'
}

if ($null -ne $initialPhaseAst) {
    Assert-True (
        $initialPhaseAst.Extent.Text -notmatch 'Get-WindowsUpdateLcuSelection'
    ) 'The initial phase still queries Windows Update before language installation.'
}
if ($null -ne $servicingReadyStateAst) {
    . ([scriptblock]::Create($servicingReadyStateAst.Extent.Text))
    Assert-True (
        -not (Test-ServicingReadyState `
            -PendingReasons @() `
            -ActiveInstallerNames @('TiWorker') `
            -AllowPendingRestart)
    ) 'AllowPendingRestart incorrectly bypasses an active servicing installer.'
    Assert-True (
        (Test-ServicingReadyState `
            -PendingReasons @('CBS RebootPending') `
            -ActiveInstallerNames @() `
            -AllowPendingRestart)
    ) 'AllowPendingRestart no longer permits the planned pre-LCU restart state.'
    Assert-True (
        -not (Test-ServicingReadyState `
            -PendingReasons @('CBS RebootPending') `
            -ActiveInstallerNames @())
    ) 'Normal servicing readiness no longer fails closed for a pending restart.'
}
if ($null -ne $windowsUpdateFailureDispositionAst) {
    . ([scriptblock]::Create($windowsUpdateFailureDispositionAst.Extent.Text))
    Assert-True (
        (Get-WindowsUpdateInstallFailureDisposition `
            -HResult -2145124330 `
            -PendingReasons @()) -eq 'TransientBusy'
    ) '0x80240016 without reboot signals is not classified as a transient servicing race.'
    Assert-True (
        (Get-WindowsUpdateInstallFailureDisposition `
            -HResult -2145124330 `
            -PendingReasons @('Windows Update RebootRequired')) -eq 'PendingRestart'
    ) '0x80240016 with a reboot signal is not classified as a mandatory restart.'
    Assert-True (
        (Get-WindowsUpdateInstallFailureDisposition `
            -HResult -2145124329 `
            -PendingReasons @()) -eq 'Fatal'
    ) 'An unrelated Windows Update error is incorrectly retryable.'
}
if ($null -ne $installAndServicePhaseAst) {
    $installAndServiceText = $installAndServicePhaseAst.Extent.Text
    $installLanguageIndex = $installAndServiceText.IndexOf(
        'Install-TargetLanguage',
        [StringComparison]::Ordinal
    )
    $selectLcuIndex = $installAndServiceText.IndexOf(
        'Get-WindowsUpdateLcuSelection',
        [StringComparison]::Ordinal
    )
    $installLcuIndex = $installAndServiceText.IndexOf(
        'Install-LcuFromWindowsUpdate',
        [StringComparison]::Ordinal
    )
    Assert-True (
        $installLanguageIndex -ge 0 -and
        $selectLcuIndex -gt $installLanguageIndex -and
        $installLcuIndex -gt $selectLcuIndex
    ) 'Windows Update LCU selection/install does not occur after requested language installation.'
    Assert-True (
        $installAndServiceText -match
        'if \(\$null -eq \$windowsUpdateSelection\.Update\) \{\s*throw \('
    ) 'The post-language Windows Update path no longer fails closed when no LCU is offered.'
}

Assert-True ($orchestratorText -match 'AllowRecognizedNonServicingPendingFileRenames') 'The PFRO opt-in is missing.'
Assert-True ($orchestratorText -match 'Test-RecognizedNonServicingPendingFileRenamePair') 'The PFRO allowlist classifier is missing.'
Assert-True ($orchestratorText -match 'Operations\.Count % 2') 'Malformed PFRO pair counts are not fail-closed.'
Assert-True ($orchestratorText -match 'servicing|winsxs|cbstemp|softwaredistribution') 'Servicing-related PFRO paths are not explicitly classified.'
Assert-True ($orchestratorText -notmatch 'Remove-ItemProperty.+PendingFileRenameOperations') 'The workflow modifies PFRO registry data.'

$orchestratorHash = Get-NormalizedSha256 ([IO.File]::ReadAllText($orchestrator))
$copyHelperHash = Get-NormalizedSha256 ([IO.File]::ReadAllText($copyHelper))
Assert-True ($installText -match [regex]::Escape($orchestratorHash)) 'InstallLanguagePacks does not pin the current orchestrator hash.'
Assert-True ($defaultText -match [regex]::Escape($orchestratorHash)) 'SetDefaultLang does not pin the current orchestrator hash.'
Assert-True ($installText -match [regex]::Escape($copyHelperHash)) 'InstallLanguagePacks does not pin the current compatibility-helper hash.'
Assert-True ($defaultText -match [regex]::Escape($copyHelperHash)) 'SetDefaultLang does not re-verify the compatibility-helper hash.'
Assert-True (
    ([regex]::Matches($installText, 'windows10SupportBaseUri')).Count -ge 3
) 'The Windows 10 support location is not isolated behind one base URI.'
$immutableSupportBaseUri = (
    'https://raw.githubusercontent.com/anshuljswl/RDS-Templates/' +
    'dcaa3564c8975df11a09e152e3b852cc9277a6cb/' +
    'CustomImageTemplateScripts/CustomImageTemplateScripts_2024-03-27'
)
Assert-True (
    $installText -match [regex]::Escape($immutableSupportBaseUri)
) 'InstallLanguagePacks does not use the immutable validation support source.'
Assert-True (
    $defaultText -match [regex]::Escape($immutableSupportBaseUri)
) 'SetDefaultLang does not identify the immutable validation support source.'
Assert-True (
    $immutableSupportBaseUri -match '/[0-9a-f]{40}/'
) 'The Windows 10 support source is not pinned to a full commit SHA.'
Assert-True (
    $orchestratorText -match 'Assert-PortalRestartCompleted[\s\S]+LastBootUpTime[\s\S]+did not run or did not complete'
) 'The second entry cannot detect a missing or incomplete portal restart.'
Assert-True (
    $orchestratorText -match 'Language/UBR parity requires LCU reapplication'
) 'The LCU reapplication decision does not preserve its diagnostic reason.'
Assert-True (
    $orchestratorText -match 'MaximumInstallAttempts = 3' -and
    $orchestratorText -match "Get-WindowsUpdateInstallFailureDisposition" -and
    $orchestratorText -match 'Inspect Windows Update, CBS, and UsoClient logs'
) 'The Windows Update busy retry is not bounded or does not retain actionable failure diagnostics.'

Assert-True ($guideText -match 'There is\s+no production `Validate` customizer') 'The guide does not document external-only validation.'
Assert-True ($guideText -match 'restartTimeout`: at least `30m`') 'The guide does not document the validated restart timeout.'
Assert-True (
    $guideText -match 'Start-Sleep -Seconds 180; Get-Service WinRM \| Where-Object Status -eq ''Running'''
) 'The guide does not document the validated restart stabilization command.'
Assert-True (
    $guideText -match 'pending AVD Portal PM\s+confirmation'
) 'The manual template workaround is not marked as pending PM confirmation.'

if ($failures.Count -gt 0) {
    throw "Versioned integration validation failed ($($failures.Count) failure(s), $passed passed):`n - $($failures -join "`n - ")"
}

Write-Host "Versioned integration validation passed: $passed assertions."
