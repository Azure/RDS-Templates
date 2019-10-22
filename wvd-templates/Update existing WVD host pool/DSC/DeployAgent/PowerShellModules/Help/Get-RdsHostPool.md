---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Get-RdsHostPool

## SYNOPSIS
Gets the properties of a host pool.

## SYNTAX

```
Get-RdsHostPool [-TenantName] <String> [[-Name] <String>] [<CommonParameters>]
```

## DESCRIPTION
The Get-RdsHostPool cmdlet gets the properties of the specified host pool. If you do not specify a host pool, this cmdlet returns properties for all host pools in the specified tenant authorized for the current user.

## EXAMPLES

### Example 1: Get all host pools in the specified tenant
```powershell
PS C:\> Get-RdsHostPool -TenantName "Contoso"

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
This command gets the properties of all host pools in the specified tenant that are authorized for the current user.

## Example 2: Get a specific host pool
```powershell
PS C:\> Get-RdsTenant -TenantName "Contoso" -Name "Contoso Host Pool"

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
This command gets the properties of the specified host pool in the tenant. The host pool and its properties are displayed only if the host pool exists in the tenant and the current user is properly authorized.

## PARAMETERS

### -Name
The name of the host pool.

```yaml
Type: String
Parameter Sets: (All)
Aliases: HostPoolName

Required: False
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

###System.String

##OUTPUTS

### Microsoft.RDInfra.RDManagementData.RdMgmtHostPool

## NOTES

## RELATED LINKS
