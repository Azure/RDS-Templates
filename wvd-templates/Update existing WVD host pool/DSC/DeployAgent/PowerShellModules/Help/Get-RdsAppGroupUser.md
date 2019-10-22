---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Get-RdsAppGroupUser

## SYNOPSIS
Lists the users that have access to an app group.

## SYNTAX

```
Get-RdsAppGroupUser [-TenantName] <String> [-HostPoolName] <String> [-AppGroupName] <String>
 [-UserPrincipalName <String>] [<CommonParameters>]
```

## DESCRIPTION
The Get-RdsAppGroupUser cmdlet lists the users that have access to the specified app group. If you specify a user principal name, this cmdlet either returns the specified user principal name who has access to the app group or an error indicating that they do not have access.

## EXAMPLES

### Example 1: List all users who have been assigned to an app group
```powershell
PS C:\> Get-RdsAppGroupUser -TenantName "Contoso" -HostPoolName "Contoso Host Pool" -AppGroupName "Desktop Application Group"

UserPrincipalName : user1@contoso.com
TenantName        : Contoso
TenantGroupName   : Default Tenant Group
HostPoolName      : Contoso Host Pool
AppGroupName      : Desktop Application Group

UserPrincipalName : user2@contoso.com
TenantName        : Contoso
TenantGroupName   : Default Tenant Group
HostPoolName      : Contoso Host Pool
AppGroupName      : Desktop Application Group
```
This command lists all users assigned to the specified app group.

### Example 2: Check if a specific user has been assigned to an app group
```powershell
PS C:\> Get-RdsAppGroupUser -TenantName "Contoso" -HostPoolName "Contoso Host Pool" -AppGroupName "Desktop Application Group" -UserPrincipalName "user1@contoso.com"

UserPrincipalName : user1@contoso.com
TenantName        : Contoso
TenantGroupName   : Default Tenant Group
HostPoolName      : Contoso Host Pool
AppGroupName      : Desktop Application Group
```
This command lists the specified user if they have already been assigned to the app group. If the user has not been assigned to the app group, you will receive an error.

## PARAMETERS

### -AppGroupName
The name of the app group.

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
The name of the host pool.

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
The name of the tenant.

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

### -UserPrincipalName
The user principal name (UPN) of the user you would like to check for app group access.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

## OUTPUTS

### Microsoft.RDInfra.RDManagementData.RdMgmtUser

## NOTES

## RELATED LINKS
