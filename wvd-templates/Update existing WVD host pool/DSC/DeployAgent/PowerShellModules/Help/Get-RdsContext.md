---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Get-RdsContext

## SYNOPSIS
Gets the metadata used to authenticate Windows Virtual Desktop requests.

## SYNTAX

```
Get-RdsContext [-DeploymentUrl <String>] [<CommonParameters>]
```

## DESCRIPTION
The Get-RdsContext cmdlet gets the current metadata used to authenticate Windows Virtual Desktop requests. This cmdlet gets the deployment URL, tenant group, and user name.

## EXAMPLES

### Example 1: Get the current context
```powershell
PS C:\> Get-RdsContext

DeploymentUrl                       TenantGroupName       UserName
-------------                       ---------------       --------
https://rdbroker.wvd.microsoft.com  Default Tenant Group  admin@contoso.com
```

## PARAMETERS

### -DeploymentUrl
The Universal Resource Locator (URL) string pointing to the Windows Virtual Dekstop management site. 

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
