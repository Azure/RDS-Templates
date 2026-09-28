# Windows 10 language servicing

Windows 10 21H2/22H2 support is integrated through the existing portal entry
points without adding AVD UX parameters or routes:

1. `InstallLanguagePacks.ps1` maps every requested `LanguageList` value,
   installs each language deterministically, reapplies the latest applicable
   non-preview Windows 10 cumulative update offered by Windows Update, records
   durable state, and returns for the portal's existing restart.
2. `SetDefaultLang.ps1` selects the requested default language from that
   installed set, applies current-user, Default User, system preferred UI, and
   system locale settings, and returns for the portal's existing second
   restart.
3. Produced-image validation runs externally after the final restart. There is
   no production `Validate` customizer.

Both entry scripts dispatch only on client builds 19044 and 19045 and return
before their pre-existing Windows 11 bodies. The Windows 11 parameter contracts
and execution bodies remain unchanged.

The Windows 10 support files are:

- `Set-Windows10MachineLanguage.ps1`
- `Copy-UserInternationalSettingsToSystemCompat.ps1`
- `Test-Windows10MachineLanguageHealth.ps1`

The two entry scripts verify SHA-256 before using downloaded or durably staged
support code. During draft validation, `InstallLanguagePacks.ps1` uses one
isolated fork-branch base URI. Before the pull request can be marked ready, that
single base URI must be switched mechanically to the corresponding
`Azure/RDS-Templates` `master` raw-content location without changing the
hash-pinned support files.

## Servicing behavior

- `LanguageList` order is retained and duplicate language tags are removed
  without selecting a default.
- The official Microsoft Windows 10 language-pack ISO is downloaded once and
  each missing client language CAB is extracted before language/FOD repair.
- The latest applicable non-preview Windows 10 cumulative update offered by
  Windows Update is selected and reapplied when language package revision does
  not match the current Windows UBR. The workflow fails closed before changing
  the image if no applicable LCU is offered. This is a required online
  validation condition: Windows Update does not normally re-offer an
  already-installed LCU, and the no-UX portal contract has no package input.
  Production remains blocked if supported source images are fully current and
  do not receive an applicable LCU; resolving that case requires a productized,
  approved current-LCU acquisition contract rather than a hardcoded KB.
- After the first restart, every installed language package must match the
  current UBR before `SetDefaultLang.ps1` can apply machine-wide settings.
- The recognized non-servicing pending-file-rename allowance is enabled only
  in the Windows 10 install path. Every pair must be well formed and match the
  validated allowlist. Unknown, mixed, malformed, servicing, language, FOD,
  LCU, or CBS-related paths remain blocking. PFRO registry data is never
  modified or deleted.

## Restart requirement

The validated Windows 10 configuration requires both existing portal-managed
restart customizers to use:

- `restartTimeout`: at least `30m` (the validated value).
- `restartCheckCommand`:
  `powershell.exe -NoProfile -Command "Start-Sleep -Seconds 180; Get-Service WinRM | Where-Object Status -eq 'Running'"`

The AVD UX default restart timeout is five minutes and is insufficient. For
internal online validation only, a proposed workaround is to deploy/export the
CIT template, update both restart settings, delete the original template, and
redeploy the modified template. This workaround is pending AVD Portal PM
confirmation and must not be presented as final customer guidance.

Production release remains blocked on restart-timeout productization. If online
validation confirms the requirement, the recommended product solution is a
conditional Windows 10-only portal timeout and restart-check configuration
(feature-controlled if required). It must not slow or otherwise change the
Windows 11 path.

## Qualification

This integration is independently reviewable but is not production-ready or
merge-ready until the restart path is productized and Xian/Nini complete online
Gen1, Gen2, and Multi-Session validation. After the final restart, use
`Test-Windows10MachineLanguageHealth.ps1` (or equivalent produced-image checks)
to verify language/UBR parity, machine and Default User settings, firewall and
event health, and RDP when required.
