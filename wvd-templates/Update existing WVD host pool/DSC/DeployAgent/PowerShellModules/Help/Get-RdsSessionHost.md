---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Get-RdsSessionHost

## SYNOPSIS
Gets the properties of a session host. 

## SYNTAX

```
Get-RdsSessionHost [-TenantName] <String> [-HostPoolName] <String> [-Name <String>] [<CommonParameters>]
```

## DESCRIPTION
The Get-RdsSessionHost cmdlet gets the properties of the specified session host. If you do not specify a session host, this cmdlet returns all session hosts in the host pool. 

## EXAMPLES

### Example 1: Get all session hosts in the host pool
```powershell
PS C:\> Get-RdsSessionHost -TenantName "Contoso" -HostPoolName "Contoso Host Pool"

SessionHostName : sh1.contoso.com
TenantName      : Contoso
TenantGroupName : Default Tenant Group
HostPoolName    : Contoso Host Pool
AllowNewSession : True
Sessions        : 1
LastHeartBeat   : 1/1/2018 12:00:00 PM
AgentVersion    : 1.0.0.1
AssignedUser    :
Status          : Available
StatusTimestamp : 1/1/2018 12:00:00 PM

SessionHostName : sh2.contoso.com
TenantName      : Contoso
TenantGroupName : Default Tenant Group
HostPoolName    : Contoso Host Pool
AllowNewSession : False
Sessions        : 1
LastHeartBeat   : 1/1/2018 12:00:00 PM
AgentVersion    : 1.0.0.1
AssignedUser    :
Status          : Available
StatusTimestamp : 1/1/2018 12:00:00 PM
```
This command gets all session hosts in the specified host pool.

### Example 2: Get a specific session host
```powershell
PS C:\> Get-RdsSessionHost -TenantName "Contoso" -HostPoolName "Contoso Host Pool" -Name "sh1.contoso.com"

SessionHostName : sh1.contoso.com
TenantName      : Contoso
TenantGroupName : Default Tenant Group
HostPoolName    : Contoso Host Pool
AllowNewSession : True
Sessions        : 1
LastHeartBeat   : 1/1/2018 12:00:00 PM
AgentVersion    : 1.0.0.1
AssignedUser    :
Status          : Available
StatusTimestamp : 1/1/2018 12:00:00 PM
```
This command gets the properties of the specified session host in the host pools. The session host and its properties are displayed only if the session host exists in the tenant and the current user is properly authorized.

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

### -Name
The fully-qualified domain name (FQDN) of the session host.

```yaml
Type: String
Parameter Sets: (All)
Aliases: SessionHostName

Required: False
Position: Named
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

### Microsoft.RDInfra.RDManagementData.RdMgmtSessionHost

## NOTES

## RELATED LINKS
