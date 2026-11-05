[CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Copy')]
param(
    [Parameter(ParameterSetName = 'Copy')]
    [bool]$NewUser = $true,

    [Parameter(Mandatory = $true, ParameterSetName = 'Probe')]
    [switch]$ProbeOnly,

    [Parameter(ParameterSetName = 'Copy')]
    [switch]$DisableRegistryFallback
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Add-IntlNativeMethods {
    if ('CopyUserIntlSettings.NativeMethods' -as [type]) {
        return
    }

    Add-Type -Language CSharp -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

namespace CopyUserIntlSettings
{
    public static class NativeMethods
    {
        [DllImport("intl.cpl", EntryPoint = "IntlCopyInternationalSettings", ExactSpelling = true, SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern UInt32 IntlCopyInternationalSettings(
            [MarshalAs(UnmanagedType.Bool)] bool copyToWelcomeScreenAndSystemAccounts,
            [MarshalAs(UnmanagedType.Bool)] bool copyToNewUser);
    }
}
"@
}

function Add-InputNativeMethods {
    if ('CopyUserIntlSettings.InputNativeMethods' -as [type]) {
        return
    }

    Add-Type -Language CSharp -TypeDefinition @"
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;

namespace CopyUserIntlSettings
{
    public static class InputNativeMethods
    {
        private const UInt32 LOAD_LIBRARY_SEARCH_SYSTEM32 = 0x00000800;
        private const Int32 ERROR_INVALID_PARAMETER = 87;
        private static readonly IntPtr HKEY_CURRENT_USER = new IntPtr(unchecked((int)0x80000001));

        [DllImport("kernel32.dll", EntryPoint = "LoadLibraryExW", SetLastError = true, CharSet = CharSet.Unicode)]
        private static extern IntPtr LoadLibraryEx(string fileName, IntPtr fileHandle, UInt32 flags);

        [DllImport("kernel32.dll", EntryPoint = "GetProcAddress", SetLastError = true)]
        private static extern IntPtr GetProcAddressByOrdinal(IntPtr module, IntPtr ordinal);

        [UnmanagedFunctionPointer(CallingConvention.Winapi)]
        private delegate bool SaveDefaultUserInputSettingsDelegate(IntPtr parentWindow, IntPtr sourceRegistryKey);

        public static bool IsSaveDefaultUserInputSettingsAvailable()
        {
            IntPtr inputDll = LoadInputDll();
            return GetProcAddressByOrdinal(inputDll, new IntPtr(105)) != IntPtr.Zero;
        }

        public static void SaveDefaultUserInputSettings()
        {
            IntPtr inputDll = LoadInputDll();
            IntPtr procedure = GetProcAddressByOrdinal(inputDll, new IntPtr(105));
            if (procedure == IntPtr.Zero)
            {
                throw new EntryPointNotFoundException("input.dll ordinal 105 (SaveDefaultUserInputSettings) was not found.");
            }

            SaveDefaultUserInputSettingsDelegate saveDefaultUserInputSettings =
                (SaveDefaultUserInputSettingsDelegate)Marshal.GetDelegateForFunctionPointer(
                    procedure,
                    typeof(SaveDefaultUserInputSettingsDelegate));

            if (!saveDefaultUserInputSettings(IntPtr.Zero, HKEY_CURRENT_USER))
            {
                throw new Win32Exception(ERROR_INVALID_PARAMETER);
            }
        }

        private static IntPtr LoadInputDll()
        {
            IntPtr inputDll = LoadLibraryEx("input.dll", IntPtr.Zero, LOAD_LIBRARY_SEARCH_SYSTEM32);
            if (inputDll == IntPtr.Zero)
            {
                throw new Win32Exception(Marshal.GetLastWin32Error(), "Unable to load input.dll from System32.");
            }

            return inputDll;
        }
    }
}
"@
}

function Test-IntlNativeEntryPoint {
    Add-IntlNativeMethods

    try {
        [void][CopyUserIntlSettings.NativeMethods]::IntlCopyInternationalSettings($false, $false)
        return $true
    }
    catch [System.EntryPointNotFoundException] {
        return $false
    }
}

function Test-InputDllSaveDefaultUserInputSettings {
    Add-InputNativeMethods
    return [CopyUserIntlSettings.InputNativeMethods]::IsSaveDefaultUserInputSettingsAvailable()
}

function Test-IsElevated {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-IntlCopyInternationalSettingsForNewUser {
    try {
        return [CopyUserIntlSettings.NativeMethods]::IntlCopyInternationalSettings($false, $true)
    }
    catch {
        $baseException = $_.Exception.GetBaseException()
        throw "Unable to call intl.cpl!IntlCopyInternationalSettings for NewUser. $($baseException.GetType().FullName): $($baseException.Message)"
    }
}

function Invoke-InputDllSaveDefaultUserInputSettings {
    if (-not (Test-InputDllSaveDefaultUserInputSettings)) {
        throw 'input.dll ordinal 105 (SaveDefaultUserInputSettings) is not available. The Win10 fallback cannot preserve 1:1 NewUser input-settings behavior without it.'
    }

    [CopyUserIntlSettings.InputNativeMethods]::SaveDefaultUserInputSettings()
}

function Copy-RegistryTree {
    param(
        [Parameter(Mandatory = $true)]
        [Microsoft.Win32.RegistryKey]$SourceKey,

        [Parameter(Mandatory = $true)]
        [Microsoft.Win32.RegistryKey]$DestinationKey
    )

    foreach ($valueName in $SourceKey.GetValueNames()) {
        $valueKind = $SourceKey.GetValueKind($valueName)
        $value = $SourceKey.GetValue($valueName, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        $DestinationKey.SetValue($valueName, $value, $valueKind)
    }

    foreach ($subKeyName in $SourceKey.GetSubKeyNames()) {
        $sourceSubKey = $SourceKey.OpenSubKey($subKeyName, $false)
        $destinationSubKey = $DestinationKey.CreateSubKey($subKeyName)
        try {
            Copy-RegistryTree -SourceKey $sourceSubKey -DestinationKey $destinationSubKey
        }
        finally {
            if ($null -ne $destinationSubKey) {
                $destinationSubKey.Dispose()
            }
            if ($null -ne $sourceSubKey) {
                $sourceSubKey.Dispose()
            }
        }
    }
}

function Copy-CurrentUserSubKeyToUsersHive {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceSubKeyPath,

        [Parameter(Mandatory = $true)]
        [string]$TargetUsersSubKeyPath
    )

    $sourceKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($SourceSubKeyPath, $false)
    if ($null -eq $sourceKey) {
        Write-Verbose "Source key HKCU\$SourceSubKeyPath does not exist."
        return
    }

    try {
        $usersHive = [Microsoft.Win32.Registry]::Users
        $usersHive.DeleteSubKeyTree($TargetUsersSubKeyPath, $false)

        $destinationKey = $usersHive.CreateSubKey($TargetUsersSubKeyPath)
        try {
            Copy-RegistryTree -SourceKey $sourceKey -DestinationKey $destinationKey
        }
        finally {
            if ($null -ne $destinationKey) {
                $destinationKey.Dispose()
            }
        }
    }
    finally {
        $sourceKey.Dispose()
    }
}

function Get-CurrentUserRegistryValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceSubKeyPath,

        [Parameter(Mandatory = $true)]
        [string[]]$SourceValueNames
    )

    $sourceKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($SourceSubKeyPath, $false)
    if ($null -eq $sourceKey) {
        return $null
    }

    try {
        foreach ($sourceValueName in $SourceValueNames) {
            $value = $sourceKey.GetValue($sourceValueName, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
            if ($null -ne $value) {
                return [pscustomobject]@{
                    Name = $sourceValueName
                    Value = $value
                    Kind = $sourceKey.GetValueKind($sourceValueName)
                }
            }
        }

        return $null
    }
    finally {
        $sourceKey.Dispose()
    }
}

function Get-FirstMultiStringEntry {
    param(
        [Parameter(Mandatory = $true)]
        $Value
    )

    if ($Value -is [string[]]) {
        if ($Value.Count -eq 0) {
            return $null
        }

        return [string]$Value[0]
    }

    return [string]$Value
}

function Invoke-WithDefaultUserHive {
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$Action
    )

    $tempHiveName = 'CopyUserIntlSettingsDefaultUser'
    $ntUserPath = Join-Path $env:SystemDrive 'Users\Default\NTUSER.DAT'

    if (-not (Test-Path $ntUserPath)) {
        throw "Default User hive was not found at $ntUserPath."
    }

    if (Test-Path "Registry::HKEY_USERS\$tempHiveName") {
        $preUnloadOutput = & reg.exe unload "HKU\$tempHiveName" 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to unload stale Default User hive mount HKU\$tempHiveName. reg.exe exit code $LASTEXITCODE. $preUnloadOutput"
        }
    }

    $loadOutput = & reg.exe load "HKU\$tempHiveName" $ntUserPath 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to load Default User hive '$ntUserPath'. reg.exe exit code $LASTEXITCODE. $loadOutput"
    }

    $actionFailed = $false
    try {
        try {
            & $Action $tempHiveName
        }
        catch {
            $actionFailed = $true
            throw
        }
    }
    finally {
        [gc]::Collect()
        [gc]::WaitForPendingFinalizers()
        $unloadOutput = & reg.exe unload "HKU\$tempHiveName" 2>&1
        if ($LASTEXITCODE -ne 0) {
            $unloadError = "Failed to unload Default User hive. reg.exe exit code $LASTEXITCODE. $unloadOutput"
            if ($actionFailed) {
                Write-Warning $unloadError
            }
            else {
                throw $unloadError
            }
        }
    }
}

function Copy-CurrentUserSubKeyToDefaultUserHive {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceSubKeyPath
    )

    Invoke-WithDefaultUserHive {
        param([Parameter(Mandatory = $true)][string]$TempHiveName)

        Copy-CurrentUserSubKeyToUsersHive `
            -SourceSubKeyPath $SourceSubKeyPath `
            -TargetUsersSubKeyPath "$TempHiveName\$SourceSubKeyPath"
    }
}

function Copy-UserInterfaceSettingsToDefaultUserHive {
    $uiLanguageValue = Get-CurrentUserRegistryValue `
        -SourceSubKeyPath 'Control Panel\Desktop' `
        -SourceValueNames @('PreferredUILanguagesPending', 'PreferredUILanguages')

    if ($null -eq $uiLanguageValue) {
        Write-Verbose 'No current-user PreferredUILanguagesPending or PreferredUILanguages value was found.'
        return
    }

    if ($uiLanguageValue.Kind -ne [Microsoft.Win32.RegistryValueKind]::MultiString) {
        Write-Verbose "Skipping UI language value '$($uiLanguageValue.Name)' because it is $($uiLanguageValue.Kind), not REG_MULTI_SZ."
        return
    }

    $uiLanguage = Get-FirstMultiStringEntry -Value $uiLanguageValue.Value
    if ([string]::IsNullOrEmpty($uiLanguage)) {
        Write-Verbose 'The current-user UI language value is empty.'
        return
    }

    $uiFallbackValue = Get-CurrentUserRegistryValue `
        -SourceSubKeyPath 'Control Panel\Desktop\LanguageConfigurationPending' `
        -SourceValueNames @($uiLanguage)

    if ($null -eq $uiFallbackValue) {
        $uiFallbackValue = Get-CurrentUserRegistryValue `
            -SourceSubKeyPath 'Control Panel\Desktop\LanguageConfiguration' `
            -SourceValueNames @($uiLanguage)
    }

    Invoke-WithDefaultUserHive {
        param([Parameter(Mandatory = $true)][string]$TempHiveName)

        $desktopKey = [Microsoft.Win32.Registry]::Users.CreateSubKey("$TempHiveName\Control Panel\Desktop")
        try {
            $desktopKey.SetValue('PreferredUILanguages', [string[]]@($uiLanguage), [Microsoft.Win32.RegistryValueKind]::MultiString)
        }
        finally {
            if ($null -ne $desktopKey) {
                $desktopKey.Dispose()
            }
        }

        if ($null -ne $uiFallbackValue) {
            if ($uiFallbackValue.Kind -ne [Microsoft.Win32.RegistryValueKind]::MultiString) {
                Write-Verbose "Skipping UI fallback value '$($uiFallbackValue.Name)' because it is $($uiFallbackValue.Kind), not REG_MULTI_SZ."
                return
            }

            $languageConfigurationKey = [Microsoft.Win32.Registry]::Users.CreateSubKey("$TempHiveName\Control Panel\Desktop\LanguageConfiguration")
            try {
                $languageConfigurationKey.SetValue($uiLanguage, $uiFallbackValue.Value, [Microsoft.Win32.RegistryValueKind]::MultiString)
            }
            finally {
                if ($null -ne $languageConfigurationKey) {
                    $languageConfigurationKey.Dispose()
                }
            }
        }
    }
}

function Invoke-NewUserRegistryFallbackCopy {
    Copy-CurrentUserSubKeyToDefaultUserHive -SourceSubKeyPath 'Control Panel\International'
    Invoke-InputDllSaveDefaultUserInputSettings
    Copy-UserInterfaceSettingsToDefaultUserHive
}

if ([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess) {
    throw 'Run this from 64-bit Windows PowerShell on 64-bit Windows.'
}

if ($PSCmdlet.ParameterSetName -eq 'Probe') {
    if (Test-IntlNativeEntryPoint) {
        Write-Output 'intl.cpl!IntlCopyInternationalSettings is available. Probe made no changes.'
        return
    }

    if (Test-InputDllSaveDefaultUserInputSettings) {
        Write-Output 'intl.cpl!IntlCopyInternationalSettings is not available. NewUser fallback can use input.dll ordinal 105 for input settings.'
        return
    }

    throw 'Neither intl.cpl!IntlCopyInternationalSettings nor input.dll ordinal 105 is available. NewUser copy cannot be emulated with 1:1 input-settings behavior.'
}

if (-not $NewUser) {
    throw 'This Win10 compatibility script intentionally supports only -NewUser $true. WelcomeScreen/system-account copy is out of scope.'
}

if (-not (Test-IsElevated)) {
    throw 'Run this script from an elevated PowerShell session. The fallback path loads C:\Users\Default\NTUSER.DAT and requires administrative privileges.'
}

$target = 'default new-user profile'

if ($PSCmdlet.ShouldProcess($target, "Copy current user's international settings")) {
    if (Test-IntlNativeEntryPoint) {
        $result = Invoke-IntlCopyInternationalSettingsForNewUser
        if ($result -ne 0) {
            $message = (New-Object ComponentModel.Win32Exception([int]$result)).Message
            throw "IntlCopyInternationalSettings failed with Win32 error $result ($message)."
        }

        Write-Output "Copied current user's international settings to the default new-user profile using intl.cpl!IntlCopyInternationalSettings."
    }
    else {
        if ($DisableRegistryFallback) {
            throw 'intl.cpl!IntlCopyInternationalSettings is not available, and registry fallback was disabled.'
        }

        Invoke-NewUserRegistryFallbackCopy
        Write-Output "Copied current user's international settings to the default new-user profile using the NewUser registry/input.dll fallback."
    }
}
