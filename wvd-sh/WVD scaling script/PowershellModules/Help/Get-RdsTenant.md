---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Get-RdsTenant

## SYNOPSIS
Gets information about the specified tenant, or all tenants, if no tenant is specified. 

## SYNTAX

```
Get-RdsTenant [-Name <String>] [<CommonParameters>]
```

## DESCRIPTION
Gets information about the specified tenant, or all tenants, if no tenant is specified. 

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-RdsTenant -Name 'Tenant'
```

## PARAMETERS

### -Name
Name of Tenant.

```yaml
Type: String
Parameter Sets: (All)
Aliases: TenantName

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

### Microsoft.RDInfra.RDManagementData.RdMgmtTenant

## NOTES

## RELATED LINKS
