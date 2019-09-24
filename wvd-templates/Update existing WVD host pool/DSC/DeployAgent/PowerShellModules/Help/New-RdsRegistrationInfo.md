---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# New-RdsRegistrationInfo

## SYNOPSIS
Creates registration information for a host pool.

## SYNTAX

```
New-RdsRegistrationInfo [-TenantName] <String> [-HostPoolName] <String> [-ExpirationHours <Int32>]
 [<CommonParameters>]
```

## DESCRIPTION
The New-RdsRegistrationInfo cmdlet creates new registration information for the specified host pool. The token from the registration information must be provided when installing the agent to successfully register the session host to the host pool.

You can only have one set of registration information at a time for a given host pool. This command will fail if the host pool already has registration information. If you would like to rotate the registration information, run the Remove-RdsRegistrationInfo cmdlet first.

## EXAMPLES

### Example 1: Create new registration information for a host pool
```powershell
PS C:\> New-RdsRegistrationInfo -TenantName "Contoso" -HostPoolName "Contoso Host Pool" -ExpirationHours 48

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
This command creates new registration information for the host pool. The registration information is valid and can be retrieved until it expires using the Get-RdsRegistrationInfo cmdlet.

### Example 2: Create new registration information for a host pool and save the token to a text file.
```powershell
PS C:\> New-RdsRegistrationInfo -TenantName "Contoso" -HostPoolName "Contoso Host Pool" -ExpirationHours 48 | Select-Object -ExpandProperty Token > .\registrationtoken.txt
```
This command creates new registration information for the host pool and saves the value of the token into the registrationtoken.txt file in the local directory.

## PARAMETERS

### -ExpirationHours
The hours to add to the current time to mark as the expiration of the registration information. The default value is 48 hours. 

```yaml
Type: Int32
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
