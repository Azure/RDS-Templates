---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Get-RdsTenantGroup

## SYNOPSIS
Gets tenant groups that are authorized for the user. 

## SYNTAX

```
Get-RdsTenantGroup [-Name <String>] [<CommonParameters>]
```

## DESCRIPTION
The Get-RdsTenantGroup cmdlet gets tenant groups that are authorized for the user. If you do not specify a tenant group, this cmdlet returns all tenants groups authorized for the current user.

## EXAMPLES

### Example 1: Get a specific tenant group
```powershell
PS C:\> Get-RdsTenantGroup -Name "Contoso Tenant Group"

TenantGroupName       Description  FriendlyName
---------------       -----------  ------------
Contoso Tenant Group
```
This command gets the specified tenant group in the current context. The tenant group is displayed only if the tenant exists in the current context and the current user is properly authorized.

## PARAMETERS

### -Name
The name of the tenant group.

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
