[CmdletBinding(DefaultParameterSetName = 'Package')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'WindowsUpdate')]
    [Parameter(Mandatory = $true, ParameterSetName = 'Package')]
    [Parameter(Mandatory = $true, ParameterSetName = 'AdoptServicedLanguage')]
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

    [Parameter(ParameterSetName = 'WindowsUpdate')]
    [Parameter(ParameterSetName = 'Package')]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$LanguagePackCabPath,

    [Parameter(ParameterSetName = 'WindowsUpdate')]
    [Parameter(ParameterSetName = 'Package')]
    [switch]$DownloadLanguagePack,

    [Parameter(Mandatory = $true, ParameterSetName = 'Package')]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$LcuPackagePath,

    [Parameter(Mandatory = $true, ParameterSetName = 'WindowsUpdate')]
    [switch]$UseWindowsUpdate,

    [Parameter(Mandatory = $true, ParameterSetName = 'WindowsUpdate')]
    [Parameter(Mandatory = $true, ParameterSetName = 'Package')]
    [Parameter(Mandatory = $true, ParameterSetName = 'AdoptServicedLanguage')]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$CopyNewUserSettingsScriptPath,

    [switch]$RequireRdp,

    [switch]$RestartAutomatically,

    [Parameter(Mandatory = $true, ParameterSetName = 'Resume', DontShow = $true)]
    [switch]$Resume,

    [Parameter(Mandatory = $true, ParameterSetName = 'AibBootStabilization', DontShow = $true)]
    [switch]$AibBootStabilization,

    [Parameter(Mandatory = $true, ParameterSetName = 'AdoptServicedLanguage', DontShow = $true)]
    [switch]$AdoptServicedLanguage,

    [Parameter(ParameterSetName = 'WindowsUpdate', DontShow = $true)]
    [Parameter(ParameterSetName = 'Package', DontShow = $true)]
    [Parameter(ParameterSetName = 'Resume', DontShow = $true)]
    [ValidateSet('InstallAndService', 'ApplyMachineLanguage', 'Validate')]
    [string]$AibPhase,

    [Parameter(ParameterSetName = 'Resume', DontShow = $true)]
    [string]$ExpectedLanguageTag,

    [Parameter(DontShow = $true)]
    [string]$WorkingDirectory = 'C:\ProgramData\Windows10MachineLanguage',

    [Parameter(DontShow = $true)]
    [uri]$LanguagePackIsoUri = 'https://software-download.microsoft.com/download/pr/19041.1.191206-1406.vb_release_CLIENTLANGPACKDVD_OEM_MULTI.iso',

    [Parameter(DontShow = $true)]
    [long]$ExpectedLanguagePackIsoLength = 5950959616
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$taskName = 'Windows10MachineLanguage-Resume'
$aibBootTaskName = 'Windows10MachineLanguage-AibBootStabilization'
$statePath = Join-Path $WorkingDirectory 'state.json'
$logPath = Join-Path $WorkingDirectory 'operation.log'
$reportPath = Join-Path $WorkingDirectory 'result.json'
$pendingActionPath = Join-Path $WorkingDirectory 'pending-action.json'
$aibBootStatePath = Join-Path $WorkingDirectory 'aib-boot-stabilization.json'
$aibBootReceiptPath = Join-Path $WorkingDirectory 'aib-boot-stabilization-complete.json'
$aibUpdateIsolationPath = Join-Path $WorkingDirectory 'aib-update-isolation.json'
$operationLockPath = Join-Path $WorkingDirectory 'operation.lock'
$installedScriptPath = Join-Path $WorkingDirectory 'Set-Windows10MachineLanguage.ps1'
$installedHelperPath = Join-Path $WorkingDirectory 'Copy-UserInternationalSettingsToSystemCompat.ps1'
$initialParameterSetName = $PSCmdlet.ParameterSetName
$isAibExecution = -not [string]::IsNullOrWhiteSpace($AibPhase) -or $AdoptServicedLanguage

function Test-IsElevated {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-IsSystemAccount {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    return $identity.User.Value -eq 'S-1-5-18'
}

function Test-IsInteractiveUserSession {
    return [Diagnostics.Process]::GetCurrentProcess().SessionId -ne 0
}

function Write-Operation {
    param([Parameter(Mandatory = $true)][string]$Message)

    $line = '{0:u} {1}' -f (Get-Date), $Message
    Write-Host $line
    Add-Content -LiteralPath $logPath -Value $line -Encoding UTF8
}

function Read-State {
    if (-not (Test-Path -LiteralPath $statePath)) {
        throw "State file was not found at '$statePath'."
    }

    return Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
}

function Write-State {
    param([Parameter(Mandatory = $true)]$State)

    $State.UpdatedUtc = (Get-Date).ToUniversalTime().ToString('o')
    $State | ConvertTo-Json -Depth 6 |
        Set-Content -LiteralPath $statePath -Encoding UTF8
}

function Register-ResumeTask {
    if ($isAibExecution) {
        return
    }

    $arguments = '-NoProfile -ExecutionPolicy Bypass -File "{0}" -Resume -WorkingDirectory "{1}"' -f `
        $installedScriptPath, $WorkingDirectory
    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $arguments
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $principal = New-ScheduledTaskPrincipal `
        -UserId 'SYSTEM' `
        -LogonType ServiceAccount `
        -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet `
        -StartWhenAvailable `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -MultipleInstances IgnoreNew `
        -RestartCount 2 `
        -RestartInterval (New-TimeSpan -Minutes 5) `
        -ExecutionTimeLimit (New-TimeSpan -Hours 3)

    Register-ScheduledTask `
        -TaskName $taskName `
        -Action $action `
        -Trigger $trigger `
        -Principal $principal `
        -Settings $settings `
        -Force | Out-Null
}

function Remove-ResumeTask {
    if ($isAibExecution) {
        return
    }

    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
}

function Copy-FileUnlessSame {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    $sourcePath = [IO.Path]::GetFullPath($Source)
    $destinationPath = [IO.Path]::GetFullPath($Destination)
    if (-not $sourcePath.Equals($destinationPath, [StringComparison]::OrdinalIgnoreCase)) {
        Copy-Item -LiteralPath $sourcePath -Destination $destinationPath -Force
    }
}

function Get-ServicingPendingReasons {
    $reasons = New-Object System.Collections.Generic.List[string]
    $registrySignals = @(
        @{
            Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
            Name = 'CBS RebootPending'
        },
        @{
            Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
            Name = 'Windows Update RebootRequired'
        },
        @{
            Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootInProgress'
            Name = 'CBS RebootInProgress'
        },
        @{
            Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\PackagesPending'
            Name = 'CBS PackagesPending'
        }
    )

    foreach ($signal in $registrySignals) {
        if (Test-Path -LiteralPath $signal.Path) {
            $reasons.Add($signal.Name)
        }
    }

    $pendingFileRenames = Get-ItemProperty `
        'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' `
        -Name PendingFileRenameOperations `
        -ErrorAction SilentlyContinue
    if ($null -ne $pendingFileRenames) {
        $reasons.Add('PendingFileRenameOperations')
    }

    return $reasons.ToArray()
}

function Test-RebootPending {
    return @(Get-ServicingPendingReasons).Count -gt 0
}

function Wait-ForServicingReady {
    param(
        [int]$TimeoutMinutes = 60,
        [switch]$AllowPendingRestart
    )

    $deadline = (Get-Date).AddMinutes($TimeoutMinutes)
    $lastReasonSummary = $null
    $lastReasons = @()
    $nextDiagnostic = [DateTime]::MinValue
    do {
        $lastReasons = @(Get-ServicingPendingReasons)
        if ($AllowPendingRestart -or $lastReasons.Count -eq 0) {
            return
        }

        $now = Get-Date
        $reasonSummary = $lastReasons -join ', '
        if ($reasonSummary -ne $lastReasonSummary -or $now -ge $nextDiagnostic) {
            $installerProcesses = @(
                Get-Process -Name TiWorker, TrustedInstaller -ErrorAction SilentlyContinue
            )
            $installerSummary = if ($installerProcesses.Count -gt 0) {
                @($installerProcesses | ForEach-Object { $_.ProcessName } | Sort-Object -Unique) -join ', '
            }
            else {
                'none'
            }
            Write-Operation (
                (
                    'Waiting for Windows servicing readiness. Pending signal(s): {0}. ' +
                    'Installer process(es), diagnostic only: {1}.'
                ) -f $reasonSummary, $installerSummary
            )
            $lastReasonSummary = $reasonSummary
            $nextDiagnostic = $now.AddMinutes(5)
        }
        Start-Sleep -Seconds 30
    } while ((Get-Date) -lt $deadline)

    throw (
        "Windows servicing did not become ready within $TimeoutMinutes minutes. " +
        "Pending signal(s): $($lastReasons -join ', ')."
    )
}

function Wait-ForServicingStability {
    param(
        [int]$StableSeconds = 180,
        [int]$TimeoutMinutes = 25
    )

    $deadline = (Get-Date).AddMinutes($TimeoutMinutes)
    $stableSince = $null
    $lastReasonSummary = $null
    do {
        $reasons = @(Get-ServicingPendingReasons)
        $now = Get-Date
        if ($reasons.Count -eq 0) {
            if ($null -eq $stableSince) {
                $stableSince = $now
                Write-Operation "Windows servicing is currently clear; requiring $StableSeconds continuous stable seconds before releasing AIB."
            }
            elseif (($now - $stableSince).TotalSeconds -ge $StableSeconds) {
                return
            }
        }
        else {
            $stableSince = $null
            $reasonSummary = $reasons -join ', '
            if ($reasonSummary -ne $lastReasonSummary) {
                Write-Operation "Holding the AIB communicator for Windows servicing: $reasonSummary."
                $lastReasonSummary = $reasonSummary
            }
        }

        Start-Sleep -Seconds 30
    } while ((Get-Date) -lt $deadline)

    throw "Windows servicing did not remain clear for $StableSeconds continuous seconds within $TimeoutMinutes minutes."
}

function Wait-ForPostLanguageBootStability {
    param(
        [int]$StableSeconds = 60,
        [int]$TimeoutMinutes = 5
    )

    $deadline = (Get-Date).AddMinutes($TimeoutMinutes)
    $bootTime = Get-SystemBootTime
    Write-Operation "Machine-language restart boot observed; requiring $StableSeconds seconds of continuous boot uptime before releasing AIB."
    do {
        $currentBootTime = Get-SystemBootTime
        if ($currentBootTime -ne $bootTime) {
            $bootTime = $currentBootTime
            Write-Operation 'A later reboot was observed; restarting the machine-language boot stability window.'
        }
        if (((Get-Date).ToUniversalTime() - $bootTime).TotalSeconds -ge $StableSeconds) {
            return
        }
        Start-Sleep -Seconds 15
    } while ((Get-Date) -lt $deadline)

    throw "The machine-language restart did not remain booted for $StableSeconds continuous seconds within $TimeoutMinutes minutes."
}

function Get-SystemBootTime {
    $bootTime = (Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop).LastBootUpTime
    if ($bootTime -is [datetime]) {
        return $bootTime.ToUniversalTime()
    }
    return [Management.ManagementDateTimeConverter]::ToDateTime([string]$bootTime).ToUniversalTime()
}

function Enter-AibUpdateIsolation {
    $windowsUpdateServicePath = 'HKLM:\SYSTEM\CurrentControlSet\Services\wuauserv'
    $automaticUpdatePolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
    if (-not (Test-Path -LiteralPath $aibUpdateIsolationPath -PathType Leaf)) {
        $policy = Get-ItemProperty `
            -LiteralPath $automaticUpdatePolicyPath `
            -Name NoAutoUpdate `
            -ErrorAction SilentlyContinue
        [ordered]@{
            SchemaVersion             = 1
            WindowsUpdateServiceStart = [int](
                Get-ItemProperty -LiteralPath $windowsUpdateServicePath -Name Start -ErrorAction Stop
            ).Start
            NoAutoUpdateExisted       = $null -ne $policy
            NoAutoUpdateValue         = if ($null -ne $policy) { [int]$policy.NoAutoUpdate } else { $null }
            CreatedUtc                = (Get-Date).ToUniversalTime().ToString('o')
        } | ConvertTo-Json |
            Set-Content -LiteralPath $aibUpdateIsolationPath -Encoding UTF8
    }

    New-Item -ItemType Directory -Path $automaticUpdatePolicyPath -Force | Out-Null
    New-ItemProperty `
        -LiteralPath $automaticUpdatePolicyPath `
        -Name NoAutoUpdate `
        -PropertyType DWord `
        -Value 1 `
        -Force | Out-Null
    Stop-Service -Name wuauserv -Force -ErrorAction Stop
    Set-Service -Name wuauserv -StartupType Disabled
    $isolatedService = Get-ItemProperty -LiteralPath $windowsUpdateServicePath -Name Start
    $isolatedPolicy = Get-ItemProperty -LiteralPath $automaticUpdatePolicyPath -Name NoAutoUpdate
    if ([int]$isolatedService.Start -ne 4 -or [int]$isolatedPolicy.NoAutoUpdate -ne 1) {
        throw 'Windows Update isolation could not be verified.'
    }
    Write-Operation 'Paused automatic Windows Update activity until the language workflow completes.'
}

function Exit-AibUpdateIsolation {
    if (-not (Test-Path -LiteralPath $aibUpdateIsolationPath -PathType Leaf)) {
        return
    }

    $isolation = Get-Content -LiteralPath $aibUpdateIsolationPath -Raw | ConvertFrom-Json
    $windowsUpdateServicePath = 'HKLM:\SYSTEM\CurrentControlSet\Services\wuauserv'
    $automaticUpdatePolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
    Set-ItemProperty `
        -LiteralPath $windowsUpdateServicePath `
        -Name Start `
        -Value ([int]$isolation.WindowsUpdateServiceStart)
    if ([bool]$isolation.NoAutoUpdateExisted) {
        Set-ItemProperty `
            -LiteralPath $automaticUpdatePolicyPath `
            -Name NoAutoUpdate `
            -Value ([int]$isolation.NoAutoUpdateValue)
    }
    else {
        Remove-ItemProperty `
            -LiteralPath $automaticUpdatePolicyPath `
            -Name NoAutoUpdate `
            -ErrorAction SilentlyContinue
    }
    Remove-Item -LiteralPath $aibUpdateIsolationPath -Force
    Write-Operation 'Restored the original Windows Update service and policy configuration.'
}

function Register-AibBootStabilization {
    param([Parameter(Mandatory = $true)][string]$Phase)

    if (-not $isAibExecution) {
        return
    }

    $winRmServicePath = 'HKLM:\SYSTEM\CurrentControlSet\Services\WinRM'
    $winRmConfiguration = Get-ItemProperty -LiteralPath $winRmServicePath -ErrorAction Stop
    $winRmStart = [int]$winRmConfiguration.Start
    if ($winRmStart -eq 4) {
        throw 'WinRM is already disabled; AIB cannot install its reboot stabilization guard safely.'
    }

    $sourceBootTime = Get-SystemBootTime
    [ordered]@{
        SchemaVersion               = 1
        Phase                       = $Phase
        OriginalWinRmStart          = $winRmStart
        OriginalWinRmDelayedExisted = $null -ne $winRmConfiguration.PSObject.Properties['DelayedAutoStart']
        OriginalWinRmDelayedValue   = if ($null -ne $winRmConfiguration.PSObject.Properties['DelayedAutoStart']) {
            [int]$winRmConfiguration.DelayedAutoStart
        }
        else {
            $null
        }
        SourceBootUtc               = $sourceBootTime.ToString('o')
        SecondaryRebootCount        = 0
        CreatedUtc                  = (Get-Date).ToUniversalTime().ToString('o')
    } | ConvertTo-Json |
        Set-Content -LiteralPath $aibBootStatePath -Encoding UTF8
    Remove-Item -LiteralPath $aibBootReceiptPath -Force -ErrorAction SilentlyContinue

    if ($Phase -eq 'PostLanguageRestart') {
        Write-Operation (
            "Armed validation-time boot stabilization for '$Phase'; " +
            'the standard AIB restart may use its unchanged WinRM readiness behavior.'
        )
        return
    }

    $arguments = '-NoProfile -ExecutionPolicy Bypass -File "{0}" -AibBootStabilization -WorkingDirectory "{1}"' -f `
        $installedScriptPath, $WorkingDirectory
    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $arguments
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $principal = New-ScheduledTaskPrincipal `
        -UserId 'SYSTEM' `
        -LogonType ServiceAccount `
        -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet `
        -StartWhenAvailable `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -MultipleInstances IgnoreNew `
        -RestartCount 5 `
        -RestartInterval (New-TimeSpan -Minutes 1) `
        -ExecutionTimeLimit (New-TimeSpan -Minutes 45)

    Register-ScheduledTask `
        -TaskName $aibBootTaskName `
        -Action $action `
        -Trigger $trigger `
        -Principal $principal `
        -Settings $settings `
        -Force | Out-Null

    Set-Service -Name WinRM -StartupType Disabled
    Write-Operation "Armed AIB boot stabilization for '$Phase'; WinRM will remain unavailable until servicing is continuously stable."
}

function Try-RequestAibSecondaryServicingReboot {
    param([Parameter(Mandatory = $true)]$GuardState)

    if ([string]$GuardState.Phase -ne 'PostLcuRestart') {
        return $false
    }
    $secondaryRebootCount = if ($null -ne $GuardState.PSObject.Properties['SecondaryRebootCount']) {
        [int]$GuardState.SecondaryRebootCount
    }
    else {
        0
    }
    if ($secondaryRebootCount -ge 1) {
        return $false
    }

    $pendingReasons = @(Get-ServicingPendingReasons)
    $activeServicingReasons = @(
        $pendingReasons | Where-Object {
            $_ -eq 'CBS RebootInProgress'
        }
    )
    if ($pendingReasons.Count -eq 0 -or $activeServicingReasons.Count -gt 0) {
        return $false
    }

    if ($null -eq $GuardState.PSObject.Properties['SecondaryRebootCount']) {
        $GuardState | Add-Member -NotePropertyName SecondaryRebootCount -NotePropertyValue 1
    }
    else {
        $GuardState.SecondaryRebootCount = 1
    }
    $GuardState | ConvertTo-Json -Depth 6 |
        Set-Content -LiteralPath $aibBootStatePath -Encoding UTF8
    Write-Operation (
        "Servicing remained restart-pending without an in-progress CBS transaction; requesting one bounded secondary reboot. " +
        "Pending signal(s): $($pendingReasons -join ', ')."
    )
    try {
        $shutdownProcess = Start-Process `
            -FilePath 'shutdown.exe' `
            -ArgumentList @(
                '/r',
                '/t', '15',
                '/f',
                '/d', 'p:4:1'
            ) `
            -WindowStyle Hidden `
            -Wait `
            -PassThru
        if ($shutdownProcess.ExitCode -ne 0) {
            throw "shutdown.exe returned exit code $($shutdownProcess.ExitCode)."
        }
    }
    catch {
        $GuardState.SecondaryRebootCount = 0
        $GuardState | ConvertTo-Json -Depth 6 |
            Set-Content -LiteralPath $aibBootStatePath -Encoding UTF8
        throw
    }
    return $true
}

function Invoke-AibBootStabilization {
    if (-not (Test-Path -LiteralPath $aibBootStatePath -PathType Leaf)) {
        throw "AIB boot stabilization state was not found at '$aibBootStatePath'."
    }

    $guardState = Get-Content -LiteralPath $aibBootStatePath -Raw | ConvertFrom-Json
    Write-Operation "AIB boot stabilization resumed for '$($guardState.Phase)'."
    $sourceBootTime = [datetime]$guardState.SourceBootUtc
    $currentBootTime = Get-SystemBootTime
    if ($currentBootTime -le $sourceBootTime) {
        throw "AIB boot stabilization did not observe a reboot after '$($guardState.Phase)'."
    }
    if ([string]$guardState.Phase -eq 'PostLanguageRestart') {
        Wait-ForPostLanguageBootStability
    }
    else {
        try {
            Wait-ForServicingStability -StableSeconds 180 -TimeoutMinutes 8
        }
        catch {
            if ($_.Exception.Message -notmatch '^Windows servicing did not remain clear') {
                throw
            }
            if (Try-RequestAibSecondaryServicingReboot -GuardState $guardState) {
                return
            }
            Wait-ForServicingStability -StableSeconds 180 -TimeoutMinutes 17
        }
    }

    if ([string]$guardState.Phase -eq 'PostLcuRestart') {
        Enter-AibUpdateIsolation
    }

    $winRmServicePath = 'HKLM:\SYSTEM\CurrentControlSet\Services\WinRM'
    $originalWinRmStart = [int]$guardState.OriginalWinRmStart
    $originalWinRmStartupType = switch ($originalWinRmStart) {
        2 { 'Automatic' }
        3 { 'Manual' }
        default {
            throw "Unsupported original WinRM startup value '$originalWinRmStart'."
        }
    }
    Set-Service -Name WinRM -StartupType $originalWinRmStartupType
    if ([bool]$guardState.OriginalWinRmDelayedExisted) {
        Set-ItemProperty `
            -LiteralPath $winRmServicePath `
            -Name DelayedAutoStart `
            -Value ([int]$guardState.OriginalWinRmDelayedValue)
    }
    else {
        Remove-ItemProperty `
            -LiteralPath $winRmServicePath `
            -Name DelayedAutoStart `
            -ErrorAction SilentlyContinue
    }
    [ordered]@{
        SchemaVersion = 1
        Phase         = [string]$guardState.Phase
        SourceBootUtc = $sourceBootTime.ToString('o')
        StableBootUtc = $currentBootTime.ToString('o')
        CompletedUtc  = (Get-Date).ToUniversalTime().ToString('o')
    } | ConvertTo-Json |
        Set-Content -LiteralPath $aibBootReceiptPath -Encoding UTF8
    Start-Service -Name WinRM
    Unregister-ScheduledTask -TaskName $aibBootTaskName -Confirm:$false -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $aibBootStatePath -Force
    Write-Operation "Windows servicing is stable; restored WinRM and released AIB after '$($guardState.Phase)'."
}

function Assert-AibBootStabilizationCompleted {
    param([Parameter(Mandatory = $true)][string]$Phase)

    if (Test-Path -LiteralPath $aibBootStatePath -PathType Leaf) {
        if ($Phase -ne 'PostLanguageRestart') {
            throw "AIB boot stabilization for '$Phase' is still pending; refusing to start a reboot-sensitive phase."
        }

        $guardState = Get-Content -LiteralPath $aibBootStatePath -Raw | ConvertFrom-Json
        if ([string]$guardState.Phase -ne $Phase) {
            throw "AIB boot stabilization state is for '$($guardState.Phase)', not '$Phase'."
        }
        $sourceBootTime = [datetime]$guardState.SourceBootUtc
        $currentBootTime = Get-SystemBootTime
        if ($currentBootTime -le $sourceBootTime) {
            throw "AIB boot stabilization did not observe a reboot after '$Phase'."
        }
        Wait-ForPostLanguageBootStability
        $stableBootTime = Get-SystemBootTime
        [ordered]@{
            SchemaVersion = 1
            Phase         = $Phase
            SourceBootUtc = $sourceBootTime.ToString('o')
            StableBootUtc = $stableBootTime.ToString('o')
            CompletedUtc  = (Get-Date).ToUniversalTime().ToString('o')
        } | ConvertTo-Json |
            Set-Content -LiteralPath $aibBootReceiptPath -Encoding UTF8
        Remove-Item -LiteralPath $aibBootStatePath -Force
        Write-Operation "Validated the machine-language restart and released AIB after '$Phase'."
    }
    if (-not (Test-Path -LiteralPath $aibBootReceiptPath -PathType Leaf)) {
        throw "AIB boot stabilization receipt for '$Phase' is missing."
    }

    $receipt = Get-Content -LiteralPath $aibBootReceiptPath -Raw | ConvertFrom-Json
    if ([string]$receipt.Phase -ne $Phase) {
        throw "AIB boot stabilization receipt is for '$($receipt.Phase)', not '$Phase'."
    }
    if ([datetime]$receipt.StableBootUtc -le [datetime]$receipt.SourceBootUtc) {
        throw "AIB boot stabilization receipt for '$Phase' does not prove that a reboot occurred."
    }
}

function Get-ExpectedStateForAibPhase {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('InstallAndService', 'ApplyMachineLanguage', 'Validate')]
        [string]$Phase
    )

    switch ($Phase) {
        'InstallAndService' { return 'InstallingLanguageAndLcu' }
        'ApplyMachineLanguage' { return 'PostLcuRestart' }
        'Validate' { return 'PostLanguageRestart' }
    }
}

function Get-OsServicingInfo {
    $currentVersion = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    return [pscustomobject]@{
        ProductName    = [string]$currentVersion.ProductName
        DisplayVersion = [string]$currentVersion.DisplayVersion
        CurrentBuild   = [int]$currentVersion.CurrentBuild
        UBR            = [int]$currentVersion.UBR
    }
}

function Get-InstalledLanguagePackageVersion {
    param([Parameter(Mandatory = $true)][string]$TargetLanguageTag)

    $escapedTag = [regex]::Escape($TargetLanguageTag)
    $packages = Get-WindowsPackage -Online |
        Where-Object {
            $_.PackageState -eq 'Installed' -and
            $_.PackageName -match "Client-LanguagePack-Package~31bf3856ad364e35~amd64~$escapedTag~10\.0\.(\d+\.\d+)$"
        } |
        ForEach-Object {
            $match = [regex]::Match($_.PackageName, '~10\.0\.(?<Version>\d+\.\d+)$')
            if ($match.Success) {
                [pscustomobject]@{
                    PackageName = $_.PackageName
                    Version     = [version]$match.Groups['Version'].Value
                    InstallTime = $_.InstallTime
                }
            }
        } |
        Sort-Object Version -Descending

    $package = $packages | Select-Object -First 1
    if ($null -eq $package) {
        throw "The installed client language package for '$TargetLanguageTag' was not found."
    }

    return $package
}

function Test-ClientLanguagePackInstalled {
    param([Parameter(Mandatory = $true)][string]$TargetLanguageTag)

    try {
        [void](Get-InstalledLanguagePackageVersion -TargetLanguageTag $TargetLanguageTag)
        return $true
    }
    catch {
        return $false
    }
}

function Get-LanguagePackFromMicrosoft {
    param(
        [Parameter(Mandatory = $true)][string]$TargetLanguageTag,
        [Parameter(Mandatory = $true)][uri]$IsoUri,
        [Parameter(Mandatory = $true)][long]$ExpectedIsoLength
    )

    $allowedHosts = @(
        'software-download.microsoft.com',
        'software-static.download.prss.microsoft.com'
    )
    if ($IsoUri.Scheme -ne 'https' -or $IsoUri.Host -notin $allowedHosts) {
        throw "Language-pack media must use HTTPS from an approved Microsoft download host."
    }

    $driveName = [IO.Path]::GetPathRoot($WorkingDirectory).Substring(0, 1)
    $drive = Get-PSDrive -Name $driveName -PSProvider FileSystem
    if ($drive.Free -lt 8GB) {
        throw "At least 8 GB of free space is required to download and extract the official Windows 10 language-pack ISO."
    }

    $isoPath = Join-Path $WorkingDirectory 'Windows10-Client-Language-Pack.iso'
    $cabPath = Join-Path $WorkingDirectory (
        'Client-Language-Pack-{0}.cab' -f $TargetLanguageTag
    )

    if (-not (Test-Path -LiteralPath $isoPath -PathType Leaf)) {
        Write-Operation "Downloading the official Windows 10 language-pack ISO from Microsoft. This download is approximately 6 GB."
        $downloaded = $false
        if (Get-Command Start-BitsTransfer -ErrorAction SilentlyContinue) {
            try {
                Start-BitsTransfer `
                    -Source $IsoUri.AbsoluteUri `
                    -Destination $isoPath `
                    -ErrorAction Stop |
                    Out-Null
                $downloaded = $true
            }
            catch {
                Remove-Item -LiteralPath $isoPath -Force -ErrorAction SilentlyContinue
                Write-Operation "BITS download was unavailable in this logon context; falling back to HTTPS download."
            }
        }
        if (-not $downloaded) {
            $null = Invoke-WebRequest `
                -Uri $IsoUri.AbsoluteUri `
                -OutFile $isoPath `
                -UseBasicParsing `
                -ErrorAction Stop
        }
    }

    $iso = Get-Item -LiteralPath $isoPath
    if ($iso.Length -ne $ExpectedIsoLength) {
        throw "The downloaded language-pack ISO is $($iso.Length) bytes; expected $ExpectedIsoLength bytes."
    }

    $mounted = $false
    try {
        $diskImage = Mount-DiskImage -ImagePath $isoPath -PassThru -ErrorAction Stop
        $mounted = $true
        $volume = $diskImage | Get-Volume | Where-Object DriveLetter | Select-Object -First 1
        if ($null -eq $volume) {
            throw 'The mounted language-pack ISO did not expose a drive letter.'
        }

        $expectedName = 'Microsoft-Windows-Client-Language-Pack_x64_{0}.cab' -f `
            $TargetLanguageTag.ToLowerInvariant()
        $sourceCab = Get-ChildItem `
            -LiteralPath "$($volume.DriveLetter):\" `
            -Filter $expectedName `
            -File `
            -Recurse `
            -ErrorAction Stop |
            Select-Object -First 1
        if ($null -eq $sourceCab) {
            throw "The official Microsoft ISO does not contain '$expectedName'."
        }

        Copy-Item -LiteralPath $sourceCab.FullName -Destination $cabPath -Force
        if ((Get-Item -LiteralPath $cabPath).Length -lt 1MB) {
            throw "The extracted language-pack CAB is unexpectedly small."
        }
        Write-Operation "Extracted '$expectedName' from the official Microsoft ISO."
    }
    finally {
        if ($mounted) {
            Dismount-DiskImage -ImagePath $isoPath -ErrorAction SilentlyContinue |
                Out-Null
        }
        Remove-Item -LiteralPath $isoPath -Force -ErrorAction SilentlyContinue
    }

    return $cabPath
}

function Assert-LanguageServicedToCurrentUbr {
    param([Parameter(Mandatory = $true)][string]$TargetLanguageTag)

    $os = Get-OsServicingInfo
    $languagePackage = Get-InstalledLanguagePackageVersion -TargetLanguageTag $TargetLanguageTag

    if ($languagePackage.Version.Minor -ne $os.UBR) {
        throw ("Language package '{0}' is at revision {1}, but Windows is at UBR {2}. " +
            'Do not apply machine-wide language settings until the approved LCU has serviced the language resources.') -f `
            $TargetLanguageTag, $languagePackage.Version.Minor, $os.UBR
    }

    Write-Operation ("Language package '{0}' is serviced to revision {1}, matching Windows UBR {2}." -f `
        $TargetLanguageTag, $languagePackage.Version.Minor, $os.UBR)
}

function Wait-ForLanguagePackage {
    param(
        [Parameter(Mandatory = $true)][string]$TargetLanguageTag,
        [int]$TimeoutMinutes = 10
    )

    $deadline = (Get-Date).AddMinutes($TimeoutMinutes)
    do {
        try {
            return Get-InstalledLanguagePackageVersion -TargetLanguageTag $TargetLanguageTag
        }
        catch {
            if ((Get-Date) -ge $deadline) {
                throw
            }

            Write-Operation "Waiting for the '$TargetLanguageTag' client language package to register."
            Start-Sleep -Seconds 15
        }
    } while ($true)
}

function Assert-CoreHealth {
    param(
        [switch]$CheckRdp,
        [switch]$CheckAibPlatform,
        [datetime]$EventsSince = (Get-Date).AddMinutes(-30),
        [int]$RuntimeTimeoutMinutes = 10
    )

    $deadline = (Get-Date).AddMinutes($RuntimeTimeoutMinutes)
    do {
        $runtimeError = $null
        $requiredServices = @('BFE', 'mpssvc')
        if ($CheckAibPlatform) {
            $requiredServices += @('WinDefend', 'WindowsAzureGuestAgent')
        }
        foreach ($serviceName in $requiredServices) {
            $service = Get-CimInstance Win32_Service -Filter "Name='$serviceName'"
            if ($null -eq $service) {
                $runtimeError = "Required service '$serviceName' was not found."
                break
            }
            if ($service.State -ne 'Running' -or $service.ExitCode -ne 0) {
                $runtimeError = "Required service '$serviceName' is unhealthy. State='$($service.State)', ExitCode='$($service.ExitCode)'."
                break
            }
        }

        if ($null -eq $runtimeError) {
            try {
                [void](Get-NetFirewallProfile -ErrorAction Stop)
            }
            catch {
                $runtimeError = "Windows Firewall APIs are unavailable. $($_.Exception.Message)"
            }
        }

        if ($null -eq $runtimeError -and $CheckRdp) {
            $rdpListener = Get-NetTCPConnection `
                -LocalPort 3389 `
                -State Listen `
                -ErrorAction SilentlyContinue
            if (-not $rdpListener) {
                $runtimeError = 'RDP validation was requested, but TCP port 3389 is not listening.'
            }
            elseif (-not (Test-NetConnection 127.0.0.1 -Port 3389 -InformationLevel Quiet)) {
                $runtimeError = 'RDP validation was requested, but the local TCP 3389 test failed.'
            }
        }

        if ($null -eq $runtimeError) {
            break
        }

        if ((Get-Date) -ge $deadline) {
            throw $runtimeError
        }

        Write-Operation "$runtimeError Retrying."
        Start-Sleep -Seconds 15
    } while ($true)

    $events = Get-WinEvent -FilterHashtable @{
        LogName   = 'System'
        StartTime = $EventsSince
    } -ErrorAction SilentlyContinue

    $mpssvcDisplayName = [string](Get-CimInstance Win32_Service -Filter "Name='mpssvc'").DisplayName
    $mpssvcFailures = @($events | Where-Object {
        $_.Id -eq 7024 -and
        $_.ProviderName -eq 'Service Control Manager' -and
        @($_.Properties | ForEach-Object { [string]$_.Value }) -contains $mpssvcDisplayName
    })

    $error1168 = @($events | Where-Object {
        $_.ProviderName -eq 'Service Control Manager' -and
        $_.Id -in @(7000, 7001, 7023, 7024, 7026, 7031, 7034) -and
        (
            @($_.Properties | ForEach-Object { [string]$_.Value }) -contains '1168' -or
            $_.Message -match '\b1168\b'
        )
    })

    if ($mpssvcFailures.Count -gt 0 -or $error1168.Count -gt 0) {
        throw "Detected $($mpssvcFailures.Count) mpssvc Event 7024 failures and $($error1168.Count) error-1168 events since $EventsSince."
    }

    Write-Operation 'Firewall, required services, event log, requested RDP, and AIB platform health checks passed.'
}

function Install-TargetLanguage {
    param(
        [Parameter(Mandatory = $true)][string]$TargetLanguageTag,
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$ClientLanguagePackPath
    )

    Import-Module LanguagePackManagement -ErrorAction Stop
    $installed = @(
        foreach ($installedLanguage in (Get-InstalledLanguage -ErrorAction Stop)) {
            if ($installedLanguage.LanguageId -eq $TargetLanguageTag) {
                $installedLanguage
            }
        }
    )
    $hasLanguagePack = @(
        $installed | Where-Object { [int]$_.LanguagePacks -ne 0 }
    ).Count -gt 0

    if (-not $hasLanguagePack) {
        if ([string]::IsNullOrWhiteSpace($ClientLanguagePackPath)) {
            throw "The '$TargetLanguageTag' client language pack is missing and no CAB was staged."
        }
        Write-Operation "Installing the '$TargetLanguageTag' client language-pack CAB."
        $packageResult = Add-WindowsPackage `
            -Online `
            -PackagePath $ClientLanguagePackPath `
            -NoRestart `
            -ErrorAction Stop
        Write-Operation "Client language-pack servicing completed. RestartNeeded=$($packageResult.RestartNeeded)."
    }
    else {
        Write-Operation "The '$TargetLanguageTag' client display language pack is already installed."
    }

    Write-Operation "Installing or repairing Features on Demand for '$TargetLanguageTag'."
    Install-Language -Language $TargetLanguageTag -ErrorAction Stop

    $installed = @(
        foreach ($installedLanguage in (Get-InstalledLanguage -ErrorAction Stop)) {
            if ($installedLanguage.LanguageId -eq $TargetLanguageTag) {
                $installedLanguage
            }
        }
    )
    if (
        $installed.Count -eq 0 -or
        @($installed | Where-Object { [int]$_.LanguagePacks -ne 0 }).Count -eq 0
    ) {
        throw "Language installation did not install a display language pack for '$TargetLanguageTag'."
    }

    Wait-ForServicingReady -AllowPendingRestart
    [void](Wait-ForLanguagePackage -TargetLanguageTag $TargetLanguageTag)
    Write-Operation "Verified the '$TargetLanguageTag' CBS client language package is installed."
}

function Set-CurrentUserLanguage {
    param([Parameter(Mandatory = $true)][string]$TargetLanguageTag)

    Set-WinUILanguageOverride -Language $TargetLanguageTag

    $languageList = New-WinUserLanguageList -Language $TargetLanguageTag
    foreach ($installedLanguage in (Get-WinUserLanguageList)) {
        if ($languageList.LanguageTag -notcontains $installedLanguage.LanguageTag) {
            [void]$languageList.Add($installedLanguage)
        }
    }
    Set-WinUserLanguageList -LanguageList $languageList -Force

    $region = New-Object System.Globalization.RegionInfo($TargetLanguageTag)
    Set-WinHomeLocation -GeoId $region.GeoId
    Set-Culture -CultureInfo $TargetLanguageTag

    # Windows 10 can defer this value until the next logon even when the
    # supported cmdlets have already applied the UI override and language list.
    $desktopKey = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey('Control Panel\Desktop')
    try {
        $preferredUiLanguages = @(
            $desktopKey.GetValue(
                'PreferredUILanguages',
                $null,
                [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
            )
        )
        if (
            $preferredUiLanguages.Count -eq 0 -or
            [string]$preferredUiLanguages[0] -ne $TargetLanguageTag
        ) {
            $desktopKey.SetValue(
                'PreferredUILanguages',
                [string[]]@($TargetLanguageTag),
                [Microsoft.Win32.RegistryValueKind]::MultiString
            )
        }
    }
    finally {
        $desktopKey.Dispose()
    }

    $deadline = (Get-Date).AddMinutes(2)
    do {
        $international = Get-ItemProperty 'HKCU:\Control Panel\International'
        $desktop = Get-ItemProperty 'HKCU:\Control Panel\Desktop'
        $localeProperty = $international.PSObject.Properties['LocaleName']
        $localeName = if ($null -ne $localeProperty) { [string]$localeProperty.Value } else { '' }
        $preferredProperty = $desktop.PSObject.Properties['PreferredUILanguages']
        $pendingProperty = $desktop.PSObject.Properties['PreferredUILanguagesPending']
        $selectedLanguages = @()
        if ($null -ne $pendingProperty -and @($pendingProperty.Value).Count -gt 0) {
            $selectedLanguages = @($pendingProperty.Value)
        }
        elseif ($null -ne $preferredProperty) {
            $selectedLanguages = @($preferredProperty.Value)
        }
        if (
            $localeName -eq $TargetLanguageTag -and
            $selectedLanguages.Count -gt 0 -and
            [string]$selectedLanguages[0] -eq $TargetLanguageTag
        ) {
            break
        }

        $uiOverride = Get-WinUILanguageOverride
        $uiOverrideName = if ($null -ne $uiOverride) { $uiOverride.Name } else { '' }
        $userLanguageTags = @((Get-WinUserLanguageList).LanguageTag)

        if ((Get-Date) -ge $deadline) {
            throw (
                "The invoking user's language settings did not persist before the Default User copy. " +
                "UIOverride='$uiOverrideName'; " +
                "UserLanguages='$($userLanguageTags -join ',')'; LocaleName='$localeName'; " +
                "RegistryLanguages='$($selectedLanguages -join ',')'."
            )
        }
        Start-Sleep -Seconds 5
    } while ($true)

    Write-Operation "Configured the invoking user's culture, UI override, language list, and home location for '$TargetLanguageTag'."
}

function Invoke-NewUserSettingsCopy {
    param([Parameter(Mandatory = $true)][string]$HelperPath)

    & $HelperPath -NewUser $true
    Write-Operation 'Copied current-user international settings to the Default User profile.'
}

function Backup-DefaultUserHive {
    $sourcePath = Join-Path $env:SystemDrive 'Users\Default\NTUSER.DAT'
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "Default User registry hive was not found at '$sourcePath'."
    }

    $backupPath = Join-Path $WorkingDirectory (
        'DefaultUser-NTUSER-{0}.DAT' -f (Get-Date -Format 'yyyyMMdd-HHmmss')
    )
    Copy-Item -LiteralPath $sourcePath -Destination $backupPath -Force
    Write-Operation "Backed up the Default User registry hive to '$backupPath'."
    return $backupPath
}

function Assert-DefaultUserLanguage {
    param([Parameter(Mandatory = $true)][string]$TargetLanguageTag)

    $hiveName = 'Windows10LanguageDefaultUser'
    $hivePath = Join-Path $env:SystemDrive 'Users\Default\NTUSER.DAT'
    $loadedHere = $false
    try {
        if (Test-Path "Registry::HKEY_USERS\$hiveName") {
            $process = Start-Process `
                -FilePath "$env:SystemRoot\System32\reg.exe" `
                -ArgumentList @('unload', "HKU\$hiveName") `
                -Wait `
                -PassThru `
                -WindowStyle Hidden
            if ($process.ExitCode -ne 0) {
                throw "Unable to clear a stale Default User registry-hive mount. reg.exe exit code: $($process.ExitCode)."
            }
        }

        $process = Start-Process `
            -FilePath "$env:SystemRoot\System32\reg.exe" `
            -ArgumentList @('load', "HKU\$hiveName", $hivePath) `
            -Wait `
            -PassThru `
            -WindowStyle Hidden
        if ($process.ExitCode -ne 0) {
            throw "Unable to load the Default User registry hive. reg.exe exit code: $($process.ExitCode)."
        }
        $loadedHere = $true

        $international = Get-ItemProperty `
            -LiteralPath "Registry::HKEY_USERS\$hiveName\Control Panel\International" `
            -ErrorAction Stop
        $desktop = Get-ItemProperty `
            -LiteralPath "Registry::HKEY_USERS\$hiveName\Control Panel\Desktop" `
            -ErrorAction Stop
        $localeProperty = $international.PSObject.Properties['LocaleName']
        $localeName = if ($null -ne $localeProperty) { [string]$localeProperty.Value } else { '' }
        $preferredProperty = $desktop.PSObject.Properties['PreferredUILanguages']
        $preferredLanguages = @()
        if ($null -ne $preferredProperty) {
            $preferredLanguages = @($preferredProperty.Value)
        }
        if (
            $localeName -ne $TargetLanguageTag -or
            $preferredLanguages.Count -eq 0 -or
            [string]$preferredLanguages[0] -ne $TargetLanguageTag
        ) {
            throw ("Default User language validation failed. LocaleName='{0}', PreferredUILanguages='{1}'." -f `
                $localeName, ($preferredLanguages -join ','))
        }
    }
    finally {
        if ($loadedHere) {
            [GC]::Collect()
            [GC]::WaitForPendingFinalizers()
            $process = Start-Process `
                -FilePath "$env:SystemRoot\System32\reg.exe" `
                -ArgumentList @('unload', "HKU\$hiveName") `
                -Wait `
                -PassThru `
                -WindowStyle Hidden
            if ($process.ExitCode -ne 0) {
                Write-Warning "Unable to unload the Default User registry hive. reg.exe exit code: $($process.ExitCode)."
            }
        }
    }

    Write-Operation "Default User international settings match '$TargetLanguageTag'."
}

function Assert-MicrosoftSignature {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Description
    )

    $signature = Get-AuthenticodeSignature -LiteralPath $Path
    if ($signature.Status -ne [Management.Automation.SignatureStatus]::Valid) {
        throw "$Description '$Path' does not have a valid Authenticode signature. Status='$($signature.Status)'; Message='$($signature.StatusMessage)'."
    }
    if (
        $null -eq $signature.SignerCertificate -or
        [string]$signature.SignerCertificate.Subject -notmatch '(?:^|,\s*)O=Microsoft Corporation(?:,|$)'
    ) {
        throw "$Description '$Path' is not signed by Microsoft Corporation."
    }
}

function Invoke-Expand {
    param(
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$FailureMessage
    )

    $expandPath = Join-Path $env:SystemRoot 'System32\expand.exe'
    if (-not (Test-Path -LiteralPath $expandPath -PathType Leaf)) {
        throw "The inbox extraction tool was not found at '$expandPath'."
    }

    $output = @(& $expandPath @Arguments 2>&1)
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "$FailureMessage expand.exe exit code: $exitCode. Output: $($output -join ' ')"
    }

    return $output
}

function Get-MsuPayloadClassification {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$MumIdentityNames,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$DismPackageNames
    )

    $allIdentities = @($MumIdentityNames) + @($DismPackageNames)
    $isServicingStack = @($allIdentities | Where-Object {
        $_ -match '(?i)(?:^|[-_.])(?:Package_for_)?ServicingStack(?:[-_.]|$)'
    }).Count -gt 0
    $hasLegacyRollupIdentity = @($allIdentities | Where-Object {
        $_ -match '(?i)^Package_for_RollupFix'
    }).Count -gt 0

    return [pscustomobject]@{
        IsServicingStack       = $isServicingStack
        HasLegacyRollupIdentity = $hasLegacyRollupIdentity
        IsLcuPayload           = -not $isServicingStack
    }
}

function Get-MumServicingMetadata {
    param([Parameter(Mandatory = $true)][Xml.XmlDocument]$MumDocument)

    $assemblyNames = @()
    $architectures = @()
    foreach ($identity in $MumDocument.SelectNodes("//*[local-name()='assemblyIdentity']")) {
        $assemblyName = [string]$identity.GetAttribute('name')
        if ([string]::IsNullOrWhiteSpace($assemblyName)) {
            $assemblyName = [string]$identity.GetAttribute('assemblyName')
        }
        if (-not [string]::IsNullOrWhiteSpace($assemblyName)) {
            $assemblyNames += $assemblyName
        }

        $architecture = [string]$identity.GetAttribute('processorArchitecture')
        if ([string]::IsNullOrWhiteSpace($architecture)) {
            $architecture = [string]$identity.GetAttribute('architecture')
        }
        if (-not [string]::IsNullOrWhiteSpace($architecture)) {
            $architectures += $architecture
        }
    }

    $packageIdentifiers = @()
    $releaseTypes = @()
    foreach ($package in $MumDocument.SelectNodes("//*[local-name()='package']")) {
        $identifier = [string]$package.GetAttribute('identifier')
        if (-not [string]::IsNullOrWhiteSpace($identifier)) {
            $packageIdentifiers += $identifier
        }
        $releaseType = [string]$package.GetAttribute('releaseType')
        if (-not [string]::IsNullOrWhiteSpace($releaseType)) {
            $releaseTypes += $releaseType
        }
    }

    return [pscustomobject]@{
        AssemblyNames      = @($assemblyNames | Select-Object -Unique)
        Architectures      = @($architectures | Select-Object -Unique)
        PackageIdentifiers = @($packageIdentifiers | Select-Object -Unique)
        ReleaseTypes       = @($releaseTypes | Select-Object -Unique)
    }
}

function Get-MsuLcuPayloads {
    param(
        [Parameter(Mandatory = $true)][string]$MsuPath,
        [Parameter(Mandatory = $true)][string]$ExtractionDirectory
    )

    Assert-MicrosoftSignature -Path $MsuPath -Description 'LCU MSU'
    New-Item -ItemType Directory -Path $ExtractionDirectory -Force | Out-Null
    [void](Invoke-Expand `
        -Arguments @('-F:*', $MsuPath, $ExtractionDirectory) `
        -FailureMessage "Unable to extract LCU MSU '$MsuPath'.")

    $allCabs = @(Get-ChildItem -LiteralPath $ExtractionDirectory -Filter '*.cab' -File)
    if ($allCabs.Count -eq 0) {
        throw "LCU MSU '$MsuPath' did not contain any CAB files."
    }

    $payloads = @()
    foreach ($cab in $allCabs) {
        if ($cab.Name -match '(?i)(?:^|[-_.])(?:wsusscan|scan|metadata)(?:[-_.]|$)') {
            Write-Operation "Ignoring non-servicing MSU CAB '$($cab.Name)'."
            continue
        }

        $listing = @(Invoke-Expand `
            -Arguments @('-D', $cab.FullName) `
            -FailureMessage "Unable to inspect extracted CAB '$($cab.FullName)'.")
        $listingText = $listing -join "`n"
        if (
            $listingText -notmatch '(?i)\bupdate\.mum\b' -or
            $listingText -notmatch '(?i)\bupdate\.cat\b'
        ) {
            Write-Operation "Ignoring CAB '$($cab.Name)' because it does not contain update.mum and update.cat servicing metadata."
            continue
        }

        $metadataDirectory = Join-Path $ExtractionDirectory (
            'metadata-{0}' -f [IO.Path]::GetFileNameWithoutExtension($cab.Name)
        )
        New-Item -ItemType Directory -Path $metadataDirectory -Force | Out-Null
        [void](Invoke-Expand `
            -Arguments @('-F:update.cat', $cab.FullName, $metadataDirectory) `
            -FailureMessage "Unable to extract update.cat from '$($cab.FullName)'.")
        [void](Invoke-Expand `
            -Arguments @('-F:update.mum', $cab.FullName, $metadataDirectory) `
            -FailureMessage "Unable to extract update.mum from '$($cab.FullName)'.")
        $catalogPath = Join-Path $metadataDirectory 'update.cat'
        $mumPath = Join-Path $metadataDirectory 'update.mum'
        if (-not (Test-Path -LiteralPath $catalogPath -PathType Leaf)) {
            throw "CAB '$($cab.FullName)' listed update.cat but did not extract it."
        }
        if (-not (Test-Path -LiteralPath $mumPath -PathType Leaf)) {
            throw "CAB '$($cab.FullName)' listed update.mum but did not extract it."
        }
        Assert-MicrosoftSignature -Path $catalogPath -Description 'LCU catalog'

        $mumDocument = New-Object Xml.XmlDocument
        try {
            $mumDocument.Load($mumPath)
        }
        catch {
            throw "CAB '$($cab.FullName)' contains an unreadable update.mum. $($_.Exception.Message)"
        }
        $mumMetadata = Get-MumServicingMetadata -MumDocument $mumDocument
        if ($mumMetadata.AssemblyNames.Count -eq 0) {
            throw "CAB '$($cab.FullName)' update.mum does not contain an assembly identity."
        }
        $unsupportedArchitectures = @($mumMetadata.Architectures | Where-Object {
            $_ -notin @('amd64', 'neutral')
        })
        if ($unsupportedArchitectures.Count -gt 0) {
            throw "CAB '$($cab.FullName)' update.mum targets unsupported architecture(s): '$($unsupportedArchitectures -join ', ')'. Expected amd64 or neutral."
        }
        if ($mumMetadata.Architectures -notcontains 'amd64') {
            throw "CAB '$($cab.FullName)' update.mum does not identify an amd64 servicing package."
        }

        $packageNames = @()
        $applicability = @()
        try {
            $packageInfo = @(Get-WindowsPackage `
                -Online `
                -PackagePath $cab.FullName `
                -ErrorAction Stop)
            $packageNames = @($packageInfo | ForEach-Object { [string]$_.PackageName })
            $applicability = @(
                $packageInfo |
                    Where-Object { $null -ne $_.PSObject.Properties['Applicable'] } |
                    ForEach-Object { [bool]$_.Applicable }
            )
            if ($applicability.Count -gt 0 -and $applicability -notcontains $true) {
                throw "DISM reports that CAB '$($cab.FullName)' is not applicable to this online image."
            }
        }
        catch {
            if ($_.Exception.Message -match 'DISM reports that CAB') {
                throw
            }
            Write-Operation "DISM metadata probe did not classify CAB '$($cab.Name)'; signed MUM/catalog servicing metadata will be used. $($_.Exception.Message)"
        }

        $classification = Get-MsuPayloadClassification `
            -MumIdentityNames $mumMetadata.AssemblyNames `
            -DismPackageNames $packageNames
        $identitySummary = @($mumMetadata.AssemblyNames + $packageNames | Select-Object -Unique)
        $payloads += [pscustomobject]@{
            Path             = $cab.FullName
            Name             = $cab.Name
            Rank             = if ($classification.IsServicingStack) { 0 } else { 1 }
            IsServicingStack = $classification.IsServicingStack
            IsLcuPayload     = $classification.IsLcuPayload
            HasLegacyRollupIdentity = $classification.HasLegacyRollupIdentity
            PackageNames     = $identitySummary
            Architectures    = $mumMetadata.Architectures
            PackageIdentifiers = $mumMetadata.PackageIdentifiers
            ReleaseTypes     = $mumMetadata.ReleaseTypes
            Applicable       = if ($applicability.Count -gt 0) { $applicability -contains $true } else { $null }
        }
    }

    if ($payloads.Count -eq 0) {
        throw "LCU MSU '$MsuPath' did not contain a valid servicing-stack or cumulative-update CAB payload."
    }
    if (@($payloads | Where-Object { $_.IsLcuPayload }).Count -eq 0) {
        throw "LCU MSU '$MsuPath' contained only servicing-stack CABs and no cumulative-update servicing CAB."
    }

    return @($payloads | Sort-Object Rank, Name)
}

function Install-LcuCab {
    param([Parameter(Mandatory = $true)][string]$CabPath)

    Write-Operation "Installing or reapplying LCU CAB '$CabPath' with DISM."
    $result = Add-WindowsPackage `
        -Online `
        -PackagePath $CabPath `
        -IgnoreCheck `
        -NoRestart `
        -ErrorAction Stop
    Write-Operation "DISM CAB servicing completed. RestartNeeded=$($result.RestartNeeded)."
}

function Install-LcuFromPackage {
    param([Parameter(Mandatory = $true)][string]$PackagePath)

    $extension = [IO.Path]::GetExtension($PackagePath).ToLowerInvariant()
    if ($extension -eq '.cab') {
        Install-LcuCab -CabPath $PackagePath
        return
    }
    if ($extension -ne '.msu') {
        throw "Unsupported LCU package extension '$extension'. Supply an .msu or .cab file."
    }

    $extractionDirectory = Join-Path $WorkingDirectory 'LcuMsuExtraction'
    if (Test-Path -LiteralPath $extractionDirectory) {
        Remove-Item -LiteralPath $extractionDirectory -Recurse -Force
    }

    try {
        $payloads = @(Get-MsuLcuPayloads `
            -MsuPath $PackagePath `
            -ExtractionDirectory $extractionDirectory)
        $appliedLcuPayloadCount = 0
        foreach ($payload in $payloads) {
            Write-Operation "Applying extracted MSU payload '$($payload.Name)' for package(s) '$($payload.PackageNames -join ', ')'."
            Install-LcuCab -CabPath $payload.Path
            if ($payload.IsLcuPayload) {
                $appliedLcuPayloadCount++
            }
        }
        if ($appliedLcuPayloadCount -eq 0) {
            throw "No cumulative-update servicing CAB from MSU '$PackagePath' was applied."
        }
    }
    finally {
        if (Test-Path -LiteralPath $extractionDirectory) {
            Remove-Item -LiteralPath $extractionDirectory -Recurse -Force
        }
    }
}

function Get-WindowsUpdateLcuSelection {
    $session = New-Object -ComObject Microsoft.Update.Session
    $searcher = $session.CreateUpdateSearcher()
    $result = $searcher.Search("IsInstalled=0 and Type='Software' and IsHidden=0")
    $candidates = @()

    for ($index = 0; $index -lt $result.Updates.Count; $index++) {
        $update = $result.Updates.Item($index)
        if (
            $update.Title -match 'Cumulative Update for Windows 10' -and
            $update.Title -notmatch '\.NET|Preview'
        ) {
            $candidates += $update
        }
    }

    $selected = $candidates |
        Sort-Object LastDeploymentChangeTime -Descending |
        Select-Object -First 1

    return [pscustomobject]@{
        Session = $session
        Update  = $selected
    }
}

function Install-LcuFromWindowsUpdate {
    param([Parameter(Mandatory = $true)]$Selection)

    $session = $Selection.Session
    $selected = $Selection.Update
    if ($null -eq $selected) {
        throw ('Windows Update did not offer an applicable Windows 10 LCU. ' +
            'Microsoft notes that an already-installed LCU is not offered again; rerun with -LcuPackagePath pointing to the approved Catalog/WSUS package.')
    }

    if (-not $selected.EulaAccepted) {
        $selected.AcceptEula()
    }

    Write-Operation "Selected Windows Update package '$($selected.Title)'."
    $updates = New-Object -ComObject Microsoft.Update.UpdateColl
    [void]$updates.Add($selected)

    if (-not $selected.IsDownloaded) {
        $downloader = $session.CreateUpdateDownloader()
        $downloader.Updates = $updates
        $downloadResult = $downloader.Download()
        if ($downloadResult.ResultCode -ne 2) {
            throw "LCU download failed with result code $($downloadResult.ResultCode)."
        }
    }

    $installer = $session.CreateUpdateInstaller()
    $installer.Updates = $updates
    $installResult = $installer.Install()
    if ($installResult.ResultCode -ne 2 -or $installResult.HResult -ne 0) {
        $hresult = '0x{0:X8}' -f ($installResult.HResult -band 0xffffffffL)
        throw "LCU installation failed. ResultCode=$($installResult.ResultCode), HResult=$hresult."
    }

    Write-Operation "LCU installation completed successfully. RebootRequired=$($installResult.RebootRequired)."
}

function Request-Restart {
    param([Parameter(Mandatory = $true)][string]$Reason)

    Write-Operation $Reason
    if ($RestartAutomatically) {
        Restart-Computer -Force
        return
    }

    $state = Read-State
    $pendingResult = [ordered]@{
        Status      = 'AwaitingRestart'
        Phase       = $state.Phase
        Reason      = $Reason
        UpdatedUtc  = (Get-Date).ToUniversalTime().ToString('o')
        ResumeTask  = if ($isAibExecution) { $null } else { $taskName }
        NextAibPhase = if (-not $isAibExecution) {
            $null
        }
        elseif ([string]$state.Phase -eq 'PostLcuRestart') {
            'ApplyMachineLanguage'
        }
        elseif ([string]$state.Phase -eq 'PostLanguageRestart') {
            'Validate'
        }
        else {
            throw "Unsupported AIB restart state '$($state.Phase)'."
        }
    }
    $pendingResult | ConvertTo-Json |
        Set-Content -LiteralPath $pendingActionPath -Encoding UTF8
    $pendingResult | ConvertTo-Json |
        Set-Content -LiteralPath $reportPath -Encoding UTF8
    if ($isAibExecution) {
        Write-Operation "Restart is required. Run an Azure Image Builder Windows Restart customizer, then invoke AIB phase '$($pendingResult.NextAibPhase)'."
        return
    }

    Write-Warning 'Restart Windows to continue. The workflow will resume automatically after startup.'
    & "$env:SystemRoot\System32\msg.exe" * "Windows language configuration requires a restart. Restart Windows to continue; the workflow will resume automatically." 2>$null
    Write-Operation "Restart is required. The scheduled task '$taskName' will resume automatically at startup."
}

function Complete-Operation {
    param([Parameter(Mandatory = $true)]$State)

    $os = Get-OsServicingInfo
    $languagePackage = Get-InstalledLanguagePackageVersion -TargetLanguageTag $State.LanguageTag
    $result = [ordered]@{
        Status                     = 'Succeeded'
        CompletedUtc               = (Get-Date).ToUniversalTime().ToString('o')
        LanguageTag                = $State.LanguageTag
        WindowsBuild               = "$($os.CurrentBuild).$($os.UBR)"
        LanguagePackage            = $languagePackage.PackageName
        LanguagePackageVersion     = $languagePackage.Version.ToString()
        SystemPreferredUILanguage  = [string](Get-SystemPreferredUILanguage)
        SystemLocale               = [string](Get-WinSystemLocale).Name
        FirewallServiceState       = [string](Get-Service mpssvc).Status
        RdpRequired                = [bool]$State.RequireRdp
        LogPath                    = $logPath
    }
    $result | ConvertTo-Json -Depth 4 |
        Set-Content -LiteralPath $reportPath -Encoding UTF8

    Exit-AibUpdateIsolation
    Unregister-ScheduledTask -TaskName $aibBootTaskName -Confirm:$false -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $aibBootStatePath, $aibBootReceiptPath -Force -ErrorAction SilentlyContinue
    $State.Phase = 'Completed'
    Write-State -State $State
    Remove-Item -LiteralPath $pendingActionPath -Force -ErrorAction SilentlyContinue
    Remove-ResumeTask
    Write-Operation "Machine-wide language configuration completed successfully. Result: $reportPath"
}

function Invoke-InstallAndServicePhase {
    param([Parameter(Mandatory = $true)]$State)

    Install-TargetLanguage `
        -TargetLanguageTag $State.LanguageTag `
        -ClientLanguagePackPath $State.LanguagePackCabPath
    Set-CurrentUserLanguage -TargetLanguageTag $State.LanguageTag
    if ([string]::IsNullOrWhiteSpace([string]$State.DefaultUserHiveBackup)) {
        $State.DefaultUserHiveBackup = Backup-DefaultUserHive
        Write-State -State $State
    }
    Invoke-NewUserSettingsCopy -HelperPath $installedHelperPath
    Assert-DefaultUserLanguage -TargetLanguageTag $State.LanguageTag

    Wait-ForServicingReady -AllowPendingRestart
    try {
        Assert-LanguageServicedToCurrentUbr -TargetLanguageTag $State.LanguageTag
        Write-Operation 'The installed language package already matches the Windows revision; no LCU reapplication is needed.'
    }
    catch {
        if ([string]$State.LcuMode -eq 'Package') {
            Install-LcuFromPackage -PackagePath $State.LcuPackagePath
        }
        else {
            $windowsUpdateSelection = Get-WindowsUpdateLcuSelection
            if ($null -eq $windowsUpdateSelection.Update) {
                throw ('Windows Update does not currently offer an applicable Windows 10 LCU. ' +
                    'Supply the organization-approved current LCU with -LcuPackagePath.')
            }
            Install-LcuFromWindowsUpdate -Selection $windowsUpdateSelection
        }
    }

    $State.Phase = 'PostLcuRestart'
    $State.PhaseStartedUtc = (Get-Date).ToUniversalTime().ToString('o')
    $State.Error = $null
    Write-State -State $State
    Register-AibBootStabilization -Phase $State.Phase
    Register-ResumeTask
    Request-Restart -Reason 'Restarting to complete cumulative-update servicing.'
}

function Invoke-InitialPhase {
    if (-not $isAibExecution -and (Test-IsSystemAccount)) {
        throw ('The standalone workflow must be started from an elevated administrator user session so the requested ' +
            'culture can be copied to Default User. For SYSTEM-based image automation, use Invoke-Windows10MachineLanguageAib.ps1.')
    }
    if (-not $isAibExecution -and -not (Test-IsInteractiveUserSession)) {
        throw ('The standalone workflow must be started from an elevated interactive administrator session. ' +
            'Password-backed scheduled tasks and other Session 0 launches do not reliably persist Set-Culture on Windows 10.')
    }

    $os = Get-OsServicingInfo
    if ($os.CurrentBuild -notin @(19044, 19045)) {
        throw "This orchestrator requires Windows 10 21H2 or 22H2. Detected build $($os.CurrentBuild)."
    }
    if (-not (Get-Module -ListAvailable -Name LanguagePackManagement)) {
        throw 'The LanguagePackManagement module is not available. Install or service Windows before running this workflow.'
    }
    if ($LanguagePackCabPath -and $DownloadLanguagePack) {
        throw 'Specify either -LanguagePackCabPath or -DownloadLanguagePack, not both.'
    }

    if (Test-RebootPending) {
        throw 'Windows already has a pending servicing restart. Restart Windows and rerun this workflow before changing language configuration.'
    }
    if ($isAibExecution -and (Test-Path -LiteralPath $statePath -PathType Leaf)) {
        $existingState = Read-State
        if ([string]$existingState.Phase -ne 'Completed') {
            throw "An incomplete AIB language operation already exists in phase '$($existingState.Phase)'. Resume it instead of starting over."
        }
    }
    Wait-ForServicingReady
    Assert-CoreHealth -CheckRdp:$RequireRdp -CheckAibPlatform:$isAibExecution

    if ($initialParameterSetName -eq 'WindowsUpdate') {
        $windowsUpdateSelection = Get-WindowsUpdateLcuSelection
        if ($null -eq $windowsUpdateSelection.Update) {
            throw ('Windows Update does not currently offer an applicable Windows 10 LCU. ' +
                'No changes were made. Supply the organization-approved current LCU with -LcuPackagePath so DISM can reapply it after language installation.')
        }
        Write-Operation "Preflight found applicable Windows Update package '$($windowsUpdateSelection.Update.Title)'."
    }

    New-Item -ItemType Directory -Path $WorkingDirectory -Force | Out-Null
    Remove-Item -LiteralPath $reportPath, $pendingActionPath -Force -ErrorAction SilentlyContinue
    Copy-FileUnlessSame -Source $PSCommandPath -Destination $installedScriptPath
    Copy-FileUnlessSame -Source $CopyNewUserSettingsScriptPath -Destination $installedHelperPath

    $stagedLanguagePackPath = $null
    if (-not (Test-ClientLanguagePackInstalled -TargetLanguageTag $LanguageTag)) {
        if ($LanguagePackCabPath) {
            $stagedLanguagePackPath = Join-Path $WorkingDirectory (
                'Client-Language-Pack-{0}{1}' -f $LanguageTag, [IO.Path]::GetExtension($LanguagePackCabPath)
            )
            Copy-FileUnlessSame -Source $LanguagePackCabPath -Destination $stagedLanguagePackPath
        }
        elseif ($DownloadLanguagePack) {
            $stagedLanguagePackPath = Get-LanguagePackFromMicrosoft `
                -TargetLanguageTag $LanguageTag `
                -IsoUri $LanguagePackIsoUri `
                -ExpectedIsoLength $ExpectedLanguagePackIsoLength
        }
        else {
            throw ("The '$LanguageTag' client language pack is not installed. " +
                'Specify -LanguagePackCabPath or -DownloadLanguagePack.')
        }
    }
    else {
        Write-Operation "The '$LanguageTag' client language pack is already installed; no CAB source is required."
    }

    $stagedLcuPath = $null
    if ($initialParameterSetName -eq 'Package') {
        $stagedLcuPath = Join-Path $WorkingDirectory (
            'Approved-Windows10-LCU{0}' -f [IO.Path]::GetExtension($LcuPackagePath)
        )
        Copy-FileUnlessSame -Source $LcuPackagePath -Destination $stagedLcuPath
    }

    $state = [pscustomobject][ordered]@{
        Phase                = 'InstallingLanguageAndLcu'
        LanguageTag          = $LanguageTag
        LcuMode              = $initialParameterSetName
        LcuPackagePath       = $stagedLcuPath
        LanguagePackCabPath  = $stagedLanguagePackPath
        LanguagePackSource   = if ($LanguagePackCabPath) { 'LocalCab' } elseif ($DownloadLanguagePack) { 'MicrosoftDownload' } else { 'AlreadyInstalled' }
        RequireRdp           = [bool]$RequireRdp
        RestartAutomatically = [bool]$RestartAutomatically
        FailureCount         = 0
        Error                = $null
        DefaultUserHiveBackup = $null
        StartedUtc           = (Get-Date).ToUniversalTime().ToString('o')
        PhaseStartedUtc      = (Get-Date).ToUniversalTime().ToString('o')
        UpdatedUtc           = $null
    }
    Write-State -State $state
    Register-ResumeTask
    $script:StateOwnedByCurrentInvocation = $true
    Invoke-InstallAndServicePhase -State $state
}

function Invoke-AdoptServicedLanguagePhase {
    $os = Get-OsServicingInfo
    if ($os.CurrentBuild -notin @(19044, 19045)) {
        throw "This orchestrator requires Windows 10 21H2 or 22H2. Detected build $($os.CurrentBuild)."
    }
    if (Test-RebootPending) {
        throw 'CIT built-in servicing still reports a pending restart; refusing machine-wide language activation.'
    }
    Wait-ForServicingReady
    Assert-LanguageServicedToCurrentUbr -TargetLanguageTag $LanguageTag
    Assert-CoreHealth -CheckRdp:$RequireRdp -CheckAibPlatform

    $state = $null
    if (Test-Path -LiteralPath $statePath -PathType Leaf) {
        $existingState = Read-State
        if (
            [string]$existingState.Phase -eq 'Completed' -and
            [string]$existingState.LanguageTag -eq $LanguageTag
        ) {
            Write-Operation "The adopted CIT language operation is already complete. Result: $reportPath"
            return
        }
        if ([string]$existingState.Phase -ne 'AdoptingServicedLanguage') {
            throw "A built-in CIT adoption cannot replace existing state '$($existingState.Phase)'."
        }
        if ([string]$existingState.LanguageTag -ne $LanguageTag) {
            throw "Existing adoption language '$($existingState.LanguageTag)' does not match requested '$LanguageTag'."
        }
        if ([bool]$existingState.RequireRdp -ne [bool]$RequireRdp) {
            throw "Existing adoption RequireRdp value '$($existingState.RequireRdp)' does not match requested '$RequireRdp'."
        }
        $state = $existingState
    }

    Copy-FileUnlessSame -Source $PSCommandPath -Destination $installedScriptPath
    Copy-FileUnlessSame -Source $CopyNewUserSettingsScriptPath -Destination $installedHelperPath
    if ($null -eq $state) {
        $state = [pscustomobject][ordered]@{
            Phase                 = 'AdoptingServicedLanguage'
            LanguageTag           = $LanguageTag
            LcuMode               = 'BuiltInCIT'
            LanguagePackSource    = 'BuiltInCIT'
            RequireRdp            = [bool]$RequireRdp
            RestartAutomatically  = $false
            FailureCount          = 0
            Error                 = $null
            DefaultUserHiveBackup = $null
            StartedUtc            = (Get-Date).ToUniversalTime().ToString('o')
            PhaseStartedUtc       = (Get-Date).ToUniversalTime().ToString('o')
            UpdatedUtc            = $null
        }
        Write-State -State $state
    }
    $script:StateOwnedByCurrentInvocation = $true

    Set-CurrentUserLanguage -TargetLanguageTag $LanguageTag
    if ([string]::IsNullOrWhiteSpace([string]$state.DefaultUserHiveBackup)) {
        $state.DefaultUserHiveBackup = Backup-DefaultUserHive
        Write-State -State $state
    }
    Invoke-NewUserSettingsCopy -HelperPath $installedHelperPath
    Assert-DefaultUserLanguage -TargetLanguageTag $LanguageTag

    Import-Module LanguagePackManagement -ErrorAction Stop
    Set-SystemPreferredUILanguage -Language $LanguageTag
    Set-WinSystemLocale -SystemLocale $LanguageTag
    if ([string](Get-SystemPreferredUILanguage) -ne $LanguageTag) {
        throw 'Set-SystemPreferredUILanguage did not persist the requested language.'
    }

    $state.Phase = 'PostLanguageRestart'
    $state.PhaseStartedUtc = (Get-Date).ToUniversalTime().ToString('o')
    Write-State -State $state
    Register-AibBootStabilization -Phase $state.Phase
    Request-Restart -Reason "Restarting to activate CIT-serviced machine language '$LanguageTag'."
}

function Invoke-PostLcuRestartPhase {
    param([Parameter(Mandatory = $true)]$State)

    if ($isAibExecution) {
        Assert-AibBootStabilizationCompleted -Phase 'PostLcuRestart'
    }
    Wait-ForServicingReady
    Assert-LanguageServicedToCurrentUbr -TargetLanguageTag $State.LanguageTag
    Assert-CoreHealth `
        -CheckRdp:$State.RequireRdp `
        -CheckAibPlatform:$isAibExecution `
        -EventsSince ([datetime]$State.PhaseStartedUtc)

    Import-Module LanguagePackManagement -ErrorAction Stop
    Set-SystemPreferredUILanguage -Language $State.LanguageTag
    Set-WinSystemLocale -SystemLocale $State.LanguageTag

    if ([string](Get-SystemPreferredUILanguage) -ne [string]$State.LanguageTag) {
        throw 'Set-SystemPreferredUILanguage did not persist the requested language.'
    }

    $State.Phase = 'PostLanguageRestart'
    $State.PhaseStartedUtc = (Get-Date).ToUniversalTime().ToString('o')
    Write-State -State $State
    Register-AibBootStabilization -Phase $State.Phase
    Register-ResumeTask
    Request-Restart -Reason "Restarting to activate machine-wide language '$($State.LanguageTag)'."
}

function Invoke-PostLanguageRestartPhase {
    param([Parameter(Mandatory = $true)]$State)

    if ($isAibExecution) {
        Assert-AibBootStabilizationCompleted -Phase 'PostLanguageRestart'
    }
    Wait-ForServicingReady
    Assert-LanguageServicedToCurrentUbr -TargetLanguageTag $State.LanguageTag

    $preferredLanguage = [string](Get-SystemPreferredUILanguage)
    $systemLocale = [string](Get-WinSystemLocale).Name
    if ($preferredLanguage -ne $State.LanguageTag -or $systemLocale -ne $State.LanguageTag) {
        throw ("Machine-wide language validation failed. PreferredUI='{0}', SystemLocale='{1}', Expected='{2}'." -f `
            $preferredLanguage, $systemLocale, $State.LanguageTag)
    }

    Assert-DefaultUserLanguage -TargetLanguageTag $State.LanguageTag
    Assert-CoreHealth `
        -CheckRdp:$State.RequireRdp `
        -CheckAibPlatform:$isAibExecution `
        -EventsSince ([datetime]$State.PhaseStartedUtc)
    Complete-Operation -State $State
}

if (-not (Test-IsElevated)) {
    throw 'Run this script from an elevated 64-bit Windows PowerShell session.'
}

if ([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess) {
    throw 'Run this script from 64-bit Windows PowerShell on 64-bit Windows.'
}
if ($isAibExecution -and -not (Test-IsSystemAccount)) {
    throw 'Azure Image Builder mode must run as the local SYSTEM account.'
}
if (
    -not [string]::IsNullOrWhiteSpace($AibPhase) -and
    $AibPhase -ne 'InstallAndService' -and
    -not $Resume
) {
    throw "AIB phase '$AibPhase' requires -Resume."
}

New-Item -ItemType Directory -Path $WorkingDirectory -Force | Out-Null
$script:StateOwnedByCurrentInvocation = $false
$script:operationLock = $null

try {
    $lockDeadline = (Get-Date).AddMinutes(2)
    do {
        try {
            $script:operationLock = [IO.File]::Open(
                $operationLockPath,
                [IO.FileMode]::OpenOrCreate,
                [IO.FileAccess]::ReadWrite,
                [IO.FileShare]::None
            )
            break
        }
        catch {
            if ((Get-Date) -ge $lockDeadline) {
                throw "Another Windows 10 machine-language invocation is already using '$WorkingDirectory'."
            }
            Start-Sleep -Seconds 2
        }
    } while ($null -eq $script:operationLock)

    if ($AibBootStabilization) {
        Invoke-AibBootStabilization
        return
    }
    if ($AdoptServicedLanguage) {
        Invoke-AdoptServicedLanguagePhase
        return
    }

    if (-not $Resume) {
        Invoke-InitialPhase
        return
    }

    $state = Read-State
    $script:StateOwnedByCurrentInvocation = $true
    $script:RestartAutomatically = if ($isAibExecution) { $false } else { [bool]$state.RestartAutomatically }
    if (
        -not [string]::IsNullOrWhiteSpace($ExpectedLanguageTag) -and
        [string]$state.LanguageTag -ne $ExpectedLanguageTag
    ) {
        throw "State language '$($state.LanguageTag)' does not match requested language '$ExpectedLanguageTag'."
    }
    if ($isAibExecution) {
        $expectedPhase = Get-ExpectedStateForAibPhase -Phase $AibPhase
        if ([string]$state.Phase -ne $expectedPhase) {
            throw "AIB phase '$AibPhase' requires state '$expectedPhase', found '$($state.Phase)'."
        }
    }
    switch ([string]$state.Phase) {
        'InstallingLanguageAndLcu' {
            Invoke-InstallAndServicePhase -State $state
        }
        'PostLcuRestart' {
            Invoke-PostLcuRestartPhase -State $state
        }
        'PostLanguageRestart' {
            Invoke-PostLanguageRestartPhase -State $state
        }
        'Completed' {
            Remove-ResumeTask
            Write-Operation "The operation is already complete. Result: $reportPath"
        }
        default {
            throw "Unsupported or unsafe resume phase '$($state.Phase)'."
        }
    }
}
catch {
    $message = $_.Exception.Message
    Write-Operation "FAILED: $message"

    try {
        if ($script:StateOwnedByCurrentInvocation -and (Test-Path -LiteralPath $statePath)) {
            $failedState = Read-State
            $failedState.FailureCount = [int]$failedState.FailureCount + 1
            $failedState.Error = $message
            Write-State -State $failedState
            [ordered]@{
                Status       = 'Failed'
                Phase        = [string]$failedState.Phase
                Error        = $message
                FailureCount = [int]$failedState.FailureCount
                UpdatedUtc   = (Get-Date).ToUniversalTime().ToString('o')
                LogPath      = $logPath
            } | ConvertTo-Json |
                Set-Content -LiteralPath $reportPath -Encoding UTF8

            if ([int]$failedState.FailureCount -ge 3) {
                Remove-ResumeTask
                Write-Operation 'Automatic retry limit reached. Review the operation log and rerun the launcher after correcting the failure.'
            }
        }
        elseif (-not $Resume) {
            [ordered]@{
                Status     = 'Failed'
                Phase      = 'PreflightOrStaging'
                Error      = $message
                UpdatedUtc = (Get-Date).ToUniversalTime().ToString('o')
                LogPath    = $logPath
            } | ConvertTo-Json |
                Set-Content -LiteralPath $reportPath -Encoding UTF8
        }
    }
    catch {
        Write-Operation "Could not persist failure state: $($_.Exception.Message)"
    }
    throw
}
finally {
    if ($null -ne $script:operationLock) {
        $script:operationLock.Dispose()
        $script:operationLock = $null
    }
}
