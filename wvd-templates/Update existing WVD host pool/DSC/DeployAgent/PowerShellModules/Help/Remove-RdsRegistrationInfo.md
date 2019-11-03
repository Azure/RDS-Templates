---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Remove-RdsRegistrationInfo

## SYNOPSIS
Removes registration information from a host pool.

## SYNTAX

```
Remove-RdsRegistrationInfo [-TenantName] <String> [-HostPoolName] <String> [<CommonParameters>]
```

## DESCRIPTION
The Remove-RdsRegistrationInfo removes the registration information from the specified host pool.

If there is no registration information for the host pool, the cmdlet will succeed silently.

## EXAMPLES

### Example 1: Remove registration information from a host pool
```powershell
PS C:\> Remove-RdsRegistrationInfo -TenantName "Contoso" -HostPoolName "Contoso Host Pool"
```
This command removes the registration information from the specified host pool.

## PARAMETERS

### -HostPoolName
The name of the host pool.

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
