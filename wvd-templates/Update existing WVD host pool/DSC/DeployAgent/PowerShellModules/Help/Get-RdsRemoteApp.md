---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Get-RdsRemoteApp

## SYNOPSIS
Lists the RemoteApp programs published to an app group.

## SYNTAX

```
Get-RdsRemoteApp [-TenantName] <String> [-HostPoolName] <String> [-AppGroupName] <String> [-Name <String>]
 [<CommonParameters>]
```

## DESCRIPTION
The Get-RdsRemoteApp cmdlet lists the RemoteApp programs published to the specified app group. If you specify the name of a RemoteApp, this cmdlet returns the properties of the specified RemoteApp.

## EXAMPLES

### Example 1: List all RemoteApps that have been published to an app group
```powershell
PS C:\> Get-RdsRemoteApp -TenantName "Contoso" -HostPoolName "Contoso Host Pool" -AppGroupName "Office Apps"

TenantGroupName     : Default Tenant Group
TenantName          : Contoso
HostPoolName        : Contoso Host Pool
AppGroupName        : Office Apps
RemoteAppName       : Excel
FilePath            : C:\Program Files\Microsoft Office\root\Office16\EXCEL.EXE
AppAlias            :
CommandLineSetting  : DoNotAllow
Description         :
FriendlyName        : Excel
IconIndex           : 0
IconPath            : C:\Program Files\Microsoft
                      Office\Root\VFS\Windows\Installer\{90160000-000F-0000-1000-0000000FF1CE}\xlicons.exe
RequiredCommandLine :
ShowInWebFeed       : True

TenantGroupName     : Default Tenant Group
TenantName          : Contoso
HostPoolName        : Contoso Host Pool
AppGroupName        : Office Apps
RemoteAppName       : PowerPoint
FilePath            : C:\Program Files\Microsoft Office\root\Office16\POWERPNT.EXE
AppAlias            :
CommandLineSetting  : DoNotAllow
Description         :
FriendlyName        : PowerPoint
IconIndex           : 0
IconPath            : C:\Program Files\Microsoft
                      Office\Root\VFS\Windows\Installer\{90160000-000F-0000-1000-0000000FF1CE}\pptico.exe
RequiredCommandLine :
ShowInWebFeed       : True
```
This command lists all RemoteApps that have been published to the specified RemoteApp app group.

### Example 2: List the properties of a specific RemoteApp
```powershell
PS C:\> Get-RdsRemoteApp -TenantName "Contoso" -HostPoolName "ContosoHP" -AppGroupName "Office Apps" -Name "Excel"

TenantGroupName     : Default Tenant Group
TenantName          : Contoso
HostPoolName        : Contoso Host Pool
AppGroupName        : Office Apps
RemoteAppName       : Excel
FilePath            : C:\Program Files\Microsoft Office\root\Office16\EXCEL.EXE
AppAlias            :
CommandLineSetting  : DoNotAllow
Description         :
FriendlyName        : Excel
IconIndex           : 0
IconPath            : C:\Program Files\Microsoft
                      Office\Root\VFS\Windows\Installer\{90160000-000F-0000-1000-0000000FF1CE}\xlicons.exe
RequiredCommandLine :
ShowInWebFeed       : True
```
This command lists the properties of the specified RemoteApp in the app group. The RemoteApp and its properties are displayed only if the RemoteApp has been published to the RemoteApp app group and the current user is properly authorized.

## PARAMETERS

### -AppGroupName
The name of the app group.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -HostPoolName
The name the of host pool.

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
The name of the RemoteApp.

```yaml
Type: String
Parameter Sets: (All)
Aliases: RemoteAppName

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

### Microsoft.RDInfra.RDManagementData.RdMgmtRemoteApp

## NOTES

## RELATED LINKS
