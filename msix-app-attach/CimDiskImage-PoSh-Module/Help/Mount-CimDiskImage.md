# Mount-CimDiskImage

Mounts a cimfs disk image file to your system.

## Syntax

```PowerShell
Mount-CimDiskImage
    [-ImagePath] <String>
    [-DriveLetter] <String>
    [-PassThru]
    [<CommonParameters>]
```

```PowerShell
Mount-CimDiskImage
    [-ImagePath] <String>
    [-MountPath] <String>
    [-PassThru]
    [<CommonParameters>]
```

## Description

This will mount a cim file to a drive letter or directory of your choosing, allowing you to browse the contents. Remember to use the -PassThru Parameter to get output

## Examples

### EXAMPLE 1

```PowerShell
Mount-CimDiskImage -ImagePath C:\MyCimFile.cim -MountPath C:\MyMountPath -Passthru
```

Mounts the Cim file to a local directory and sends the result to the pipeline

### EXAMPLE 2

```PowerShell
Mount-CimDiskImage C:\MyCimFile.cim -MountPath C:\MyMountPath
```

Mounts the Cim Disk Image file to a local directory

### EXAMPLE 3

```PowerShell
Mount-CimDiskImage C:\MyCimFile.cim -MountPath C:\MyMountPath
```

Mounts the Cim Disk Image file to a local directory

### EXAMPLE 4

```PowerShell
Mount-CimDiskImage C:\MyCimFile.cim -DriveLetter X:
```

Mounts the Cim Disk Image file to the specified Drive

### EXAMPLE 5

```PowerShell
Mount-CimDiskImage C:\MyCimFile.cim -DriveLetter X: -PassThru | Get-CimDiskImage
```

Returns the details for the cimfs volume which has just been mounted

### EXAMPLE 6

```PowerShell
Get-ChildItem C:\MyCimFile.cim | Mount-CimDiskImage -MountPath C:\MyMountPath -Passthru
```

Mounts the Cim Disk Image file to a local directory and outputs the results to the pipeline

### EXAMPLE 7

```PowerShell
'C:\MyCimFile.cim' | Mount-CimDiskImage -DriveLetter X: -PassThru
```

Mounts the Cim Disk Image file to the specified drive and outputs the results to the pipeline

### EXAMPLE 8

```PowerShell
Mount-CimDiskImage -ImagePath C:\MyCimFile.cim -NoMountPath -PassThru
```

Mounts the Cim Disk Image file to a volume without mounting to the filesystem and outputs the results to the pipeline

## Parameters

### -ImagePath

Specifies the location of the Cim Disk Image file to be mounted.

|  | |
|---|---|
| Type:    | String |
| Aliases: | Fullname |
| Position: | 0 |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |

### -DriveLetter

Specifies the Drive letter which the Cim Disk Image file should be mounted to.  It can be in the format 'X:' or 'X:\'

|  | |
|---|---|
| Type:    | String |
| Position: | Named |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |

### -MountPath

Specifies the local folder to which the Cim Disk Image file will be mounted.  This folder needs to exist and be empty prior to attempting to mount a cim file to it.

|  | |
|---|---|
| Type:    | String |
| Position: | Named |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |

### -NoMountPath

Specifies that the volume will be attached but no filesystem mountpath will be created.

|  | |
|---|---|
| Type:    | SwitchParameter |
| Position: | Named |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |

### -PassThru

Specifies the local folder to which the Cim Disk Image file will be mounted.  This folder needs to exist and be empty prior to attempting to mount a Cim Disk Image file to it.

|  | |
|---|---|
| Type:    | SwitchParameter |
| Position: | Named |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
