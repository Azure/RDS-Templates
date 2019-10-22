---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Set-RdsTenant

## SYNOPSIS
Sets properties for a tenant.

## SYNTAX

```
Set-RdsTenant [-Name] <String> [-AadTenantId <String>] [-FriendlyName <String>] [-Description <String>]
 [-SsoAdfsAuthority <String>] [-SsoClientId <String>] [-SsoClientSecret <String>] [<CommonParameters>]
```

## DESCRIPTION
The Set-RdsTenant cmdlet sets properties for a tenant. You can use this cmdlet to set the required properties to enable single sign-on with ADFS.

## EXAMPLES

### Example 1: Set properties for the tenant
```powershell
PS C:\> Set-RdsTenant -Name "Contoso" -FriendlyName "Contoso Apps and Desktops" -Description "Tenant for Contoso users to securely access their apps and desktops."

TenantGroupName  : Default Tenant Group
AadTenantId      : xxxx-xxxx-xxxx-xxxx-xxxx
TenantName       : Contoso
Description      : Tenant for Contoso users to securely access their apps and desktops.
FriendlyName     : Contoso Apps and Desktops
SsoAdfsAuthority : 
SsoClientId      : 
SsoClientSecret  : 
```
This command sets general properties for the tenant.

### Example 2: Set single sign-on properties for the tenant
```powershell
PS C:\> Set-RdsTenant -Name "Contoso" -SsoAdfsAuthority "https://sts.contoso.com/adfs" -SsoClientId "https://mrs-Prod.ame.gbl/mrs-RDInfra-prod" -SsoClientSecret $secureSecret

TenantGroupName  : Default Tenant Group
AadTenantId      : xxxx-xxxx-xxxx-xxxx-xxxx
TenantName       : Contoso
Description      : Tenant for Contoso users to securely access their apps and desktops.
FriendlyName     : Contoso Apps and Desktops
SsoAdfsAuthority : https://sts.contoso.com/adfs
SsoClientId      : https://mrs-Prod.ame.gbl/mrs-RDInfra-prod
SsoClientSecret  : **********
```
This command sets the required properties to enable single sign-on with ADFS. This is the last step in setting up single sign-on. Refer to the Windows Virtual Desktop documentation for all of the steps.

## PARAMETERS

### -AadTenantId
The Azure Active Directory tenant ID to be associated with the new tenant. Any users you assign to app groups within this tenant must exist in this Azure Active Directory.

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

### -Description
A 512 character string that describes the Tenant to help administrators. Any character is allowed. 

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
The name of the tenant.

```yaml
Type: String
Parameter Sets: (All)
Aliases: TenantName

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -SsoAdfsAuthority
The Universal Resource Locator (URL) string pointing to your ADFS cluster, typically in the format of https://sts.contoso.com/adfs . This URL must be accessible over the Internet so Windows Virtual Desktop can coordinate single sign-on.

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

### -SsoClientId
The ADFS client ID that identifies Windows Virtual Desktop application. Example: https://mrs-Prod.ame.gbl/mrs-RDInfra-prod

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

### -SsoClientSecret
The ADFS client secret that was generated when registering Windows Virtual Desktop to your ADFS cluster as a client. Example: zw26ykuGzIs4sG_wSJntJvBsvgnH5J_NfakWuQJQ 

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

## OUTPUTS

### Microsoft.RDInfra.RDManagementData.RdMgmtTenant

## NOTES

## RELATED LINKS
