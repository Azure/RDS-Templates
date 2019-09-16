---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Remove-RdsAppGroup

## SYNOPSIS
Removes an app group from a host pool. 

## SYNTAX

```
Remove-RdsAppGroup [-TenantName] <String> [-HostPoolName] <String> [-Name] <String> [<CommonParameters>]
```

## DESCRIPTION
The Remove-RdsAppGroup cmdlet removes an app group from the specified host pool. If the specified app group is a RemoteApp app group, you must first remove all RemoteApps published to the app group before running this command.

## EXAMPLES

### Example 1
```powershell
PS C:\> Remove-RdsAppGroup -TenantName "Contoso" -HostPoolName "Contoso Host Pool" -Name "Office Apps"
```
This command removes an app group in the host pool.

## PARAMETERS

### -HostPoolName
The name of the host pool.

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

### -Name
The name of the app group.

```yaml
Type: String
Parameter Sets: (All)
Aliases: AppGroupName

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -TenantName
The name of the tenant.

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

### System.Object
## NOTES

## RELATED LINKS
