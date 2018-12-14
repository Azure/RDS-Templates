---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Get-RdsUserSession

## SYNOPSIS
Gets a list of all user sessions running on a session host or all session hosts within a host pool. 

## SYNTAX

```
Get-RdsUserSession [-TenantName] <String> [-HostPoolName] <String> [<CommonParameters>]
```

## DESCRIPTION
Gets a list of all user sessions running on a session host or all session hosts within a host pool. 

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-RdsUserSession -TenantName 'Tenant' -HostPoolName 'HostPool' -SessionHostName 'SessionHostName'
```

## PARAMETERS

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

## OUTPUTS

### Microsoft.RDInfra.RDManagementData.RdMgmtUserSession

## NOTES

## RELATED LINKS
