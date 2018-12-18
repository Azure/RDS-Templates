---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Set-RdsRemoteApp

## SYNOPSIS
Modifies the settings for a RemoteApp program.

## SYNTAX

### RA1 (Default)
```
Set-RdsRemoteApp [-TenantName] <String> [-HostPoolName] <String> [-AppGroupName] <String> [-Name] <String>
 [-FilePath <String>] [-CommandLineSetting <CommandLineSetting>] [-Description <String>]
 [-FileVirtualPath <String>] [-FolderName <String>] [-FriendlyName <String>] [-IconIndex <Int32>]
 [-IconPath <String>] [-RequiredCommandLine <String>] [-ShowInWebFeed] [<CommonParameters>]
```

### RA2
```
Set-RdsRemoteApp [-TenantName] <String> [-HostPoolName] <String> [-AppGroupName] <String> [-Name] <String>
 [-CommandLineSetting <CommandLineSetting>] [-Description <String>] [-FileVirtualPath <String>]
 [-FolderName <String>] [-FriendlyName <String>] [-IconIndex <Int32>] [-IconPath <String>]
 [-RequiredCommandLine <String>] [-ShowInWebFeed] [-AppAlias <String>] [<CommonParameters>]
```

## DESCRIPTION
Modifies the settings for a RemoteApp program.

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```


## PARAMETERS

### -AppAlias


```yaml
Type: String
Parameter Sets: RA2
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AppGroupName
Name of AppGroup.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -CommandLineSetting


```yaml
Type: CommandLineSetting
Parameter Sets: (All)
Aliases:
Accepted values: Allow, DoNotAllow, Require

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description


```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FilePath


```yaml
Type: String
Parameter Sets: RA1
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FileVirtualPath


```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FolderName


```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FriendlyName


```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -HostPoolName


```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -IconIndex


```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IconPath


```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name


```yaml
Type: String
Parameter Sets: (All)
Aliases: RemoteAppName

Required: True
Position: 3
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -RequiredCommandLine


```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ShowInWebFeed


```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TenantName


```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

## OUTPUTS

### Microsoft.RDInfra.RDManagementData.RdMgmtRemoteApp

## NOTES

## RELATED LINKS
