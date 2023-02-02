# RegisterPackageDemo.ps1

Registers an App Attach Package for the current user.

The MSIX Package full name is the name of the directory for the newly staged application under 'C:\Program Files\WindowsApps'

## Syntax

```PowerShell
RegisterPackageDemo.ps1
    [-MsixPackageFullName] <string>
    [<CommonParameters>]
```

## Description

Here is an example of a MSIX Package Full Name: Microsoft.PowerShell_7.3.2.0_x64__8wekyb3d8bbwe

If you cannot see the package name under the Windows Apps directory, it was not successfully staged.

## Examples

### EXAMPLE 1

```PowerShell
RegisterPackageDemo.ps1 -MsixPackageFullName 'MyMsixAppFullName'
```

Registers a package for the current user

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
