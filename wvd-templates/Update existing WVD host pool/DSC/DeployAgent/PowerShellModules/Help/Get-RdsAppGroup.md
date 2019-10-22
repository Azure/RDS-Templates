---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Get-RdsAppGroup

## SYNOPSIS
Gets the properties of an app group.

## SYNTAX

```
Get-RdsAppGroup [-TenantName] <String> [-HostPoolName] <String> [-Name <String>] [<CommonParameters>]
```

## DESCRIPTION
The Get-RdsAppGroup cmdlet gets the properties of the specified app group. If you do not specify an app group name, this cmdlet returns properties for all app groups in the specified hostpool.

## EXAMPLES

### Example 1: Get all app groups in the specified host pool
```powershell
PS C:\> Get-RdsAppGroup -TenantName "Contoso" -HostPoolName "Contoso Host Pool"

TenantGroupName : Default Tenant Group
TenantName      : Contoso
HostPoolName    : Contoso Host Pool
AppGroupName    : Desktop Application Group
Description     : The default desktop application group for the session host pool
FriendlyName    : Desktop Application Group
ResourceType    : Desktop

TenantGroupName : Microsoft Internal
TenantName      : Contoso
HostPoolName    : Contoso Host Pool
AppGroupName    : Office Apps
Description     : RemoteApp group for Office applications
FriendlyName    :
ResourceType    : RemoteApp
```
This command gets the properties of all app groups in the specified tenant and host pool that are authorized for the current user.

### Example 2: Get a specific app group
```powershell
PS C:\> Get-RdsAppGroup -TenantName "Contoso" -HostPoolName "Contoso Host Pool" -Name "Desktop Application Group"

TenantGroupName : Default Tenant Group
TenantName      : Contoso
HostPoolName    : Contoso Host Pool
AppGroupName    : Desktop Application Group
Description     : The default desktop application group for the session host pool
FriendlyName    : Desktop Application Group
ResourceType    : Desktop
```

This command gets the properties of the specified app group in the host pool. The app group and its properties are displayed only if the app group exists in the host pool and the current user is properly authorized.

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
The name of the app group.

```yaml
Type: String
Parameter Sets: (All)
Aliases: AppGroupName

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

### Microsoft.RDInfra.RDManagementData.RdMgmtAppGroup

## NOTES

## RELATED LINKS
