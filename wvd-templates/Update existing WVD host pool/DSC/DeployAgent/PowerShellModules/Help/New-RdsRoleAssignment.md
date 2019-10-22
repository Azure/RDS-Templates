---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# New-RdsRoleAssignment

## SYNOPSIS
Creates a role assignment.

## SYNTAX

### EmptyParameterSet (Default)
```
New-RdsRoleAssignment [<CommonParameters>]
```

### SignInNameRoleAssignmentDeploymentScopeParameterSet
```
New-RdsRoleAssignment [-RoleDefinitionName] <String> -SignInName <String> -AADTenantId <String> [-Deployment]
 [<CommonParameters>]
```

### SignInNameRoleAssignmentTenantGroupScopeParameterSet
```
New-RdsRoleAssignment [-RoleDefinitionName] <String> -SignInName <String> -TenantGroupName <String>
 -AADTenantId <String> [<CommonParameters>]
```

### SignInNameRoleAssignmentTenantScopeParameterSet
```
New-RdsRoleAssignment [-RoleDefinitionName] <String> -SignInName <String> [-TenantGroupName <String>]
 -TenantName <String> [-AADTenantId <String>] [<CommonParameters>]
```

### SignInNameRoleAssignmentHostPoolScopeParameterSet
```
New-RdsRoleAssignment [-RoleDefinitionName] <String> -SignInName <String> [-TenantGroupName <String>]
 -TenantName <String> -HostPoolName <String> [-AADTenantId <String>] [<CommonParameters>]
```

### SignInNameRoleAssignmentAppGroupScopeParameterSet
```
New-RdsRoleAssignment [-RoleDefinitionName] <String> -SignInName <String> [-TenantGroupName <String>]
 -TenantName <String> -HostPoolName <String> -AppGroupName <String> [-AADTenantId <String>]
 [<CommonParameters>]
```

### SPNRoleAssignmentDeploymentScopeParameterSet
```
New-RdsRoleAssignment [-RoleDefinitionName] <String> -ApplicationId <String> [-Deployment] [<CommonParameters>]
```

### SPNRoleAssignmentTenantGroupScopeParameterSet
```
New-RdsRoleAssignment [-RoleDefinitionName] <String> -ApplicationId <String> -TenantGroupName <String>
 [<CommonParameters>]
```

### SPNRoleAssignmentTenantScopeParameterSet
```
New-RdsRoleAssignment [-RoleDefinitionName] <String> -ApplicationId <String> [-TenantGroupName <String>]
 -TenantName <String> [<CommonParameters>]
```

### SPNRoleAssignmentHostPoolScopeParameterSet
```
New-RdsRoleAssignment [-RoleDefinitionName] <String> -ApplicationId <String> [-TenantGroupName <String>]
 -TenantName <String> -HostPoolName <String> [<CommonParameters>]
```

### SPNRoleAssignmentAppGroupScopeParameterSet
```
New-RdsRoleAssignment [-RoleDefinitionName] <String> -ApplicationId <String> [-TenantGroupName <String>]
 -TenantName <String> -HostPoolName <String> -AppGroupName <String> [<CommonParameters>]
```

### GroupRoleAssignmentDeploymentScopeParameterSet
```
New-RdsRoleAssignment [-RoleDefinitionName] <String> -GroupObjectId <String> -AADTenantId <String>
 [-Deployment] [<CommonParameters>]
```

### GroupRoleAssignmentTenantGroupScopeParameterSet
```
New-RdsRoleAssignment [-RoleDefinitionName] <String> -GroupObjectId <String> -TenantGroupName <String>
 -AADTenantId <String> [<CommonParameters>]
```

### GroupRoleAssignmentTenantScopeParameterSet
```
New-RdsRoleAssignment [-RoleDefinitionName] <String> [-GroupObjectId <String>] [-TenantGroupName <String>]
 -TenantName <String> [-AADTenantId <String>] [<CommonParameters>]
```

### GroupRoleAssignmentHostPoolScopeParameterSet
```
New-RdsRoleAssignment [-RoleDefinitionName] <String> [-GroupObjectId <String>] [-TenantGroupName <String>]
 -TenantName <String> -HostPoolName <String> [-AADTenantId <String>] [<CommonParameters>]
```

### GroupRoleAssignmentAppGroupScopeParameterSet
```
New-RdsRoleAssignment [-RoleDefinitionName] <String> [-GroupObjectId <String>] [-TenantGroupName <String>]
 -TenantName <String> -HostPoolName <String> -AppGroupName <String> [-AADTenantId <String>]
 [<CommonParameters>]
```

## DESCRIPTION
The New-RdsRoleAssignment cmdlet creates a role assignment by specifying the three properties of a role assignment: the role, the principal, and the scope.

To define the role, you can use one of the following parameters:
- RDS Owner
- RDS Contributor
- RDS Reader
- RDS Operator
To understand each of the built-in roles, run Get-RdsRoleDefinition.

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

### Example 1: Create a role assignment for a user
```powershell
PS C:\> New-RdsRoleAssignment -RoleDefinitionName "RDS Owner" -SignInName "admin@contoso.com" -TenantGroupName "Default Tenant Group" -TenantName "Contoso" -HostPoolName "Contoso Host Pool" -AppGroupName "Desktop Application Group"

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
```
This commands creates a new role assignment, assigning admin@contoso.com the RDS Owner role at the "Desktop Application Group" app group scope.

### Example 2: Create a role assignment for a service principal
```powershell
PS C:\> New-RdsRoleAssignment -RoleDefinitionName "RDS Reader" -ApplicationId "yyyy-yyyy-yyyy-yyyy-yyyy" -TenantGroupName "Contoso Tenant Group" -TenantName "Contoso A" -HostPoolName "Contoso A Host Pool"

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
```
This command creates a new role assignment, assigning the specified service principal the RDS Reader role at the "Contoso A Host Pool" host pool scope.

### Example 3: Create a role assignment for an Azure AD group
```powershell
PS C:\> New-RdsRoleAssignment -RoleDefinitionName "RDS Operator" -GroupObjectId "aaaa-aaaa-aaaa-aaaa-aaaa" -TenantGroupName "Contoso Tenant Group" -TenantName "Contoso A"

RoleAssignmentId   : cccc-cccc-cccc-cccc-cccc
Scope              : /Contoso Tenant Group/Contoso A
TenantGroupName    : Contoso Tenant Group
TenantName         : Contoso A
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
```
This command creates a new role assignment, assigning the specified Azure AD group the RDS Operator role at the "Contoso A" tenant scope.

### Example 4: Create a role assignment for a user from a different Azure AD tenant
```powershell
PS C:\> New-RdsRoleAssignment -RoleDefinitionName "RDS Contributor" -SignInName "admin@contosob.com" -TenantGroupName "Contoso Tenant Group" -TenantName "Contoso A" -AadTenantId "xxxx-xxxx-xxxx-xxxx-xxxx"

RoleAssignmentId   : cccc-cccc-cccc-cccc-cccc
Scope              : /Contoso Tenant Group/Contoso A
TenantGroupName    : Contoso Tenant Group
TenantName         : Contoso A
HostPoolName       : 
AppGroupName       : 
DisplayName        : admin
SignInName         : admin@contosob.com
GroupObjectId      : aaaa-aaaa-aaaa-aaaa-aaaa
AADTenantId        : 0000-0000-0000-0000-0000
AppId              : yyyy-yyyy-yyyy-yyyy-yyyy
RoleDefinitionName : RDS Owner
RoleDefinitionId   : 3b14baea-8d82-4610-f5da-08d623dd1cc4
ObjectId           : bbbb-bbbb-bbbb-bbbb-bbbb
ObjectType         : User
Item               :
```
This command creates a new role assignment, assigning admin@contosob.com the RDS Contributor role at the "Contoso A" tenant scope. The AadTenantId parameter is specified since admin@contosob.com does not exist in the Azure AD tenant associated with the Contoso A tenant.

### Example 5: Create a role assignment at the tenant group scope
```powershell
PS C:\> New-RdsRoleAssignment -RoleDefinitionName "RDS Owner" -SignInName "admin@contoso.com" -TenantGroupName "Contoso Tenant Group" -AadTenantId "xxxx-xxxx-xxxx-xxxx-xxxx"

RoleAssignmentId   : cccc-cccc-cccc-cccc-cccc
Scope              : /Contoso Tenant Group
TenantGroupName    : Contoso Tenant Group
TenantName         : 
HostPoolName       : 
AppGroupName       : 
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
```
This command creates a new role assignment, assigning admin@contoso.com the RDS Owner role at the "Contoso Tenant Group" tenant group scope. The AadTenantId parameter is specified since tenant groups are not associated with any specific Azure AD tenant and Windows Virtual Desktop must resolve the user.

## PARAMETERS

### -AADTenantId
The Azure Active Directory tenant ID of the user. This is required when assigning a user at the tenant group scope. This is also required when assigning a user at the tenant, host pool, or app group scope when they do not exist in the Azure AD tenant associated with the Windows Virtual Desktop tenant.

```yaml
Type: String
Parameter Sets: SignInNameRoleAssignmentDeploymentScopeParameterSet, SignInNameRoleAssignmentTenantGroupScopeParameterSet, GroupRoleAssignmentDeploymentScopeParameterSet, GroupRoleAssignmentTenantGroupScopeParameterSet
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: SignInNameRoleAssignmentTenantScopeParameterSet, SignInNameRoleAssignmentHostPoolScopeParameterSet, SignInNameRoleAssignmentAppGroupScopeParameterSet, GroupRoleAssignmentTenantScopeParameterSet, GroupRoleAssignmentHostPoolScopeParameterSet, GroupRoleAssignmentAppGroupScopeParameterSet
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -AppGroupName
The name of the app group.

```yaml
Type: String
Parameter Sets: SignInNameRoleAssignmentAppGroupScopeParameterSet, SPNRoleAssignmentAppGroupScopeParameterSet, GroupRoleAssignmentAppGroupScopeParameterSet
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ApplicationId
The application ID of the service principal.

```yaml
Type: String
Parameter Sets: SPNRoleAssignmentDeploymentScopeParameterSet, SPNRoleAssignmentTenantGroupScopeParameterSet, SPNRoleAssignmentTenantScopeParameterSet, SPNRoleAssignmentHostPoolScopeParameterSet, SPNRoleAssignmentAppGroupScopeParameterSet
Aliases: SPN, ServicePrincipalName

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Deployment
A scope specific to Windows Virtual Desktop.

```yaml
Type: SwitchParameter
Parameter Sets: SignInNameRoleAssignmentDeploymentScopeParameterSet, SPNRoleAssignmentDeploymentScopeParameterSet, GroupRoleAssignmentDeploymentScopeParameterSet
Aliases:

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
Parameter Sets: GroupRoleAssignmentDeploymentScopeParameterSet, GroupRoleAssignmentTenantGroupScopeParameterSet
Aliases: AADGroupId, UserGroupObjectId

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: GroupRoleAssignmentTenantScopeParameterSet, GroupRoleAssignmentHostPoolScopeParameterSet, GroupRoleAssignmentAppGroupScopeParameterSet
Aliases: AADGroupId, UserGroupObjectId

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
Parameter Sets: SignInNameRoleAssignmentHostPoolScopeParameterSet, SignInNameRoleAssignmentAppGroupScopeParameterSet, SPNRoleAssignmentHostPoolScopeParameterSet, SPNRoleAssignmentAppGroupScopeParameterSet, GroupRoleAssignmentHostPoolScopeParameterSet, GroupRoleAssignmentAppGroupScopeParameterSet
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -RoleDefinitionName
The name of the role.

```yaml
Type: String
Parameter Sets: SignInNameRoleAssignmentDeploymentScopeParameterSet, SignInNameRoleAssignmentTenantGroupScopeParameterSet, SignInNameRoleAssignmentTenantScopeParameterSet, SignInNameRoleAssignmentHostPoolScopeParameterSet, SignInNameRoleAssignmentAppGroupScopeParameterSet, SPNRoleAssignmentDeploymentScopeParameterSet, SPNRoleAssignmentTenantGroupScopeParameterSet, SPNRoleAssignmentTenantScopeParameterSet, SPNRoleAssignmentHostPoolScopeParameterSet, SPNRoleAssignmentAppGroupScopeParameterSet, GroupRoleAssignmentDeploymentScopeParameterSet, GroupRoleAssignmentTenantGroupScopeParameterSet, GroupRoleAssignmentTenantScopeParameterSet, GroupRoleAssignmentHostPoolScopeParameterSet, GroupRoleAssignmentAppGroupScopeParameterSet
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
Parameter Sets: SignInNameRoleAssignmentDeploymentScopeParameterSet, SignInNameRoleAssignmentTenantGroupScopeParameterSet, SignInNameRoleAssignmentTenantScopeParameterSet, SignInNameRoleAssignmentHostPoolScopeParameterSet, SignInNameRoleAssignmentAppGroupScopeParameterSet
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
Parameter Sets: SignInNameRoleAssignmentTenantGroupScopeParameterSet, SPNRoleAssignmentTenantGroupScopeParameterSet, GroupRoleAssignmentTenantGroupScopeParameterSet
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: SignInNameRoleAssignmentTenantScopeParameterSet, SignInNameRoleAssignmentHostPoolScopeParameterSet, SignInNameRoleAssignmentAppGroupScopeParameterSet, SPNRoleAssignmentTenantScopeParameterSet, SPNRoleAssignmentHostPoolScopeParameterSet, SPNRoleAssignmentAppGroupScopeParameterSet, GroupRoleAssignmentTenantScopeParameterSet, GroupRoleAssignmentHostPoolScopeParameterSet, GroupRoleAssignmentAppGroupScopeParameterSet
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
Parameter Sets: SignInNameRoleAssignmentTenantScopeParameterSet, SignInNameRoleAssignmentHostPoolScopeParameterSet, SignInNameRoleAssignmentAppGroupScopeParameterSet, SPNRoleAssignmentTenantScopeParameterSet, SPNRoleAssignmentHostPoolScopeParameterSet, SPNRoleAssignmentAppGroupScopeParameterSet, GroupRoleAssignmentTenantScopeParameterSet, GroupRoleAssignmentHostPoolScopeParameterSet, GroupRoleAssignmentAppGroupScopeParameterSet
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

### System.Management.Automation.SwitchParameter

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
