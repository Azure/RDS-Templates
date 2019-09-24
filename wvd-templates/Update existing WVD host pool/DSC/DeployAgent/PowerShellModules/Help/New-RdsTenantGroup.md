---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# New-RdsTenantGroup

## SYNOPSIS
Creates a new tenant group.

## SYNTAX

```
New-RdsTenantGroup [-Name] <String> [-FriendlyName <String>] [-Description <String>] [<CommonParameters>]
```

## DESCRIPTION
 
Creates a new tenant group within the deployment.

## EXAMPLES

### Example 1
```powershell
PS C:\> New-RdsTenantGroup -Name "Contoso Tenant Group"

TenantGroupName       Description  FriendlyName
---------------       -----------  ------------
Contoso Tenant Group
```
This command creates a new tenant group in Windows Virtual Desktop.

## PARAMETERS

### -Description
A 512 character string that describes the TenantGroup to help administrators. Any character is allowed

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -FriendlyName
A 256 character string that is intended for display to end users. Any character is allowed. 

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Name
The name of the tenant, which must be unique in Windows Virtual Desktop. 

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

### Microsoft.RDInfra.RDManagementData.RdMgmtTenantGroup

## NOTES

## RELATED LINKS
