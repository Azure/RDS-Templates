---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Get-RdsRemoteDesktop

## SYNOPSIS
Gets the properties of a published desktop. 

## SYNTAX

```
Get-RdsRemoteDesktop [-TenantName] <String> [-HostPoolName] <String> [-AppGroupName] <String>
 [<CommonParameters>]
```

## DESCRIPTION
The Get-RdsRemoteDesktop cmdlet gets the properties of the specified published desktop. This cmdlet will fail if you specify a RemoteApp app group.

## EXAMPLES

### Example 1: Get the properties of a published desktop
```powershell
PS C:\> Get-RdsRemoteDesktop -TenantName "Contoso" -HostPoolName "Contoso Host Pool" -AppGroupName "Desktop Application Group"

TenantGroupName   : Default Tenant Group
TenantName        : Contoso
HostPoolName      : Contoso Host Pool
AppGroupName      : Desktop Application Group
RemoteDesktopName : Remote Desktop
FriendlyName      : Engineering - Desktop
Description       : The default Session Desktop
ShowInWebFeed     :
```
This command gets the properties of the specified published desktop. The desktop app group and its properties are displayed only if the desktop app group exists in the host pool and the current user is properly authorized.

## PARAMETERS

### -AppGroupName
The name of the app group, which must be a desktop app group.

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

### Microsoft.RDInfra.RDManagementData.RdMgmtPublishedDesktop

## NOTES

## RELATED LINKS
