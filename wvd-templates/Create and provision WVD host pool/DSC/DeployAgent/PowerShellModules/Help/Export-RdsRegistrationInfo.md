---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Export-RdsRegistrationInfo

## SYNOPSIS
Exports registration information for a host pool. 

## SYNTAX

```
Export-RdsRegistrationInfo [-TenantName] <String> [-HostPoolName] <String> [<CommonParameters>]
```

## DESCRIPTION
The Export-RdsRegistrationInfo cmdlet exports the registration information for the specified host pool. The token from the registration information can then be used by new or existing session hosts to properly register to a host pool. The registration info is only valid for the specified amount of hours defined when running New-RdsRegistrationInfo.

This command will fail if the host pool does not have registration information.

## EXAMPLES

### Example 1: Export the registration information for a host pool
```powershell
PS C:\> Export-RdsRegistration -TenantName "Contoso" -HostPoolName "Contoso Host Pool"

Token           : xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx111111111111111111111111111111111111111111111111111111111
                  YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY222222222222222222222222222222222222222222222222222222222
                  zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz333333333333333333333333333333333333333333333333333333333
                  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa444444444444444444444444444444444444444444444444444444444
                  bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb555555555555555555555555555555555555555555555555555555555
                  cccccccccccccccccccccccccccccccccccccccccccc666666666666666666666666666666666666666666666666666666666
                  dddddddddddddddddddddddddddddddddddddddddddd777777777777777777777777777777777777777777777777777777777
                  eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee88888888888888888888888888
ExpirationTime  : 1/3/2018 12:00:00 PM
TenantGroupName : Default Tenant Group
TenantName      : Contoso
HostPoolName    : Contoso Host Pool
```
This command exports the registration information for the specified host pool.

### Example 2: Export the registration information for a host pool and save the token to a text file.
```powershell
PS C:\> Export-RdsRegistrationInfo -TenantName "Contoso" -HostPoolName "Contoso Host Pool" | Select-Object -ExpandProperty Token > .\registrationtoken.txt
```
This command exports the registration information for the host pool and saves the value of the token into the registrationtoken.txt file in the local directory.

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

### Microsoft.RDInfra.RDManagementData.RdMgmtRegistrationInfo

## NOTES

## RELATED LINKS
