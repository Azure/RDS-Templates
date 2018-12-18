---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# New-RdsTenant

## SYNOPSIS
Creates a new WVD Tenant within the deployment and TenantGroup specified in the RDS context. 

## SYNTAX

```
New-RdsTenant [-Name] <String> [-AadTenantId] <String> [-FriendlyName <String>] [-Description <String>]
 [<CommonParameters>]
```

## DESCRIPTION
Creates a new WVD Tenant within the deployment and TenantGroup specified in the RDS context. 

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```


## PARAMETERS

### -AadTenantId
Azure Active Directory tenant ID.

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
The name of the new Tenant.. Must be unique within the scope of the TenantGroup>. Uniqueness is case insensitive. May be up to 64 characters long. Must contain only letter, digit, space, underscore, apostrophe, or dash character. Must not contain leading or trailing spaces. Alias: TenantName. 

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
