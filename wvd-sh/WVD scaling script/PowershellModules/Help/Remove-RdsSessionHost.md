---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Remove-RdsSessionHost

## SYNOPSIS
This cmdlet removes a registered session host from the host pool. To re-register the session host, the admin must get valid registration info for the host pool and copy it to the session host so that the host agent can re-register. 

## SYNTAX

```
Remove-RdsSessionHost [-TenantName] <String> [-HostPoolName] <String> [-Name] <String> [-Force]
 [<CommonParameters>]
```

## DESCRIPTION
This cmdlet removes a registered session host from the host pool. To re-register the session host, the admin must get valid registration info for the host pool and copy it to the session host so that the host agent can re-register. 

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

## PARAMETERS

### -Force
 Forces the removal of the session host, even if there are user session objects contained with the session host. 

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -HostPoolName
HostPool name.

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
SessionHost name.

```yaml
Type: String
Parameter Sets: (All)
Aliases: SessionHostName

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -TenantName
Tenant name.

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
