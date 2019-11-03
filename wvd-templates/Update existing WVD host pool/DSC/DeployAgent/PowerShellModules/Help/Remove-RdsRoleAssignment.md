---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Remove-RdsRoleAssignment

## SYNOPSIS
Removes a role assignment.

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

The Remove-RdsRoleAssignment cmdlet removes a role assignment by specifying the three properties of a role assignment: the role, the principal, and the scope.

To define the role, you can use one of the following parameters:
- RDS Owner
- RDS Contributor
- RDS Reader
- RDS Operator

To specify the principal, you can use one of the following parameters:
- SignInName
- ApplicationId
- GroupObjectId

To define the scope, you can use a combination of the following parameters:
- TenantGroupName
- TenantName
- HostPoolName
- AppGroupName

## EXAMPLES

### Example 1: Remove a role assignment for a user
```powershell
PS C:\> Remove-RdsRoleAssignment -RoleDefinitionName "RDS Owner" -SignInName "admin@contoso.com" -TenantGroupName "Default Tenant Group" -TenantName "Contoso" -HostPoolName "Contoso Host Pool" -AppGroupName "Desktop Application Group"
```
This command removes the role assignment for admin@contoso.com who is assigned to the RDS Owner role at the "Desktop Application Group" app group scope.

### Example 2: Remove a role assignment for a service principal
```powershell
PS C:\> Remove-RdsRoleAssignment -RoleDefinitionName "RDS Reader" -ApplicationId "yyyy-yyyy-yyyy-yyyy-yyyy" -TenantGroupName "Contoso Tenant Group" -TenantName "Contoso A" -HostPoolName "Contoso A Host Pool"
```
This command removes the role assignment for the specified service principal who is assigned to the RDS Reader role at the "Contoso A Host Pool" host pool scope.

### Example 3: Remove a role assignment for an Azure AD group
```powershell
PS C:\> Remove-RdsRoleAssignment -RoleDefinitionName "RDS Operator" -GroupObjectId "aaaa-aaaa-aaaa-aaaa-aaaa" -TenantGroupName "Contoso Tenant Group" -TenantName "Contoso A"
```
This command removes the role assignment for the specified Azure AD group who is assigned to the RDS Operator role at the "Contoso A" tenant scope.

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

### -ApplicationId
The application ID of the service principal.

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
The object ID of the Azure AD group.

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

### -RoleDefinitionName
The name of the role.

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
The user principal name (UPN) of the user.

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

### -Deployment
A scope specific to Windows Virtual Desktop.

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
