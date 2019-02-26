---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Remove-RdsRemoteApp

## SYNOPSIS
The Remove-RdsRemoteApp cmdlet removes a RemoteApp program from an AppGroup. When a RemoteApp program is removed, users can no longer use that program. This cmdlet does not delete the program executable. 

## SYNTAX

```
Remove-RdsRemoteApp [-TenantName] <String> [-HostPoolName] <String> [-AppGroupName] <String> [-Name] <String>
 [<CommonParameters>]
```

## DESCRIPTION
The Remove-RdsRemoteApp cmdlet removes a RemoteApp program from an AppGroup. When a RemoteApp program is removed, users can no longer use that program. This cmdlet does not delete the program executable. 

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

### -Name
Name of RemoteApp.

```yaml
Type: String
Parameter Sets: (All)
Aliases: RemoteAppName

Required: True
Position: 3
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
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

### System.Object
## NOTES

## RELATED LINKS
