---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Export-RdsRegistrationInfo

## SYNOPSIS
Exports session host registration info for a specific host pool. 

## SYNTAX

```
Export-RdsRegistrationInfo [-TenantName] <String> [-HostPoolName] <String> [<CommonParameters>]
```

## DESCRIPTION
The Export-RdsRegistrationInfo cmdlet exports session host registration info for a specific host pool. This registration info can then be used by new or existing session hosts to properly register to a host pool. The registration info is only valid for the specified amount of hours defined when running New-RdsRegistrationInfo. 
If no registration info currently exists for the specified host pool, the outpull will be null.

## EXAMPLES

### Example 1
```powershell
PS C:\> Export-RdsRegistration -TenantName 'wfdtenant' -HostPoolName 'wfdhostpool'
```

With named parameters.

### Example 2
```powershell
PS C:\> Export-RdsRegistration 'wfdtenant' 'wfdhostpool'
```

Without named parameters.

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

### Microsoft.RDInfra.RDManagementData.RdMgmtRegistrationInfo

## NOTES

## RELATED LINKS
