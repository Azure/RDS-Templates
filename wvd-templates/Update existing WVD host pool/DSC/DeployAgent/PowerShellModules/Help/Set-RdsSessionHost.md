---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Set-RdsSessionHost

## SYNOPSIS
Sets the state of a session host.

## SYNTAX

```
Set-RdsSessionHost [-TenantName] <String> [-HostPoolName] <String> [-Name] <String> [-AllowNewSession]
 [<CommonParameters>]
```

## DESCRIPTION
The Set-RdsSessionHost cmdlet sets the state of the specified session host. You can either disable or enable new connections to the session host. Changing this property on the session host does not affect any user sessions on the session host.

## EXAMPLES

### Example 1: Disable new connections to a session host (aka, set the host to drain mode)
```powershell
PS C:\> Set-RdsSessionHost -TenantName "Contoso" -HostPoolName "Contoso Host Pool" -Name "sh1.contoso.com" -AllowNewSession $false

SessionHostName : sh1.contoso.com
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
This command disables the session host from receiving any new connections and removes it as a candidate for load balancing. Any existing sessions on the server will remain there until the user is logged off. An administrator can force a logoff with the Invoke-RdsUserSessionLogoff cmdlet.

### Example 2: Enable new connections to a session host (aka, remove the host from drain mode)
```powershell
PS C:\> Set-RdsSessionHost -TenantName "Contoso" -HostPoolName "Contoso Host Pool" -Name "sh1.contoso.com" -AllowNewSession $true

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
This command enables the session host to receive new connections and is now a candidate for load balancing.

## PARAMETERS

### -AllowNewSession
A switch with two potential values:
- True, specifying that the session host can be assigned new user sessions by the broker.
- False, specifying that the session host will not be assigned any new user sessions (aka drain mode). 

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

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

Required: True
Position: 2
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
