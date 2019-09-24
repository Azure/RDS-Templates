---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Remove-RdsAppGroupUser

## SYNOPSIS
Removes a user's access to an app group.

## SYNTAX

```
Remove-RdsAppGroupUser [-TenantName] <String> [-HostPoolName] <String> [-AppGroupName] <String>
 [-UserPrincipalName] <String> [<CommonParameters>]
```

## DESCRIPTION
The Remove-RdsAppGroupUser cmdlet removes a user's access to the specified app group. This cmdlet only takes in a single user principal name (UPN) at a time and only applies to users (not groups). To remove multiple users at a time, you can use loop PowerShell syntax. This cmdlet does not support groups as UPNs.

The UPN must exist in the Azure Active Directory associated with the tenant. If the user has not already been assigned access to the app group, the cmdlet will succeed silently.

## EXAMPLES

### Example 1
```powershell
PS C:\> Remove-RdsAppGroupUser -TenantName "Contoso" -HostPoolName "Contoso Host Pool" -AppGroupName "Office Apps" -UserPrincipalName "user1@contoso.com"
```
This command removes the user's access to the app group.

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
The user principal name (UPN) of the user whose app group access you would like to remove.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
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
