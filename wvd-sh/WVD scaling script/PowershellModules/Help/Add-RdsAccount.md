---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Add-RdsAccount

## SYNOPSIS
Adds an authenticated account and deployment URL to the context for RDS cmdlet requests. 

## SYNTAX

### AddAccountWithCredential (Default)
```
Add-RdsAccount [-DeploymentUrl] <String> [[-Credential] <PSCredential>] [<CommonParameters>]
```

### AddAccountWithServicePrincipal
```
Add-RdsAccount [-DeploymentUrl] <String> [-Credential] <PSCredential> [-ServicePrincipal]
 [-AadTenantId] <String> [<CommonParameters>]
```

### AddAccountWithThumbprint
```
Add-RdsAccount [-DeploymentUrl] <String> [-CertificateThumbprint] <String> [-ApplicationId] <String>
 [-AadTenantId] <String> [<CommonParameters>]
```

## DESCRIPTION
Adds an authenticated account and deployment URL to the context for RDS cmdlet requests. 

## EXAMPLES

### Example 1
```powershell
PS C:\> Add-RdsAccount -DeploymentUrl 'https://wvdbroker.microsoft.com'
```
This will launch AAD dialog to insert UPN and password.

## PARAMETERS

### -AadTenantId
Specifies the AAD tenant ID from which the service principal is a member.

```yaml
Type: String
Parameter Sets: AddAccountWithServicePrincipal, AddAccountWithThumbprint
Aliases: TenantId

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ApplicationId
SPN

```yaml
Type: String
Parameter Sets: AddAccountWithThumbprint
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CertificateThumbprint
Certificate Hash (Thumbprint)

```yaml
Type: String
Parameter Sets: AddAccountWithThumbprint
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
Specifies a PSCredential object. For more information about the PSCredential object, type Get-Help Get-Credential. The PSCredential object provides the user ID and password for organizational ID credentials, or the application ID and secret for service principal credentials.

```yaml
Type: PSCredential
Parameter Sets: AddAccountWithCredential
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: PSCredential
Parameter Sets: AddAccountWithServicePrincipal
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DeploymentUrl
Universal Resource Locator string pointing to the WVD deployment's management site. 

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ServicePrincipal
Is ServicePrincipal

```yaml
Type: SwitchParameter
Parameter Sets: AddAccountWithServicePrincipal
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### Microsoft.RDInfra.RDManagementData.RdMgmtContext

## NOTES

## RELATED LINKS
