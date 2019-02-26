---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Get-RdsDiagnosticActivities

## SYNOPSIS
Gets the details of a user action in the system, either admin or end-user. 

## SYNTAX

```
Get-RdsDiagnosticActivities [-StartTime <DateTime>] [-EndTime <DateTime>] [-ActivityType <ActivityType>]
 [-UserName <String>] [-ActivityId <Guid>] [-Outcome <Outcome>] [-TenantName <String>] [-Deployment]
 [-Detailed] [<CommonParameters>]
```

## DESCRIPTION
The Get-RdsDiagnosticActivities cmdlet gets the details of the specified user action in the system.

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-RdsDiagnosticActivities
```

Retrieves the activities from the past one hour.

## PARAMETERS

### -ActivityId
The ID of the activity

```yaml
Type: Guid
Parameter Sets: (All)
Aliases: Id

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ActivityType
The type of the activity

```yaml
Type: ActivityType
Parameter Sets: (All)
Aliases: Type
Accepted values: Connection, Management, Feed, RegistrationToken

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Deployment
Get deployment-level activities

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Detailed
Get detailed information

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -EndTime
The time before which the activity ended (local)

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases: End

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Outcome
The outcome of the activity

```yaml
Type: Outcome
Parameter Sets: (All)
Aliases:
Accepted values: Success, Failure

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -StartTime
The time after which the activity started (local)

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases: Start

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -TenantName
The tenant of the activity

```yaml
Type: String
Parameter Sets: (All)
Aliases: Tenant

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -UserName
The username for the activity

```yaml
Type: String
Parameter Sets: (All)
Aliases: User

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Nullable`1[[System.DateTime, mscorlib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089]]

### System.Nullable`1[[Microsoft.RDInfra.Diagnostics.Common.ActivityType, Microsoft.RDInfra.Diagnostics.Common, Version=1.0.0.1, Culture=neutral, PublicKeyToken=99498ce06f56ba9d]]

### System.String

### System.Nullable`1[[System.Guid, mscorlib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089]]

### System.Nullable`1[[Microsoft.RDInfra.Diagnostics.Common.Outcome, Microsoft.RDInfra.Diagnostics.Common, Version=1.0.0.1, Culture=neutral, PublicKeyToken=99498ce06f56ba9d]]

### System.Management.Automation.SwitchParameter

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
