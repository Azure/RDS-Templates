---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Set-RdsContext

## SYNOPSIS
Sets the TenantGroup context for subsequent RDS PowerShell cmdlets. This context is only valid for the duration of the PowerShell session or until another Set-RdsContext is run. If not specified, then “Default Tenant Group” will be used.

## SYNTAX

```
Set-RdsContext [-TenantGroupName] <String> [<CommonParameters>]
```

## DESCRIPTION
Sets the TenantGroup context for subsequent RDS PowerShell cmdlets. This context is only valid for the duration of the PowerShell session or until another Set-RdsContext is run. If not specified, then “Default Tenant Group” will be used.

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

## PARAMETERS

### -TenantGroupName
Name of TenantGroup.

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

### Microsoft.RDInfra.RDManagementData.RdMgmtContext

## NOTES

## RELATED LINKS
