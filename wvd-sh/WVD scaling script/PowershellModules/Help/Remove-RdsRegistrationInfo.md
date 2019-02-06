---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Remove-RdsRegistrationInfo

## SYNOPSIS
This cmdlet assumes that only one registration information object can exist at a time for a given tenant and host pool. Consequently, the registration information does not need to be provided as input.

## SYNTAX

```
Remove-RdsRegistrationInfo [-TenantName] <String> [-HostPoolName] <String> [<CommonParameters>]
```

## DESCRIPTION
This cmdlet assumes that only one registration information object can exist at a time for a given tenant and host pool. Consequently, the registration information does not need to be provided as input.

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
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

### System.Object
## NOTES

## RELATED LINKS
