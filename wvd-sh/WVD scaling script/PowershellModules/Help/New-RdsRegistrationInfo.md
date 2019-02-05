---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# New-RdsRegistrationInfo

## SYNOPSIS
Creates a new RdMgmtRegistrationInfo object for this host pool. 
Note: Since there is only one registration token for a host pool, there is no need to name the registration token.

## SYNTAX

```
New-RdsRegistrationInfo [-TenantName] <String> [-HostPoolName] <String> [-ExpirationHours <Int32>]
 [<CommonParameters>]
```

## DESCRIPTION
Creates a new RdMgmtRegistrationInfo object for this host pool. 

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -ExpirationHours
The Expiration date is automatically calculated by adding the ExpirationHours value to the current time. Default is 48 hours from the time the cmdlet is run. 

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

## OUTPUTS

### Microsoft.RDInfra.RDManagementData.RdMgmtRegistrationInfo

## NOTES

## RELATED LINKS
