# Windows 10 language servicing

Windows 10 21H2/22H2 uses the standalone `SetDefaultLangWin10.ps1` entry
point. The existing `SetDefaultLang.ps1` remains the Windows 11 implementation
and is intentionally unchanged.

The approved Windows 10 runtime files are:

- `SetDefaultLangWin10.ps1`
- `Set-Windows10MachineLanguage.ps1`
- `Invoke-Windows10MachineLanguageAib.ps1`
- `Invoke-Windows10MachineLanguageCit.ps1`
- `Copy-UserInternationalSettingsToSystemCompat.ps1`
- `Test-Windows10MachineLanguageHealth.ps1`

The compatibility helper retains its approved package filename because the
hash-verified release archive and CIT extraction contract reference that exact
name.

## Azure Image Builder flow

Use this exact order:

1. `StageInputs`
2. `InstallAndService`
3. Windows restart
4. `ApplyMachineLanguage`
5. Windows restart
6. `Validate`

`Aib-Customizers.TwoRestartCandidate.example.json` contains the validated
six-customizer ordering. Both restart checks invoke
`Start-Sleep -Seconds 180` before requiring WinRM to be running, and each
restart retains a 30-minute timeout.

The phase-specific wrapper URLs must reference the same branch or immutable
commit as these runtime files. Do not hardcode `master` during branch
validation. The release ZIP remains an external, hash-verified input and is
not stored in this repository.

## Pending file rename opt-in

The two-restart wrappers must explicitly pass
`-AllowRecognizedNonServicingPendingFileRenames` to both `StageInputs` and
`InstallAndService`.

Without that switch, pending-file-rename handling is unchanged and any PFRO
entry remains restart-blocking. With the switch, preflight ignores PFRO only
when every source/destination pair is well formed and matches the narrow
validated non-servicing allowlist. Unknown, mixed, malformed, servicing,
language, Features on Demand, LCU, or CBS-related paths remain fail-closed.
The registry value is never modified or deleted.

## Online validation prerequisite

Before an online AIB run, publish immutable phase wrappers and the approved
release ZIP to HTTPS locations accessible to the build identity, substitute
their URIs and SHA-256 values in an isolated template, and keep the produced
image excluded from latest until qualification is complete.
