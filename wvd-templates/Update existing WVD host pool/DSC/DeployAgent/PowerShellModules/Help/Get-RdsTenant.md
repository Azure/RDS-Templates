---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Get-RdsTenant

## SYNOPSIS
Gets tenants that are authorized for the current user. 

## SYNTAX

```
Get-RdsTenant [-Name <String>] [<CommonParameters>]
```

## DESCRIPTION
The Get-RdsTenant cmdlet gets tenants that are authorized for the current user. If you do not specify a tenant, this cmdlet returns all tenants authorized for the current user.

## EXAMPLES

### Example 1: Get all tenants in the current context
```powershell
PS C:\> Get-RdsTenant

TenantGroupName  : Default Tenant Group
AadTenantId      : aaaa-aaaa-aaaa-aaaa
TenantName       : Contoso
Description      : Windows Virtual Desktop tenant for Contoso.
FriendlyName     : Contoso
SsoAdfsAuthority :
SsoClientId      :
SsoClientSecret  :

TenantGroupName  : Default Tenant Group
AadTenantId      : aaaa-aaaa-aaaa-aaaa
TenantName       : ContosoATenant
Description      : Windows Virtual Desktop tenant for ContosoA.
FriendlyName     : ContosoA
SsoAdfsAuthority :
SsoClientId      :
SsoClientSecret  :
```
This command gets all tenants in the current context that are authorized for the current user.

### Example 2: Get a specific tenant
```powershell
PS C:\> Get-RdsTenant -Name "Contoso"

TenantGroupName  : Default Tenant Group
AadTenantId      : aaaa-aaaa-aaaa-aaaa
TenantName       : Contoso
Description      : Windows Virtual Desktop tenant for Contoso.
FriendlyName     : Contoso
SsoAdfsAuthority :
SsoClientId      :
SsoClientSecret  :
```
This command gets the specified tenant in the current context. The tenant is displayed only if the tenant exists in the current context and the current user is properly authorized.

## PARAMETERS

### -Name
The name of the tenant.

```yaml
Type: String
Parameter Sets: (All)
Aliases: TenantName

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
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
