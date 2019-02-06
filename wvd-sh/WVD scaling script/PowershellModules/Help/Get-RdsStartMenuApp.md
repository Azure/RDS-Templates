---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Get-RdsStartMenuApp

## SYNOPSIS
This cmdlet returns a list of start menu apps from one of the session hosts in the host pool that contains this app group.  

## SYNTAX

```
Get-RdsStartMenuApp [-TenantName] <String> [-HostPoolName] <String> [-AppGroupName] <String>
 [<CommonParameters>]
```

## DESCRIPTION
This cmdlet returns a list of start menu apps from one of the session hosts in the host pool that contains this app group.  


## EXAMPLES

### Example 1
```powershell
PS C:\> Get-RdsStartMenuApp -TenantName 'Tenant' -HostPoolName 'HostPool' -AppGroupName 'AppGroup'
```

## PARAMETERS

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

### -HostPoolName
Name of HostPool.

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

### -TenantName
Name of Tenant.

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

### Microsoft.RDInfra.RDManagementData.RdMgmtStartMenuApp

## NOTES

## RELATED LINKS
