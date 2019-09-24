---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Remove-RdsTenant

## SYNOPSIS
Removes a tenant.

## SYNTAX

```
Remove-RdsTenant [-Name] <String> [<CommonParameters>]
```

## DESCRIPTION
The Remove-RdsTenant cmdlet removes a tenant in the current context. You must first remove all host pools associated with the tenant before running this command.

## EXAMPLES

### Example 1
```powershell
PS C:\> Remove-RdsTenant -Name "Contoso"
```
This command removes a tenant in the current context.

## PARAMETERS

### -Name
The name of the tenant.

```yaml
Type: String
Parameter Sets: (All)
Aliases: TenantName

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
