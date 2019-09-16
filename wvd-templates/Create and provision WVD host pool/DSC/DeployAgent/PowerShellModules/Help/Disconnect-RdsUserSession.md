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
The Disconnect-RdsUserSession cmdlet disconnects the user from their current active session running on the specified session host. The user is not logged off, so all applications continue to run. The user can reconnect to their session by launching a connection again in their Remote Desktop client.

## EXAMPLES

### Example 1: Disconnect a user by providing all required information
```powershell
PS C:\> Disconnect-RdsUserSession -TenantName "Contoso" -HostPoolName "Contoso Host Pool" -SessionHostName "sh1.contoso.com" -SessionId 1
```
This command disconnects the user on the specified session host associated with the provided session ID. This command requires you to have looked up the user session previously to provide all of the required information. By running the Disconnect-RdsUserSession cmdlet without the NoUserPrompt switch, you will be asked to confirm to disconnect the user.

### Example 2: Disconnect a user by searching for their user session
```powershell
PS C:\> Get-RdsUserSession -TenantName "Contoso" -HostPoolName "Contoso Host Pool" | where { $_.UserPrincipalName -eq "contoso\user1" } | Disconnect-RdsUserSession -NoUserPrompt
```
This command uses the Get-RdsUserSession cmdlet to search for the specific user's session, then pipes it into the Disconnect-RdsUserSession cmdlet to disconnect the user. By running the Disconnect-RdsUserSession cmdlet with the NoUserPrompt switch, you will not receive any additional prompt to confirm to disconnect the user.

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
The session ID correlating to the user you want to disconnect.

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
