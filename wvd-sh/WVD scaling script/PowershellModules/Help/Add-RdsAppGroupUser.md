---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Add-RdsAppGroupUser

## SYNOPSIS
Adds a user to the list of users that can access a specific app group.

## SYNTAX

```
Add-RdsAppGroupUser [-TenantName] <String> [-HostPoolName] <String> [-AppGroupName] <String>
 [-UserPrincipalName] <String> [<CommonParameters>]
```

## DESCRIPTION
The Add-RdsAppGroupUser cmdlet adds a user to the list of users that can access the specified AppGroup Name. 
This cmdlet only takes in a single user principal name (UPN) at a time and only applies to users (not groups). To add multiple users at a time, you can use loop PowerShell syntax. This cmdlet does not support groups as UPNs. 

## EXAMPLES

### Example 1
```powershell
PS C:\> Add-RdsAppGroupUser -TenantName 'wvdtenant' -HostPoolName 'wvdhostpool' -AppGroupName 'wfdappgroup' -UserPrincipalName 'PattiFuller@contoso.com'
```

With named parameters.

### Example 2
```powershell
PS C:\> Add-RdsAppGroupUser 'wvdtenant' 'wvdhostpool' 'wfdappgroup' 'PattiFuller@contoso.com'
```

Without named parameters.

## PARAMETERS

### -AppGroupName
Name of AppGroup.

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
Name of HostPool.

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
Name of Tenant.

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
Specifies the User Principal Name (UPN) of a user or a list of UPNs for multiple users; for example, PattiFuller@contoso.com. The user must be an existing user account in the customer's AAD or match the customer's ADFS domain name. Once added, this user will be able to access the AppGroup resources. If the UPN is already in the AppGroup's access list, the cmdlet does nothing and reports success

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
