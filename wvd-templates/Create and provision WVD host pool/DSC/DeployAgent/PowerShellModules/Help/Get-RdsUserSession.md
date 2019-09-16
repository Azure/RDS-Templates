---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Get-RdsUserSession

## SYNOPSIS
Lists all active user sessions in a host pool.

## SYNTAX

```
Get-RdsUserSession [-TenantName] <String> [-HostPoolName] <String> [<CommonParameters>]
```

## DESCRIPTION
The Get-RdsUserSession lists all user sessions running on the session hosts in the specified host pool.

With this command, you can identify the session host name and session ID associated with a specific user. You can then run the Disconnect-RdsUserSession, Invoke-RdsUserSessionLogoff or Send-RdsUserSessionMessage with this additional information.

## EXAMPLES

### Example 1: List all user sessions running in a host pool
```powershell
PS C:\> Get-RdsUserSession -TenantName "Contoso" -HostPoolName "Contoso Host Pool"
```
This command lists all user sessions running on the session hosts in the specified host pool.

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

### Microsoft.RDInfra.RDManagementData.RdMgmtUserSession

## NOTES

## RELATED LINKS
