---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Get-RdsHostPool

## SYNOPSIS
Gets the properties of a host pool.

## SYNTAX

```
Get-RdsHostPool [-TenantName] <String> [[-Name] <String>] [<CommonParameters>]
```

## DESCRIPTION
The Get-RdsHostPool cmdlet gets the properties of the specified host pool. If you do not specify a host pool, this cmdlet returns properties for all host pools in the specified tenant.

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-RdsHostPool -TenantName
```

## PARAMETERS

### -Name
Name of HostPool.

```yaml
Type: String
Parameter Sets: (All)
Aliases: HostPoolName

Required: False
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

###System.String

##OUTPUTS

### Microsoft.RDInfra.RDManagementData.RdMgmtHostPool

## NOTES

## RELATED LINKS
