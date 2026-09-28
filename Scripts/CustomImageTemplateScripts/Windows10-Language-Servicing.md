# Windows 10 language servicing

The Windows 10 21H2/22H2 language workflow uses these individual scripts from
this directory:

- `Invoke-Windows10MachineLanguageCit.ps1`
- `Invoke-Windows10MachineLanguageAib.ps1`
- `Set-Windows10MachineLanguage.ps1`
- `Copy-UserInternationalSettingsToSystemCompat.ps1`
- `Test-Windows10MachineLanguageHealth.ps1`

Windows 11 continues through the existing `setDefaultLang.ps1` implementation.

## Azure Image Builder flow

Use this exact order for the approved two-restart flow:

1. `StageInputs`
2. `InstallAndService`
3. Windows restart
4. `ApplyMachineLanguage`
5. Windows restart
6. `Validate`

`Aib-Customizers.TwoRestartCandidate.example.json` contains the validated
six-customizer ordering. Both restart checks wait 180 seconds before requiring
WinRM to be running by invoking `Start-Sleep -Seconds 180`, and each restart
retains a 30-minute timeout.

The phase-specific wrapper URLs must reference the same branch or immutable
commit as the runtime files. Do not hardcode `master` when validating a branch.
The release ZIP remains an external, hash-verified input and is not stored in
this repository.

## Pending file rename opt-in

The two-restart wrappers must explicitly pass
`-AllowRecognizedNonServicingPendingFileRenames` to both `StageInputs` and
`InstallAndService`.

Without that switch, pending-file-rename handling is unchanged and any PFRO
entry remains restart-blocking. With the switch, the preflight ignores PFRO
only when every source/destination pair is well formed and matches the narrow
validated non-servicing allowlist. Unknown, mixed, malformed, servicing,
language, Features on Demand, LCU, or CBS-related paths remain fail-closed.
The registry value is never modified or deleted.

## Online validation prerequisite

Before an online AIB run, publish immutable phase wrappers and the approved
release ZIP to HTTPS locations accessible to the build identity, substitute
their URIs and SHA-256 values in an isolated template, and keep the produced
image excluded from latest until qualification is complete.
