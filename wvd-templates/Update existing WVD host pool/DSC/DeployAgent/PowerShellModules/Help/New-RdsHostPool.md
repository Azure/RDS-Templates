---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# New-RdsHostPool

## SYNOPSIS
Creates a host pool. 

## SYNTAX

```
New-RdsHostPool [-TenantName] <String> [-Name] <String> [-Description <String>] [-FriendlyName <String>]
 [-Persistent] [<CommonParameters>]
```

## DESCRIPTION
Creates a host pool within a tenant. The host pool contains one or more session hosts where users can connect to run programs, save files, and use resources on those hosts.

At creation time, you can decide to create a persistent host pool by using the persistent flag. By making a persistent host pool, the user will always connect to the same session host for their sessions. If you do not use this flag, a pooled host pool is created. In a pooled host pool, users are connected to a session host in the pool that is dynamically selected by the load balancer.

## EXAMPLES

### Example 1: Create a pooled host pool
```powershell
PS C:\> New-RdsHostPool -TenantName "Contoso" -Name "Contoso Host Pool"

TenantName            : Contoso
TenantGroupName       : Default Tenant Group
HostPoolName          : Contoso Host Pool
FriendlyName          :
Description           :
Persistent            : False
CustomRdpProperty     :
MaxSessionLimit       : 999999
UseReverseConnect     : True
LoadBalancerType      : BreadthFirst
```
This command creates a new, pooled host pool in the specified tenant. The host pool comes populated with some pre-defined values. To change these values, run the Set-RdsHostPool cmdlet.

### Example 2: Create a persistent host pool
```powershell
PS C:\> New-RdsHostPool -TenantName "Contoso" -Name "Persistent" -Persistent

TenantName            : MontoyaC
TenantGroupName       : Default Tenant Group
HostPoolName          : Persistent
FriendlyName          :
Description           :
Persistent            : True
CustomRdpProperty     :
MaxSessionLimit       : 999999
UseReverseConnect     : True
LoadBalancerType      : Persistent
```
This command creates a new, persistent host pool in the specified tenant. The host pool comes populated with some pre-defined values. To changes these values, run the Set-RdsHostPool cmdlet.

## PARAMETERS

### -Description
A 512 character string that describes the HostPool to help administrators. Any character is allowed. 

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

### -FriendlyName
A 256 character string that is intended for display to end users. Any character is allowed. 

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

### -Name
The name of the host pool, which must be unique in the tenant.

```yaml
Type: String
Parameter Sets: (All)
Aliases: HostPoolName

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Persistent
A switch indicating to mark the host pool as persistent.

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

### Microsoft.RDInfra.RDManagementData.RdMgmtHostPool

## NOTES

## RELATED LINKS
