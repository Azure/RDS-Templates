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

### Example 1
```powershell
PS C:\> Get-RdsAppGroupUser -TenantName 'wvdtenant' -HostPoolName 'wvdhostpool' -AppGroupName 'wvdappgroup' -UserPrincipalName 'PattiFuller@contoso.com'
```

With named parameters.

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
Name of UPN.

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
