---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Send-RdsUserSessionMessage

## SYNOPSIS
Sends a system message to a user session.

## SYNTAX

```
Send-RdsUserSessionMessage [-TenantName] <String> [-HostPoolName] <String> [-SessionHostName] <String>
 [-SessionId] <Int32> [-MessageTitle] <String> [-MessageBody] <String> [-NoUserPrompt] [<CommonParameters>]
```

## DESCRIPTION
The Send-RdsUserSessionmessage cmdlet sends a system message to a specified user session. Because the user session ID is unique only within the context of a session host, a different session host server can share the same user session ID. The session host and session ID that you specify by using this cmdlet uniquely identify a session within a host pool. If the session ID is not present, then the message is broadcast to all user sessions on the session host.

## EXAMPLES

### Example 1: Send a message to a user session by providing all required information
```powershell
PS C:\> Send-RdsUserSessionMessage -TenantName "Contoso" -HostPoolName "Contoso Host Pool" -SessionHostName "sh1.contoso.com" -SessionId 1 -MessageTitle "Test announcement" -MessageBody "Test message."
```
This command sends a message to the specified user session. This command requires you to have looked up the user session previously to provide all of the required information. By running the Send-RdsUserSessionMessage cmdlet without the NoUserPrompt switch, you will be asked to confirm to send the message.

### Example 2: Send a message to a user by searching for their user session
```powershell
PS C:\> Get-RdsUserSession -TenantName "Contoso" -HostPoolName "Contoso Host Pool" | where { $_.UserPrincipalName -eq "contoso\user1" } | Send-RdsUserSessionMessage -MessageTitle "Test announcement" -MessageBody "Test message." -NoUserPrompt
```
This command uses the Get-RdsUserSession cmdlet to search for the specific user's session, then pipes it into the Send-RdsUserSessionMessage cmdlet to send a message to the user session. By running the Send-RdsUserSessionMessage cmdlet with the NoUserPrompt switch, you will not receive any additional prompt to confirm to send the message.

## PARAMETERS

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

### -MessageBody
The body of the message you want to send to the user session.

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
The title of the message you want to send to the user session.

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
The switch indicating that you would like to disconnect the user without any additional confirmation.

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
The name of the session host.

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
The session ID correlating to the user session that will receive the message.

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

### System.Int32

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
