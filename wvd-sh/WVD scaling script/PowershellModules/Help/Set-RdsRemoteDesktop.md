---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Set-RdsRemoteDesktop

## SYNOPSIS
Used to change the FriendlyName and Description of the published desktop for host pool’s desktop app group. 

## SYNTAX

```
Set-RdsRemoteDesktop [-TenantName] <String> [-HostPoolName] <String> [-AppGroupName] <String>
 [-FriendlyName <String>] [-Description <String>] [-ShowInWebFeed <Boolean>] [<CommonParameters>]
```

## DESCRIPTION
Used to change the FriendlyName and Description of the published desktop for host pool’s desktop app group. 

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

## PARAMETERS

### -AppGroupName
Name of AppGroup.

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
Name of HostPool.

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
Specifies whether to show the RemoteApp program in the RD web feed, and in RemoteApp and Desktop Connections to which the user subscribes. Default is 1. Note: This allows the admin to turn off an application temporarily and then turn it back on without deleting and re-creating the custom app information 

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
Name of Tenant.

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
