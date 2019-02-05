---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Disconnect-RdsUserSession

## SYNOPSIS
Disconnects a user from their current active session. 

## SYNTAX

```
Disconnect-RdsUserSession [-TenantName] <String> [-HostPoolName] <String> [-SessionHostName] <String>
 [-SessionId] <Int32> [-NoUserPrompt] [<CommonParameters>]
```

## DESCRIPTION
The Disconnect-RdsUserSession cmdlet disconnects the user from their current active session running on the specified session host. The user is not logged out, so all applications continue to run. The user can reconnect to their session by launching a connection again in their Remote Desktop client.

## EXAMPLES

### Example 1
```powershell
PS C:\> Disconnect-RdsUserSession -TenantName 'wvdtenant' -HostPoolName 'wvdhostpool' -SessionHostName 'wfdsessionhost' -SessionId 1
```

With named parameters

### Example 2
```powershell
PS C:\> Disconnect-RdsUserSession 'wvdtenant' 'wvdhostpool' 'wfdsessionhost' 1
```

Without named parameters

## PARAMETERS

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

### -NoUserPrompt
{{Fill NoUserPrompt Description}}

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

### -SessionHostName
Name of SessionHost.

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

### -SessionId
SessionId value.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

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

### System.Int32

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
