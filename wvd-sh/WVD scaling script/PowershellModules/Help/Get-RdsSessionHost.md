---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Get-RdsSessionHost

## SYNOPSIS
Gets the properties of a specific session host or, if no SessionHost Name is specified, all session hosts in a host pool. 

## SYNTAX

```
Get-RdsSessionHost [-TenantName] <String> [-HostPoolName] <String> [-Name <String>] [<CommonParameters>]
```

## DESCRIPTION
Gets the properties of a specific session host or, if no SessionHost Name is specified, all session hosts in a host pool. 

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-RdsSessionHost -TenantName 'Tenant' -HostPoolName 'HostPool' -Name 'SessionHostName'
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

### -Name
FQDN of Session Host

```yaml
Type: String
Parameter Sets: (All)
Aliases: SessionHostName

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -TenantName
Name of Tenant

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

### Microsoft.RDInfra.RDManagementData.RdMgmtSessionHost

## NOTES

## RELATED LINKS
