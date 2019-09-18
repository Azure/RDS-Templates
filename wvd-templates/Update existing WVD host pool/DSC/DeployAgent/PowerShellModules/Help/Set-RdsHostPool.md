---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Set-RdsHostPool

## SYNOPSIS
Sets the properties for a host pool.

## SYNTAX

### HP4 (Default)
```
Set-RdsHostPool [-TenantName] <String> [-Name] <String> [-FriendlyName <String>] [-Description <String>]
 [-MaxSessionLimit <Int32>] [<CommonParameters>]
```

### HP5
```
Set-RdsHostPool [-TenantName] <String> [-Name] <String> [-BreadthFirstLoadBalancer] [-MaxSessionLimit <Int32>]
 [<CommonParameters>]
```

### HP6
```
Set-RdsHostPool [-TenantName] <String> [-Name] <String> [-DepthFirstLoadBalancer] -MaxSessionLimit <Int32>
 [<CommonParameters>]
```

### HP3
```
Set-RdsHostPool [-TenantName] <String> [-Name] <String> [-CustomRdpProperty <String>]
 [-UseReverseConnect <Boolean>] [<CommonParameters>]
```

## DESCRIPTION
The Set-RdsHostPool cmdlet sets the properties for the specified host pool. Three parameter sets exist for this cmdlet. First is used to disable user profile disks. The second is used to enable user profile disks. The third is used to set all other properties of the host pool. 

## EXAMPLES

### Example 1: Set the host pool to use depth-first load balancing
```powershell
PS C:\> Set-RdsHostPool -TenantName "Contoso" -Name "Contoso Host Pool" -DepthFirstLoadBalancer -MaxSessionLimit 10

TenantName            : Contoso
TenantGroupName       : Default Tenant Group
HostPoolName          : Contoso Host Pool
FriendlyName          :
Description           :
Persistent            : False
CustomRdpProperty     :
MaxSessionLimit       : 10
UseReverseConnect     : True
LoadBalancerType      : DepthFirst
```
This command sets the host pool to use depth-first load balancing, such that incoming users will all be directed to a specific session host until it reaches the MaxSessionLimit, which is specified as 10 in this example. The MaxSessionLimit parameter is a requirement when setting depth-first load balancing since connections will not be distributed to subsequent session hosts until this session limit is reached on the first session host.

### Example 2: Set the host pool to use breadth-first load balancing
```powershell
PS C:\> Set-RdsHostPool -TenantName "Contoso" -Name "Contoso Host Pool" -BreadthFirstLoadBalancer

TenantName            : Contoso
TenantGroupName       : Default Tenant Group
HostPoolName          : Contoso Host Pool
FriendlyName          :
Description           :
Persistent            : False
CustomRdpProperty     :
MaxSessionLimit       : 10
UseReverseConnect     : True
LoadBalancerType      : BreadthFirst
```
This command sets the host pool to use breadth-first load balancing, such that incoming users will be evenly directed across session hosts in the host pool. The MaxSessionLimit parameter is optional since load balancing in breadth-first mode is less restrictive than load balancing in depth-first mode.

### Example 3: Set custom RDP properties for connections to the host pool
```powershell
PS C:\> Set-RdsHostPool -TenantName "Contoso" -Name "Contoso Host Pool" -CustomRdpProperty "use multimon:i:0"

TenantName            : Contoso
TenantGroupName       : Default Tenant Group
HostPoolName          : Contoso Host Pool
FriendlyName          :
Description           :
Persistent            : False
CustomRdpProperty     : use multimon:i:0;
MaxSessionLimit       : 10
UseReverseConnect     : True
LoadBalancerType      : BreadthFirst
```
This command sets custom RDP properties for connections to this host pool.

## PARAMETERS

### -BreadthFirstLoadBalancer
Switch to enable the use of breadth-first load balancing for the host pool. Breadth-first indicates that new user sessions are directed to the session host with the least number of user sessions.

```yaml
Type: SwitchParameter
Parameter Sets: HP5
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CustomRdpProperty
Specifies Remote Desktop Protocol (RDP) settings to include in the .rdp files for all RemoteApp programs and remote desktops published in this collection. 

```yaml
Type: String
Parameter Sets: HP3
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -DepthFirstLoadBalancer
Switch to enable the use of depth-first load balancing for the host pool. Depth-first indicates that new user sessions are directed to the session host with the highest number of user sessions that has not already reached its max session limit.

```yaml
Type: SwitchParameter
Parameter Sets: HP6
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description
The description for the host pool.

```yaml
Type: String
Parameter Sets: HP4
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```


### -FriendlyName
The friendly name of the host pool to be displayed.

```yaml
Type: String
Parameter Sets: HP4
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```


### -MaxSessionLimit
The maximum number of sessions allowed per session host in the hosr pool. When depth-first mode is set for load-balancing, this value is used to determine when to stop load balancing users to one host and to begin sending users to the next host.

```yaml
Type: Int32
Parameter Sets: HP4, HP5
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: Int32
Parameter Sets: HP6
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
The name of the host pool.

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
