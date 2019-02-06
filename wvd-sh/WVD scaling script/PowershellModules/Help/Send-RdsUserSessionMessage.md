---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Send-RdsUserSessionMessage

## SYNOPSIS
Sends a system message to a specified user session. Because the user session ID is unique only within the context of a session host, a different session host server can share the same user session ID. The session host and session ID that you specify by using this cmdlet uniquely identify a session within a host pool. If the session ID is not present, then the message is broadcast to all user sessions on the session host.

## SYNTAX

```
Send-RdsUserSessionMessage [-TenantName] <String> [-HostPoolName] <String> [-SessionHostName] <String>
 [-SessionId] <Int32> [-MessageTitle] <String> [-MessageBody] <String> [-NoUserPrompt] [<CommonParameters>]
```

## DESCRIPTION
Sends a system message to a specified user session. Because the user session ID is unique only within the context of a session host, a different session host server can share the same user session ID. The session host and session ID that you specify by using this cmdlet uniquely identify a session within a host pool. If the session ID is not present, then the message is broadcast to all user sessions on the session host.

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

## PARAMETERS

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

### -MessageBody
Specifies the text of the message body.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 5
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -MessageTitle
Specifies the text of the message title.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -NoUserPrompt
Whether user prompt should be shown.

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
SessionHost name.

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
Specifies a unique session ID on the host. Use Get-RdsUserSession to retrieve the unique ID for a specific session. If not present, then a message is sent to all User Sessions on the session host.

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
