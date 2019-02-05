---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Set-RdsHostPool

## SYNOPSIS
Sets the properties of the host pool specified by the Name parameter. Three parameter sets exist for this cmdlet. First is used to disable user profile disks. The second is used to enable user profile disks. The third is used to set all other properties of the host pool. 

## SYNTAX

### HP4 (Default)
```
Set-RdsHostPool [-TenantName] <String> [-Name] <String> [-FriendlyName <String>] [-Description <String>]
 [-MaxSessionLimit <Int32>] [<CommonParameters>]
```

### HP1
```
Set-RdsHostPool [-TenantName] <String> [-Name] <String> [-DisableUserProfileDisk] [<CommonParameters>]
```

### HP2
```
Set-RdsHostPool [-TenantName] <String> [-Name] <String> [-DiskPath <String>] [-EnableUserProfileDisk]
 [-ExcludeFolderPath <String[]>] [-ExcludeFilePath <String[]>] [-IncludeFilePath <String[]>]
 [-IncludeFolderPath <String[]>] [<CommonParameters>]
```

### HP5
```
Set-RdsHostPool [-TenantName] <String> [-Name] <String> [-BreadthFirstLoadBalancer] [-MaxSessionLimit <Int32>]
 [<CommonParameters>]
```

### HP6
```
Set-RdsHostPool [-TenantName] <String> [-Name] <String> [-DepthFirstLoadBalancer] -MaxSessionLimit <Int32>
 [<CommonParameters>]
```

### HP3
```
Set-RdsHostPool [-TenantName] <String> [-Name] <String> [-CustomRdpProperty <String>]
 [-UseReverseConnect <Boolean>] [<CommonParameters>]
```

## DESCRIPTION
Sets the properties of the host pool specified by the Name parameter. Three parameter sets exist for this cmdlet. First is used to disable user profile disks. The second is used to enable user profile disks. The third is used to set all other properties of the host pool. 

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```


## PARAMETERS

### -BreadthFirstLoadBalancer


```yaml
Type: SwitchParameter
Parameter Sets: HP5
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CustomRdpProperty
Specifies Remote Desktop Protocol (RDP) settings to include in the .rdp files for all RemoteApp programs and remote desktops published in this collection. 

```yaml
Type: String
Parameter Sets: HP3
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -DepthFirstLoadBalancer


```yaml
Type: SwitchParameter
Parameter Sets: HP6
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description


```yaml
Type: String
Parameter Sets: HP4
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DisableUserProfileDisk


```yaml
Type: SwitchParameter
Parameter Sets: HP1
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DiskPath

```yaml
Type: String
Parameter Sets: HP2
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EnableUserProfileDisk


```yaml
Type: SwitchParameter
Parameter Sets: HP2
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExcludeFilePath


```yaml
Type: String[]
Parameter Sets: HP2
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExcludeFolderPath


```yaml
Type: String[]
Parameter Sets: HP2
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
Parameter Sets: HP4
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeFilePath


```yaml
Type: String[]
Parameter Sets: HP2
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeFolderPath


```yaml
Type: String[]
Parameter Sets: HP2
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaxSessionLimit


```yaml
Type: Int32
Parameter Sets: HP4, HP5
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: Int32
Parameter Sets: HP6
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name


```yaml
Type: String
Parameter Sets: (All)
Aliases: HostPoolName

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
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

### -UseReverseConnect


```yaml
Type: Boolean
Parameter Sets: HP3
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

## OUTPUTS

### Microsoft.RDInfra.RDManagementData.RdMgmtHostPool

## NOTES

## RELATED LINKS
