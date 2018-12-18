---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Get-RdsAppGroup

## SYNOPSIS
Returns the properties of an app group.

## SYNTAX

```
Get-RdsAppGroup [-TenantName] <String> [-HostPoolName] <String> [-Name <String>] [<CommonParameters>]
```

## DESCRIPTION
The Get-RdsAppGroup cmdlet returns the properties of the specified app group. If you do not specify an app group name, this cmdlet returns properties for all app groups in the specified hostpool.

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-RdsAppGroup -TenantName 'wfdtenant' -HostPoolName 'wfdhostpool' -Name 'wfdappgroup'
```

With named parameters for a specific AppGroup.

### Example 2
```powershell
PS C:\> Get-RdsAppGroup 'wfdtenant' 'wfdhostpool' -Name 'wfdappgroup'
```

Without named parameters for a specific AppGroup.

### Example 3
```powershell
PS C:\> Get-RdsAppGroup 'wfdtenant' 'wfdhostpool' -AppGroupName 'wfdappgroup'
```

Without named parameters for a specific AppGroup and using alias for AppGroup name.

### Example 4
```powershell
PS C:\> Get-RdsAppGroup -TenantName 'wfdtenant' -HostPoolName 'wfdhostpool'
```

With named parameters and return a list of AppGroups.

## PARAMETERS

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

### -Name
Name of AppGroup.

```yaml
Type: String
Parameter Sets: (All)
Aliases: AppGroupName

Required: False
Position: Named
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

### Microsoft.RDInfra.RDManagementData.RdMgmtAppGroup

## NOTES

## RELATED LINKS
