---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# New-RdsRoleAssignment

## SYNOPSIS


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


## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -AADTenantId
AAD Tenant Id

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
RDmi Application group name

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
The app SPN.

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
At Deployment Scope

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
AAD Tenant User Group object Id

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
RDmi Host pool name

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
Role definition name.
For e.g.
RDS Reader, RDS Contributor, RDS Owner.

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
The user SignInName.

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
RDmi Tenant Group name

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
RDmi Tenant name

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
