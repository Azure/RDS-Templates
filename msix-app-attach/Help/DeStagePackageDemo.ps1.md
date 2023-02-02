# DeStagePackageDemo.ps1

DeStages an App Attach Package on the system

## Syntax

```PowerShell
DeStagePackageDemo.ps1
    [-MsixPackageFullName] <String>
    [-DeviceId] <String>
    [<CommonParameters>]
```

## Description

When given a Msix Package Full Name it will dismount the disk image to the VM and Destage the application, optionally you can also specify the volume Device Id to ensure the disk is dismounted.  IF you use the deviceID it will ensure the disk is unmounted in all scenarios.  Without it there are scenarios where the package is destaged but not dismounted.

## Examples

### EXAMPLE 1

```PowerShell
DeStagePackageDemo.ps1 -MsixPackageFullName 'MyMsixAppFullName'
```

DeStages a package

### EXAMPLE 2

```PowerShell
DeStagePackageDemo.ps1 -MsixPackageFullName 'MyMsixAppFullName' -DeviceId '\\?\Volume{9b95da08-a0e9-41c8-b462-7c8dcdc5033f}\'
```

DeStages a package when the deviceID is needed

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

### -DeviceId

Specifies the DeviceId of a volume.

|  | |
|---|---|
| Type:    | String |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
