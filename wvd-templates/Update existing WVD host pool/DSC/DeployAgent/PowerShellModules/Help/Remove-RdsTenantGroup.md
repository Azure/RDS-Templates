---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Remove-RdsTenantGroup

## SYNOPSIS
Removes a tenant group.

## SYNTAX

```
Remove-RdsTenantGroup [-Name] <String> [<CommonParameters>]
```

## DESCRIPTION
The Remove-RdsTenantGrouop cmdlet removes a tenant group. You must first remove all tenants associated with the tenant group before running this command.

## EXAMPLES

### Example 1
```powershell
PS C:\> Remove-RdsTenantGroup -Name "Contoso Tenant Group"
```
This command removes a tenant group.

## PARAMETERS

### -Name
The name of the tenant group.

```yaml
Type: String
Parameter Sets: (All)
Aliases: TenantGroupName

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
