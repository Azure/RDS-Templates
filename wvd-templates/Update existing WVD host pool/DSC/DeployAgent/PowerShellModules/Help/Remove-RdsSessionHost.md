---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Remove-RdsSessionHost

## SYNOPSIS
Removes a session host from a host pool.

## SYNTAX

```
Remove-RdsSessionHost [-TenantName] <String> [-HostPoolName] <String> [-Name] <String> [-Force]
 [<CommonParameters>]
```

## DESCRIPTION
The Remove-RdsSessionHost cmdlet removes a registered session host from the host pool. To re-register the session host to a host pool, you must re-install the agent with valid registration information for that host pool.

This command will fail if the session host has active user sessions. To complete the removal of the session host, you must first log off all users from the session host using the Invoke-RdsUserSessionLogoff cmdlet or re-run the Remove-RdsSessionHost cmdlet with the Force parameter.

When running this command to remove a session host from a persistent host pool, the user assignment is also removed. This is the only way to re-assign a user to a new session host in a persistent host pool.

## EXAMPLES

### Example 1: Remove a session host that has no active sessions
```powershell
PS C:\> Remove-RdsSessionhost -TenantName "Contoso" -HostPoolName "Contoso Host Pool" -Name "sh1.contoso.com"
```
This command removes a session host from a host pool. By running the Remove-RdsSessionHost cmdlet without the Force switch, it will only succeed if there are no active sessions on the specified session host. To force the users to log off of the session host, you can run the Invoke-RdsUserSessionLogoff cmdlet.

### Example 2: Remove a session host using the force switch
```powershell
PS C:\> Remove-RdsSessionhost -TenantName "Contoso" -HostPoolName "Contoso Host Pool" -Name "sh1.contoso.com" -Force
```
This command removes a session host from a host pool. By running the Remove-RdsSessionHost cmdlet with the Force switch, the session host will be immediately removed from the database, along with the user session information. This does not automatically log off the users and may result in a user losing their session state if they are accidentally disconnected from their session before performing a log off.

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
