---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Remove-RdsHostPool

## SYNOPSIS
Removes a host pool from a tenant. 

## SYNTAX

```
Remove-RdsHostPool [-TenantName] <String> [-Name] <String> [<CommonParameters>]
```

## DESCRIPTION
The Remove-RdsHostPool cmdlet removes a host pool from the specified tenant. You must first remove all session hosts and app groups associated with the host pool before running this command.

## EXAMPLES

### Example 1
```powershell
PS C:\> Remove-RdsHostPool -TenantName "Contoso" -Name "Contoso Host Pool"
```
This command removes a host pool in the tenant.

## PARAMETERS

### -Name
The name of the host pool.

```yaml
Type: String
Parameter Sets: (All)
Aliases: HostPoolName

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -TenantName
The name of the tenant.

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
