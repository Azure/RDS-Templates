---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# New-RdsAppGroup

## SYNOPSIS
This cmdlet creates a new app group within the scope of tenant and host pool. If the app group has a ResourceType set to RemoteApp, then it is empty until applications are explicitly published to the app group.

## SYNTAX

```
New-RdsAppGroup [-TenantName] <String> [-HostPoolName] <String> [-Name] <String> [-Description <String>]
 [-FriendlyName <String>] [-ResourceType <AppGroupResource>] [<CommonParameters>]
```

## DESCRIPTION
This cmdlet creates a new app group within the scope of tenant and host pool. If the app group has a ResourceType set to RemoteApp, then it is empty until applications are explicitly published to the app group.

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```


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
The unique name of the host pool within which this app group is created. 

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
Name of AppGroup

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
Must be set to either Desktop or RemoteApp. If the resource type is set to RemoteApp, then the app group is empty until applications are published to the app group. The ResourceType can only be set to Desktop if there is no existing Desktop app group for the specified host pool. If the ResourceType is set to Desktop, then a published desktop is automatically created. 

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

### Microsoft.RDInfra.RDManagementData.RdMgmtAppGroup

## NOTES

## RELATED LINKS
