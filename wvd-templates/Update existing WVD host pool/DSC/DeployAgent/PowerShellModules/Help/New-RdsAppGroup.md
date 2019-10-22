---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# New-RdsAppGroup

## SYNOPSIS
Creates an app group.

## SYNTAX

```
New-RdsAppGroup [-TenantName] <String> [-HostPoolName] <String> [-Name] <String> [-Description <String>]
 [-FriendlyName <String>] [-ResourceType <AppGroupResource>] [<CommonParameters>]
```

## DESCRIPTION
The New-RdsAppGroup cmdlet creates a new app group within the specified host pool.

You can create as many RemoteApp app groups within a host pool as you would like, but you can have only one desktop app group within a host pool. A default "Desktop Application Group" is automatically created Whenever you create a new host pool, so you must remove the app group first if you would like to create a new desktop app group.

You can specify the type of the app group using the resource type parameter. If you do not specify this parameter, a RemoteApp app group is created by default.

## EXAMPLES

### Example 1: Create a RemoteApp app group
```powershell
PS C:\> New-RdsAppGroup -TenantName "Contoso" -HostPoolName "Contoso Host Pool" -Name "LOB Apps" -ResourceType RemoteApp

TenantGroupName : Default Tenant Group
TenantName      : Contoso
HostPoolName    : Contoso Host Pool
AppGroupName    : LOB Apps
Description     :
FriendlyName    :
ResourceType    : RemoteApp
```
This command creates a new RemoteApp app group in the host pool. You can now run New-RdsRemoteApp to publish RemoteApps to the app group, along with Add-RdsAppGroupUser to assign users to the app group.

### Example 2: Create a desktop app group
```powershell
PS C:\> New-RdsAppGroup -TenantName "Contoso" -HostPoolName "Contoso Host Pool" -Name "Shared Desktops" -ResourceType Desktop

TenantGroupName : Default Tenant Group
TenantName      : Contoso
HostPoolName    : Contoso Host Pool
AppGroupName    : Shared Desktops
Description     :
FriendlyName    :
ResourceType    : Desktop
```
This command creates a new RemoteApp app group in the host pool. You can now run Add-RdsAppGroupUser to assign users to the app group.

## PARAMETERS

### -Description
A 512 character string that describes the AppGroup to help administrators. Any character is allowed. 

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
The name of the app group, which must be unique in the host pool.

```yaml
Type: String
Parameter Sets: (All)
Aliases: AppGroupName

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -ResourceType
A switch with two potential values:
- Desktop, to publish a desktop
- RemoteApp, to publish one or more RemoteApps 

```yaml
Type: AppGroupResource
Parameter Sets: (All)
Aliases:
Accepted values: RemoteApp, Desktop

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

### Microsoft.RDInfra.RDManagementData.RdMgmtAppGroup

## NOTES

## RELATED LINKS
