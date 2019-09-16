---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Set-RdsRemoteDesktop

## SYNOPSIS
Sets the properties for a published desktop. 

## SYNTAX

```
Set-RdsRemoteDesktop [-TenantName] <String> [-HostPoolName] <String> [-AppGroupName] <String>
 [-FriendlyName <String>] [-Description <String>] [-ShowInWebFeed <Boolean>] [<CommonParameters>]
```

## DESCRIPTION
The Set-RdsRemoteDesktop cmdlet sets the properties for a published desktop. You can edit the friendly name, description, and if it appears in the web feed. By changing the friendly name, you can set the name that appears to end-users for the published desktop in their Windows Virtual Desktop feed. 

## EXAMPLES

### Example 1: Set the friendly name that will appear in the feed
```powershell
PS C:\> Set-RdsRemoteDesktop -TenantName "Contoso" -HostPoolName "Contoso Host Pool" -AppGroupName "Desktop Application Group" -FriendlyName "Accounting - Desktop"

TenantGroupName   : Default Tenant Group
TenantName        : Contoso
HostPoolName      : Contoso Host Pool
AppGroupName      : Desktop Application Group
RemoteDesktopName : Remote Desktop
FriendlyName      : Accounting - Desktop
Description       :
ShowInWebFeed     :
```
This command sets the friendly name for the specified desktop app group. The provided friendly name will now be shown to end-users who have access to this app group.

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

### -Description
A 512 character string that describes the RemoteDesktop to help administrators. Any character is allowed.

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
A 256 character string that is displayed to end users in the Windows Virtual Desktop feed. Any character is allowed. 

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

### -ShowInWebFeed
Specifies whether to show the published desktop in the Windows Virtual Desktop feed. This allows you to temporarily disable a desktop and then re-enable it without deleting and re-creating the custom desktop information.

```yaml
Type: Boolean
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

### Microsoft.RDInfra.RDManagementData.RdMgmtPublishedDesktop

## NOTES

## RELATED LINKS
