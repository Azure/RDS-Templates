---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# New-RdsTenant

## SYNOPSIS
Creates a tenant. 

## SYNTAX

```
New-RdsTenant [-Name] <String> [-AadTenantId] <String> [-FriendlyName <String>] [-Description <String>]
 [<CommonParameters>]
```

## DESCRIPTION
Creates a tenant in the current context. 

## EXAMPLES

### Example 1: Create a tenant
```powershell
PS C:\> New-RdsTenant -Name "Contoso" -AadTenantId "aaaa-aaaa-aaaa-aaaa"

TenantGroupName  : Default Tenant Group
AadTenantId      : aaaa-aaaa-aaaa-aaaa
TenantName       : Contoso
Description      : 
FriendlyName     : 
SsoAdfsAuthority :
SsoClientId      :
SsoClientSecret  :
```
This command creates a new tenant in the current context.

## PARAMETERS

### -AadTenantId
The Azure Active Directory tenant ID to be associated with the new tenant. Any users you assign to app groups within this tenant must exist in this Azure Active Directory.

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
The name of the tenant, which must be unique in the context.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

## OUTPUTS

### Microsoft.RDInfra.RDManagementData.RdMgmtTenant

## NOTES

## RELATED LINKS
