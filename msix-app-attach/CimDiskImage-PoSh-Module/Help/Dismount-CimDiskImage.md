# Dismount-CimDiskImage

Dismounts a cimfs disk image from your system.

## Syntax

```PowerShell
Dismount-CimDiskImage
    [-DeviceId] <String[]>
    [<CommonParameters>]
```

## Description

When the volume DeviceId is supplied as a parameter it will remove the mount point if it exists and then dismount the cimfs volume. This will only work on Cim Disk Image files.  It will also dismount cimfs volumes with no mount point.

## Examples

### EXAMPLE 1

```PowerShell
Dismount-CimDiskImage -DeviceId '\\?\Volume{d342880f-3a74-4a9a-be74-2c67e2b3862d}\'
```

Dismounts a volume by DeviceId

### EXAMPLE 2

```PowerShell
Get-CimDiskImage C:\MyMountPoint | Dismount-CimDiskImage
```

Dismounts a volume by path

### EXAMPLE 3

```PowerShell
Get-CimDiskImage | Dismount-CimDiskImage
```

Dismounts all Cimfs volumes

### EXAMPLE 4

```PowerShell
Get-CimInstance -ClassName win32_volume | Where-Object { $_.FileSystem -eq 'cimfs' } | Dismount-CimDiskImage
```

Dismounts all Cimfs volumes

## Parameters

### -DeviceId

Specifies the device ID of the volume, an example of which is: \\\\?\Volume{d342880f-3a74-4a9a-be74-2c67e2b3862d}\

|  | |
|---|---|
| Type:    | String |
| Position: | 0 |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
