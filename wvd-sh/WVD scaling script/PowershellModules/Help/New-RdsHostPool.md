---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# New-RdsHostPool

## SYNOPSIS
Creates a host pool for a tenant. The host pool contains one or more session hosts (Remote Desktop Session Host servers or Windows 10 VMs). Users can connect to session hosts in a host pool to run programs, save files, and use resources on those hosts. 

## SYNTAX

```
New-RdsHostPool [-TenantName] <String> [-Name] <String> [-Description <String>] [-FriendlyName <String>]
 [-Persistent] [<CommonParameters>]
```

## DESCRIPTION
Creates a host pool for a tenant. The host pool contains one or more session hosts (Remote Desktop Session Host servers or Windows 10 VMs). Users can connect to session hosts in a host pool to run programs, save files, and use resources on those hosts. 

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -Description
A 512 character string that describes the HostPool to help administrators. Any character is allowed. 

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

### -Name
Name of HostPool.

```yaml
Type: String
Parameter Sets: (All)
Aliases: HostPoolName

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Persistent
Not Implemented

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

### -TenantName
Name of Tenant

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

### Microsoft.RDInfra.RDManagementData.RdMgmtHostPool

## NOTES

## RELATED LINKS
