---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Get-RdsRoleAssignment

## SYNOPSIS


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


## EXAMPLES

### Example 1
```powershell
PS C:\> 
```

## PARAMETERS

### -AppGroupName
Name of AppGroup

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
User Group object id from AAD to uniquely identify user groups.

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

### -ServicePrincipalName
The app SPN.

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
User name for which to retrieve the roles.

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
