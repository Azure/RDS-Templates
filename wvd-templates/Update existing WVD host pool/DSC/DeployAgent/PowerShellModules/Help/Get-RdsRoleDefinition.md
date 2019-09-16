---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Get-RdsRoleDefinition

## SYNOPSIS
Lists all roles that are available for assignment.

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
The Get-RdsRoleDefinition cmdlet lists all roles that are available for assignment. You can look at a specific role by providing the name or the id of the role definition. Currently, custom roles are not supported.

## EXAMPLES

### Example 1: List all avilable roles
```powershell
PS C:\> Get-RdsRoleDefinition

RoleDefinitionName : RDS Owner
Id                 : 3b14baea-8d82-4610-f5da-08d623dd1cc4
Scope              : /
IsCustom           : False
Description        : Can perform all operations on any RDS objects.
Actions            : {*}
AssignableScopes   : {}
Item               :

RoleDefinitionName : RDS Reader
Id                 : 2ea11dc0-46e3-4ee8-f5db-08d623dd1cc4
Scope              : /
IsCustom           : False
Description        : Can Read properties of RDS objects
Actions            : {*/Read}
AssignableScopes   : {}
Item               :

RoleDefinitionName : RDS Contributor
Id                 : f5dc85e1-b94d-48f0-f5dc-08d623dd1cc4
Scope              : /
IsCustom           : False
Description        : Can perform all operations on any RDS object, except role assignment
Actions            : {Microsoft.RDS.Resources/*, Microsoft.RDS.Diagnostics/*}
AssignableScopes   : {}
Item               :

RoleDefinitionName : RDS Operator
Id                 : 827a079d-aa89-4d0d-f5dd-08d623dd1cc4
Scope              : /
IsCustom           : False
Description        : Can Read diagnostics information.
Actions            : {Microsoft.RDS.Diagnostics/Read}
AssignableScopes   : {}
Item               :
```
This command lists 

## PARAMETERS

### -AppGroupName
The name of the app group.

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
The name of the host pool.

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
The id for the specific role definition.

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
The name of the role definition. Default role definition names include:
- RDS Owner
- RDS Reader
- RDS Contributor
- RDS Operator

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
The name of the tenant group.

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
The name of the tenant.

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
