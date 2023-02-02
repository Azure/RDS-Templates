# StagePackageDemo.ps1

Stages an App Attach Package on the system

## Syntax

```PowerShell
StagePackageDemo.ps1
    [-Path] <System.IO.FileInfo[]>
    [<CommonParameters>]
```

## Description

When given a UNC path to an MSIX App Attach disk image in cim or vhd(x) format it will mount the disk image to the VM and stage the application, this does not make the application visible to any user, you must also register the application for each user.

Remember that the computer account will need permission to the share and file.

## Examples

### EXAMPLE 1

```PowerShell
StagePackageDemo.ps1 -Path '\\MyServer\MyShare\MyApp.vhdx'
```

Stages a package in vhdx format

### EXAMPLE 2

```PowerShell
StagePackageDemo.ps1 -Path '\\MyServer\MyShare\MyApp.cim'
```

Stages a package in cim format

## Parameters

### -Path

Specifies the UNC path of the disk Image.

|  | |
|---|---|
| Type:    | System.IO.FileInfo |
| Position: | 0 |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
