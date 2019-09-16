---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Set-RdsAppGroup

## SYNOPSIS
Sets properties for an app group. 

## SYNTAX

```
Set-RdsAppGroup [-TenantName] <String> [-HostPoolName] <String> [-Name] <String> [-Description <String>]
 [-FriendlyName <String>] [<CommonParameters>]
```

## DESCRIPTION
The Set-RdsAppGroup cmdlet sets properties for the specified app group. 

## EXAMPLES

### Example 1: Set properties for the app group
```powershell
PS C:\> Set-RdsAppGroup -TenantName "Contoso" -HostPoolName "Contoso Host Pool" -Name "Office Apps" -FriendlyName "Office" -Description "RemoteApp group for Office applications"

TenantGroupName : Microsoft Internal
TenantName      : Contoso
HostPoolName    : Contoso Host Pool
AppGroupName    : Office Apps
Description     : RemoteApp group for Office applications
FriendlyName    : Office
ResourceType    : RemoteApp
```
This command sets the properties for the app group.

## PARAMETERS

### -Description
A 512 character string that describes the app group to help administrators. Any character is allowed. 

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
The name of the app group.

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
