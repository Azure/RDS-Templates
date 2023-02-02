# DeRegisterPackageDemo.ps1

DeRegisters an App Attach Package for the current user.

The MSIX Package full name is the name of the directory for the newly staged application under 'C:\Program Files\WindowsApps'

## Syntax

```PowerShell
DeRegisterPackageDemo.ps1
    [-MsixPackageFullName] <string>
    [-Passthru] <switch>
    [<CommonParameters>]
```

## Description

Here is an example of a MSIX Package Full Name: Microsoft.PowerShell_7.3.2.0_x64__8wekyb3d8bbwe

If you cannot see the package name under the Windows Apps directory, it was not successfully staged.

## Examples

### EXAMPLE 1

```PowerShell
DeRegisterPackageDemo.ps1 -MsixPackageFullName 'MyMsixAppFullName' -PassThru
```

DeRegisters a package for the current user and outputs the deviceId needed to destage the package

### EXAMPLE 2

```PowerShell
DeRegisterPackageDemo.ps1 -MsixPackageFullName 'MyMsixAppFullName'
```

DeRegisters a package for the current user

## Parameters

### -MsixPackageFullName

Specifies the MSIX Package Full Name.

|  | |
|---|---|
| Type:    | String |
| Position: | 0 |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |

### -PassThru

Outputs the MSIX Package Full Name and the Volume Device ID to the pipeline

|  | |
|---|---|
| Type:    | SwitchParameter |
| Position: | Named |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
