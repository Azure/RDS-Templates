---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Get-RdsContext

## SYNOPSIS
The Get-RdsContext cmdlet gets the details of the current context.

## SYNTAX

```
Get-RdsContext [-DeploymentUrl <String>] [<CommonParameters>]
```

## DESCRIPTION
The Get-RdsContext cmdlet gets the details of the current context.

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-RdsContext
```

## PARAMETERS

### -DeploymentUrl
Universal Resource Locator string pointing to the WVD deployment's management site. 

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### Microsoft.RDInfra.RDManagementData.RdMgmtContext

## NOTES

## RELATED LINKS
