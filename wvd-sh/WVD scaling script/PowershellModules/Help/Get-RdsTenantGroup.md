---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Get-RdsTenantGroup

## SYNOPSIS
Gets information about the specified tenant group or all tenant groups, if no TenantGroupName is specified. 

## SYNTAX

```
Get-RdsTenantGroup [-Name <String>] [<CommonParameters>]
```

## DESCRIPTION
Gets information about the specified tenant group or all tenant groups, if no TenantGroupName is specified. 

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-RdsTenantGroup -Name 'TenantGroupName'
```

## PARAMETERS

### -Name
Name of TenantGorup

```yaml
Type: String
Parameter Sets: (All)
Aliases: TenantGroupName

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

### Microsoft.RDInfra.RDManagementData.RdMgmtTenantGroup

## NOTES

## RELATED LINKS
