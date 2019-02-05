---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Remove-RdsRoleAssignment

## SYNOPSIS


## SYNTAX

### EmptyParameterSet (Default)
```
Remove-RdsRoleAssignment [-TenantGroupName <String>] [-TenantName <String>] [-HostPoolName <String>]
 [-AppGroupName <String>] [<CommonParameters>]
```

### SignInNameParameterSet
```
Remove-RdsRoleAssignment [-RoleDefinitionName] <String> -SignInName <String> [-TenantGroupName <String>]
 [-TenantName <String>] [-HostPoolName <String>] [-AppGroupName <String>] [<CommonParameters>]
```

### ServicePrincipalParameterSet
```
Remove-RdsRoleAssignment [-RoleDefinitionName] <String> -ApplicationId <String> [-TenantGroupName <String>]
 [-TenantName <String>] [-HostPoolName <String>] [-AppGroupName <String>] [<CommonParameters>]
```

### GroupObjectIdParameterSet
```
Remove-RdsRoleAssignment [-RoleDefinitionName] <String> -GroupObjectId <String> [-TenantGroupName <String>]
 [-TenantName <String>] [-HostPoolName <String>] [-AppGroupName <String>] [<CommonParameters>]
```

## DESCRIPTION

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

## PARAMETERS

### -AppGroupName
Application group name

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

### -ApplicationId
The app SPN.

```yaml
Type: String
Parameter Sets: ServicePrincipalParameterSet
Aliases: SPN, ServicePrincipalName

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -GroupObjectId
User Group object id from AAD to uniquely identify user groups.

```yaml
Type: String
Parameter Sets: GroupObjectIdParameterSet
Aliases: UserGroupObjectId

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -HostPoolName
Host pool name

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

### -RoleDefinitionName
Role definition name.
For e.g.
RDS Reader, RDS Contributor, RDS Owner.

```yaml
Type: String
Parameter Sets: SignInNameParameterSet, ServicePrincipalParameterSet, GroupObjectIdParameterSet
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -SignInName
The user SignInName.

```yaml
Type: String
Parameter Sets: SignInNameParameterSet
Aliases: Email, UserPrincipalName

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -TenantGroupName
Tenant Group name

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
Tenant name

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

### -Deployment
Scope level.

```yaml
Type: Switch
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
