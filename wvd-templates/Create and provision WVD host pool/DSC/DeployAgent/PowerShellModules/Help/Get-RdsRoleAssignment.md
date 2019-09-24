---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Get-RdsRoleAssignment

## SYNOPSIS
Lists role assignments at a defined scope.

## SYNTAX

### EmptyParameterSet (Default)
```
Get-RdsRoleAssignment [-SignInName <String>] [-TenantGroupName <String>] [-TenantName <String>]
 [-HostPoolName <String>] [-AppGroupName <String>] [<CommonParameters>]
```

### SignInNameParameterSet
```
Get-RdsRoleAssignment [-SignInName <String>] [-TenantGroupName <String>] [-TenantName <String>]
 [-HostPoolName <String>] [-AppGroupName <String>] [<CommonParameters>]
```

### ServicePrincipalParameterSet
```
Get-RdsRoleAssignment [-ServicePrincipalName <String>] [-TenantGroupName <String>] [-TenantName <String>]
 [-HostPoolName <String>] [-AppGroupName <String>] [<CommonParameters>]
```

### GroupObjectIdParameterSet
```
Get-RdsRoleAssignment [-GroupObjectId <String>] [-TenantGroupName <String>] [-TenantName <String>]
 [-HostPoolName <String>] [-AppGroupName <String>] [<CommonParameters>]
```

## DESCRIPTION
The Get-RdsRoleAssignment cmdlet lists all role assignments at the defined scope. Without any parameters, this command returns all the role assignments starting at the highest scope authorized to the current user. To define the scope, you can use a combination of the following parameters:
- TenantGroupName
- TenantName
- HostPoolName
- AppGroupName

This list can be also be filtered by specifying the principal of the role assignment. To specify the principal, you can use one of the following parameters:
- SignInName
- ServicePrincipalName
- GroupObjectId

## EXAMPLES

### Example 1: List all role assignments
```powershell
PS C:\> Get-RdsRoleAssignment

RoleAssignmentId   : cccc-cccc-cccc-cccc-cccc
Scope              : /Default Tenant Group/Contoso/Contoso Host Pool/Desktop Application Group
TenantGroupName    : Default Tenant Group
TenantName         : Contoso
HostPoolName       : Contoso Host Pool
AppGroupName       : Desktop Application Group
DisplayName        : admin
SignInName         : admin@contoso.com
GroupObjectId      : aaaa-aaaa-aaaa-aaaa-aaaa
AADTenantId        : xxxx-xxxx-xxxx-xxxx-xxxx
AppId              : yyyy-yyyy-yyyy-yyyy-yyyy
RoleDefinitionName : RDS Owner
RoleDefinitionId   : 3b14baea-8d82-4610-f5da-08d623dd1cc4
ObjectId           : bbbb-bbbb-bbbb-bbbb-bbbb
ObjectType         : User
Item               :

RoleAssignmentId   : cccc-cccc-cccc-cccc-cccc
Scope              : /Default Tenant Group/Contoso
TenantGroupName    : Contoso Tenant Group
TenantName         : Contoso
HostPoolName       : 
AppGroupName       : 
DisplayName        : 
SignInName         : 
GroupObjectId      : 0000-0000-0000-0000-0000
AADTenantId        : 0000-0000-0000-0000-0000
AppId              : yyyy-yyyy-yyyy-yyyy-yyyy
RoleDefinitionName : RDS Reader
RoleDefinitionId   : 3b14baea-8d82-4610-f5da-08d623dd1cc4
ObjectId           : bbbb-bbbb-bbbb-bbbb-bbbb
ObjectType         : ServicePrincipal
Item               :
```
This command gets all role assignments in the current context, starting at the highest scope authorized for the current user.

### Example 2: List role assignments for a user
```powershell
PS C:\> Get-RdsRoleAssignment -SignInName "admin@contoso.com"

RoleAssignmentId   : cccc-cccc-cccc-cccc-cccc
Scope              : /Contoso Tenant Group/Contoso A/Contoso A Host Pool/Desktop Application Group
TenantGroupName    : Contoso Tenant Group
TenantName         : Contoso A
HostPoolName       : Contoso A Host Pool
AppGroupName       : Desktop Application Group
DisplayName        : admin
SignInName         : admin@contoso.com
GroupObjectId      : aaaa-aaaa-aaaa-aaaa-aaaa
AADTenantId        : 0000-0000-0000-0000-0000
AppId              : yyyy-yyyy-yyyy-yyyy-yyyy
RoleDefinitionName : RDS Owner
RoleDefinitionId   : 3b14baea-8d82-4610-f5da-08d623dd1cc4
ObjectId           : bbbb-bbbb-bbbb-bbbb-bbbb
ObjectType         : User
Item               :

RoleAssignmentId   : cccc-cccc-cccc-cccc-cccc
Scope              : /Contoso Tenant Group/Contoso B/Contoso B Host Pool/Desktop Application Group
TenantGroupName    : Contoso Tenant Group
TenantName         : Contoso B
HostPoolName       : Contoso B Host Pool
AppGroupName       : Desktop Application Group
DisplayName        : admin
SignInName         : admin@contoso.com
GroupObjectId      : aaaa-aaaa-aaaa-aaaa-aaaa
AADTenantId        : 0000-0000-0000-0000-0000
AppId              : yyyy-yyyy-yyyy-yyyy-yyyy
RoleDefinitionName : RDS Reader
RoleDefinitionId   : 2ea11dc0-46e3-4ee8-f5db-08d623dd1cc4
ObjectId           : bbbb-bbbb-bbbb-bbbb-bbbb
ObjectType         : User
Item               :
```
This command gets all role assignments for the specified user in the current context.

### Example 3: List role assignments for a service principal
```powershell
PS C:\> Get-RdsRoleAssignment -ServicePrincipalName "yyyy-yyyy-yyyy-yyyy-yyyy"

RoleAssignmentId   : cccc-cccc-cccc-cccc-cccc
Scope              : /Contoso Tenant Group/Contoso A/Contoso A Host Pool/Desktop Application Group
TenantGroupName    : Contoso Tenant Group
TenantName         : Contoso A
HostPoolName       : Contoso A Host Pool
AppGroupName       : 
DisplayName        : 
SignInName         : 
GroupObjectId      : 0000-0000-0000-0000-0000
AADTenantId        : 0000-0000-0000-0000-0000
AppId              : yyyy-yyyy-yyyy-yyyy-yyyy
RoleDefinitionName : RDS Reader
RoleDefinitionId   : 2ea11dc0-46e3-4ee8-f5db-08d623dd1cc4
ObjectId           : bbbb-bbbb-bbbb-bbbb-bbbb
ObjectType         : ServicePrincipal
Item               :

RoleAssignmentId   : cccc-cccc-cccc-cccc-cccc
Scope              : /Contoso Tenant Group/Contoso B/Contoso B Host Pool/Desktop Application Group
TenantGroupName    : Contoso Tenant Group
TenantName         : Contoso B
HostPoolName       : Contoso B Host Pool
AppGroupName       : Desktop Application Group
DisplayName        : 
SignInName         : 
GroupObjectId      : 0000-0000-0000-0000-0000
AADTenantId        : 0000-0000-0000-0000-0000
AppId              : yyyy-yyyy-yyyy-yyyy-yyyy
RoleDefinitionName : RDS Owner
RoleDefinitionId   : 3b14baea-8d82-4610-f5da-08d623dd1cc4
ObjectId           : bbbb-bbbb-bbbb-bbbb-bbbb
ObjectType         : ServicePrincipal
Item               :
```
This command gets all role assignments for the specified service principal in the current context. You must provide the application ID of the service principal as the value of the parameter.

### Example 4: List role assignments for an Azure AD group
```powershell
PS C:\> Get-RdsRoleAssignment -GroupObjectId "aaaa-aaaa-aaaa-aaaa-aaaa"

RoleAssignmentId   : cccc-cccc-cccc-cccc-cccc
Scope              : /Contoso Tenant Group/Contoso A
TenantGroupName    : Contoso Tenant Group
TenantName         : Contoso A
HostPoolName       : 
AppGroupName       : 
DisplayName        : 
SignInName         : 
GroupObjectId      : aaaa-aaaa-aaaa-aaaa-aaaa
AADTenantId        : dddd-dddd-dddd-dddd-dddd
AppId              : 
RoleDefinitionName : RDS Operator
RoleDefinitionId   : 827a079d-aa89-4d0d-f5dd-08d623dd1cc4
ObjectId           : bbbb-bbbb-bbbb-bbbb-bbbb
ObjectType         : Group
Item               :

RoleAssignmentId   : cccc-cccc-cccc-cccc-cccc
Scope              : /Contoso Tenant Group/Contoso B/Contoso B Host Pool/Desktop Application Group
TenantGroupName    : Contoso Tenant Group
TenantName         : Contoso B
HostPoolName       : Contoso B Host Pool
AppGroupName       : Desktop Application Group
DisplayName        : 
SignInName         : 
GroupObjectId      : aaaa-aaaa-aaaa-aaaa-aaaa
AADTenantId        : dddd-dddd-dddd-dddd-dddd
AppId              : 
RoleDefinitionName : RDS Owner
RoleDefinitionId   : 3b14baea-8d82-4610-f5da-08d623dd1cc4
ObjectId           : bbbb-bbbb-bbbb-bbbb-bbbb
ObjectType         : Group
Item               :
```
This command gets all role assignments for the specified Azure AD group in the current context.

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

### -GroupObjectId
The object ID of the Azure AD group to filter for role assignments.

```yaml
Type: String
Parameter Sets: GroupObjectIdParameterSet
Aliases: UserGroupObjectId

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

### -ServicePrincipalName
The application ID of the service principal to filter for role assignments.

```yaml
Type: String
Parameter Sets: ServicePrincipalParameterSet
Aliases: SPN, ApplicationId

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -SignInName
The user principal name (UPN) of the user to filter for role assignments.

```yaml
Type: String
Parameter Sets: EmptyParameterSet, SignInNameParameterSet
Aliases: Email, UserPrincipalName

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
