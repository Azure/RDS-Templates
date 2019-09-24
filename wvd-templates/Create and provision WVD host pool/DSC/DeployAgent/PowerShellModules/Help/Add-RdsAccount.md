---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Add-RdsAccount

## SYNOPSIS
Adds an authenticated account to use for Windows Virtual Desktop cmdlet requests. 

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
The Add-RdsAccount cmdlet adds an authenticated account to use for Windows Virtual Desktop cmdlet requests. Upon completion, the context is automatically set to use the "Default Tenant Group" as the tenant groupo name. You can run the Set-RdsContext cmdlet to change the context.

## EXAMPLES

### Example 1: Connect to Windows Virtual Desktop through an interactive login
```powershell
PS C:\> Add-RdsAccount -DeploymentUrl "https://rdbroker.wvd.microsoft.com"

DeploymentUrl                       TenantGroupName       UserName
-------------                       ---------------       --------
https://rdbroker.wvd.microsoft.com  Default Tenant Group  admin@contoso.com
```
This command connects to a work or school account. To run Windows Virtual Desktop cmdlets with this account, you must provide organizational ID credentials at the prompt. If multi-factor authentication is enabled for your credentials, you must log in using the interactive option or use service principal authentication.

### Example 2: Connect to Windows Virtual Desktop using organizational ID credentials
````powershell
PS C:\> $Credential = Get-Credential
PS C:\> Add-RdsAccount -DeploymentUrl "https://rdbroker.wvd.microsoft.com"

DeploymentUrl                       TenantGroupName       UserName
-------------                       ---------------       --------
https://rdbroker.wvd.microsoft.com  Default Tenant Group  admin@contoso.com
````
The first command will prompt for user credentials (username and password), and then stores them in the $Credential variable. The second command connects to the Azure AD account using the credentials stored in $Credential. This account authenticates with Windows Virtual Desktop using organizational ID credentials. If multi-factor authentication is enabled for your credentials, you must log in using the interactive option or use service principal authentication.

### Example 3: Connect to Windows Virtual Desktop using a service principal account with password credentials
````powershell
PS C:\> $Credential = Get-Credential
PS C:\> Add-RdsAccount -DeploymentUrl "https://rdbroker.wvd.microsoft.com" -ServicePrincipal -AadTenantId "xxxx-xxxx-xxxx-xxxx"

DeploymentUrl                       TenantGroupName       UserName
-------------                       ---------------       --------
https://rdbroker.wvd.microsoft.com  Default Tenant Group  admin@contoso.com
````
The first command gets the service principal credentials (Application ID and service principal secret), and then stores them in the $Credential variable. The second command connects to the Azure AD account using the service principal credentials stored in $Credential for the specified Tenant. The ServicePrincipal switch parameter indicates that the account authenticates as a service principal.

### Example 4: Connect to Windows Virtual Desktop using a service principal account with certificate credentials
```powershell
# For more information on creating a self-signed certificate
# and giving it proper permissions, please see the following:
# https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-authenticate-service-principal-powershell
PS C:\> $Thumbprint = "0SZTNJ34TCCMUJ5MJZGR8XQD3S0RVHJBA33Z8ZXV"
PS C:\> $TenantId = "4cd76576-b611-43d0-8f2b-adcb139531bf"
PS C:\> $ApplicationId = "3794a65a-e4e4-493d-ac1d-f04308d712dd"
PS C:\> Add-RdsAccount -DeploymentUrl "https://rdbroker.wvd.microsoft.com" -CertificateThumbprint $Thumbprint -ApplicationId $ApplicationId -AadTenantId $TenantId

DeploymentUrl                       TenantGroupName       UserName
-------------                       ---------------       --------
https://rdbroker.wvd.microsoft.com  Default Tenant Group  admin@contoso.com
````

## PARAMETERS

### -AadTenantId
Specifies the Azure AD tenant ID from which the service principal is a member.

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
The application ID of the service principal to authenticate to Windows Virtual Desktop.

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
The thumbprint for the installed certificate to authenticate as the service principal to Windows Virtual Desktop.

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
The Universal Resource Locator (URL) string pointing to the Windows Virtual Desktop management site. 

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
Switch indicating that this account authenticates by providing service principal credentials.

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
