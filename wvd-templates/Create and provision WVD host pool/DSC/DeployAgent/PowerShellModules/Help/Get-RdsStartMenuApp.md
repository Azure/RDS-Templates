---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Get-RdsStartMenuApp

## SYNOPSIS
Lists start menu applications available for publishing to an app group.  

## SYNTAX

```
Get-RdsStartMenuApp [-TenantName] <String> [-HostPoolName] <String> [-AppGroupName] <String>
 [<CommonParameters>]
```

## DESCRIPTION
The Get-RdsStartMenuApp cmdlet lists start menu applications available for publishing to the specified app group. Applications listed when running this command can be published with the New-RdsRemoteApp cmdlet by providing the app alias.

Applications may not be listed when running this command if it is not installed on all session hosts in the host pool or if the application does not have a registered shortcut in the start menu.

## EXAMPLES

### Example 1: List all start menu applications available for publishing to an app group
```powershell
PS C:\> Get-RdsStartMenuApp -TenantName "Contoso" -HostPoolName "Contoso Host Pool" -AppGroupName "Office Apps"

TenantGroupName      : Default Tenant Group
TenantName           : Contoso
HostPoolName         : Contoso Host Pool
AppGroupName         : Office Apps
AppAlias             : excel
FriendlyName         : Excel
FilePath             : C:\Program Files\Microsoft Office\root\Office16\EXCEL.EXE
CommandLineArguments :
IconPath             : C:\Program Files\Microsoft
                       Office\Root\VFS\Windows\Installer\{90160000-000F-0000-1000-0000000FF1CE}\xlicons.exe
IconIndex            : 0

TenantGroupName      : Default Tenant Group
TenantName           : Contoso
HostPoolName         : Contoso Host Pool
AppGroupName         : Office Apps
AppAlias             : powerpoint
FriendlyName         : PowerPoint
FilePath             : C:\Program Files\Microsoft Office\root\Office16\POWERPNT.EXE
CommandLineArguments :
IconPath             : C:\Program Files\Microsoft
                       Office\Root\VFS\Windows\Installer\{90160000-000F-0000-1000-0000000FF1CE}\pptico.exe
IconIndex            : 0
```
This command list of start menu applications available for publishing to the specified app group.

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

### Microsoft.RDInfra.RDManagementData.RdMgmtStartMenuApp

## NOTES

## RELATED LINKS
