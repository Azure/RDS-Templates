---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Get-RdsRoleDefinition

## SYNOPSIS


## SYNTAX

### EmptyParameterSet (Default)
```
Get-RdsRoleDefinition [-RoleDefinitionName <String>] [-TenantGroupName <String>] [-TenantName <String>]
 [-HostPoolName <String>] [-AppGroupName <String>] [<CommonParameters>]
```

### RoleDefinitionNameParameterSet
```
Get-RdsRoleDefinition [-RoleDefinitionName <String>] [-TenantGroupName <String>] [-TenantName <String>]
 [-HostPoolName <String>] [-AppGroupName <String>] [<CommonParameters>]
```

### RoleDefinitionIdParameterSet
```
Get-RdsRoleDefinition -Id <Guid> [-TenantGroupName <String>] [-TenantName <String>] [-HostPoolName <String>]
 [-AppGroupName <String>] [<CommonParameters>]
```

## DESCRIPTION


## EXAMPLES

### Example 1
```powershell
PS C:\>
```

## PARAMETERS

### -AppGroupName
Name of AppGroup.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -HostPoolName
Name of HostPool.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Id
Role definition id.

```yaml
Type: Guid
Parameter Sets: RoleDefinitionIdParameterSet
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -RoleDefinitionName
Role definition name.
For e.g.
RDS Reader, RDS Contributor, RDS Owner.

```yaml
Type: String
Parameter Sets: EmptyParameterSet, RoleDefinitionNameParameterSet
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -TenantGroupName
Name of TenantGroup.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -TenantName
Name of Tenant.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

### System.Guid

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
