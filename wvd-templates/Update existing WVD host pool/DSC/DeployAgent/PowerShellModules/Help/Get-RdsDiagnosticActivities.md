---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Get-RdsDiagnosticActivities

## SYNOPSIS
Gets the details of a user action in the system. 

## SYNTAX

```
Get-RdsDiagnosticActivities [-StartTime <DateTime>] [-EndTime <DateTime>] [-ActivityType <ActivityType>]
 [-UserName <String>] [-ActivityId <Guid>] [-Outcome <Outcome>] [-TenantName <String>] [-Deployment]
 [-Detailed] [<CommonParameters>]
```

## DESCRIPTION
The Get-RdsDiagnosticActivities cmdlet gets the details of a user action in the system, both for end-user or administrative purposes. The list of activities can be filtered by the following parameters:
- ActivityId
- ActivityType
- Outcome
- StartTime (and optionally, EndTime)
- UserName

You can combine multiple filters into a single query. If you do not specify a start time or a time range, you will receive a list of activities only for the last hour. You can also query with the -Detailed parameter to receive additional information about each activity. The additional information for each activity varies depending on the activity type.

## EXAMPLES

### Example 1: Retrieve basic diagnostic activities in a tenant
```powershell
PS C:\> Get-RdsDiagnosticActivities -TenantName "Contoso"

ActivityId        : xxxx-xxxx-xxxx-xxxx-xxxx
ActivityType      : Connection
StartTime         : 1/1/2018 3:20:00 PM
EndTime           :
UserName          : user1@contoso.com
RoleInstances     : rdwebclient;mrs-eus2r0c001-rdgateway-prod-staging::RD2818782CE977;mrs-eus2r0c001-rdbroker-prod-staging::RD2818785C1CF1;sh1.contoso.com;
Outcome           :
Status            : Ongoing
Details           :
LastHeartbeatTime : 1/1/2018 4:01:00 PM
Checkpoints       :
Errors            :

ActivityId        : xxxx-xxxx-xxxx-xxxx-xxxx
ActivityType      : Feed
StartTime         : 1/1/2018 3:52:20 PM
EndTime           : 1/1/2018 3:52:26 PM
UserName          : user2@contoso.com
RoleInstances     : rdwebclient;mrs-eus2r0c001-rdbroker-prod-staging::RD28187853BC78;
Outcome           : Success
Status            : Completed
Details           :
LastHeartbeatTime : 1/1/2018 3:52:26 PM
Checkpoints       :
Errors            :

ActivityId        : xxxx-xxxx-xxxx-xxxx-xxxx
ActivityType      : Management
StartTime         : 1/1/2018 3:44:54 PM
EndTime           : 1/1/2018 3:44:54 PM
UserName          : admin@contoso.com
RoleInstances     : mrs-eus2r0c001-rdbroker-prod-staging::RD28187853BC78;
Outcome           : Success
Status            : Completed
Details           : 
LastHeartbeatTime : 1/1/2018 3:44:54 PM
Checkpoints       : 
Errors            : 

ActivityId        : xxxx-xxxx-xxxx-xxxx-xxxx
ActivityType      : Connection
StartTime         : 1/1/2018 3:14:15 AM
EndTime           : 1/1/2018 3:18:00 AM
UserName          : user2@contoso.com
RoleInstances     : user2client.contoso.com;mrs-eus2r0c001-rdgateway-prod-staging::RD2818782C3626;mrs-eus2r0c001-rdbroker-prod::RD28187853BC78;sh1.contoso.com;
Outcome           : Success
Status            : Completed
Details           : 
LastHeartbeatTime : 1/1/2018 3:18:00 AM
Checkpoints       : 
Errors            : 
```
This command gets activities for the specified tenant. By running the Get-RdsDiagnosticActivities cmdlet without specifying a time range, you will only receive activities for the past hour.

### Example 2: Retrieve detailed diagnostic activities in a tenant
```powershell
PS C:\> Get-RdsDiagnosticActivities -TenantName "Contoso" -Detailed

ActivityId        : xxxx-xxxx-xxxx-xxxx-xxxx
ActivityType      : Connection
StartTime         : 1/1/2018 3:20:00 PM
EndTime           :
UserName          : user1@contoso.com
RoleInstances     : rdwebclient;mrs-eus2r0c001-rdgateway-prod-staging::RD2818782CE977;mrs-eus2r0c001-rdbroker-prod-staging::RD2818785C1CF1;sh1.contoso.com;
Outcome           :
Status            : Ongoing
Details           : {[ClientOS, ], [ClientVersion, ], [ClientType, ], [PredecessorConnectionId, ]...}
LastHeartbeatTime : 1/1/2018 4:01:00 PM
Checkpoints       : {RdpConnectionProgress, RdpConnectionProgress, RdpConnectionProgress, RdpConnectionProgress...}
Errors            : {}

ActivityId        : xxxx-xxxx-xxxx-xxxx-xxxx
ActivityType      : Feed
StartTime         : 1/1/2018 3:52:20 PM
EndTime           : 1/1/2018 3:52:26 PM
UserName          : user2@contoso.com
RoleInstances     : rdwebclient;mrs-eus2r0c001-rdbroker-prod-staging::RD28187853BC78;
Outcome           : Success
Status            : Completed
Details           : {[ClientOS, Win32 Chrome 70.0.3538.110], [ClientVersion, 1.0.4-wvd], [ClientType, HTML], [ClientIPAddress, ]...}
LastHeartbeatTime : 1/1/2018 3:52:26 PM
Checkpoints       : {TenantListComplete, TenantResourceComplete}
Errors            : {}

ActivityId        : xxxx-xxxx-xxxx-xxxx-xxxx
ActivityType      : Management
StartTime         : 1/1/2018 3:44:54 PM
EndTime           : 1/1/2018 3:44:54 PM
UserName          : admin@contoso.com
RoleInstances     : mrs-eus2r0c001-rdbroker-prod-staging::RD28187853BC78;
Outcome           : Success
Status            : Completed
Details           : {[Object, /RdsManagement/V1/TenantGroups/Default%20Tenant%20Group/Tenants/Contoso], [Method, Get], [Route,
                    Tenant::GetTenantAsync], [ObjectsFetched, 1]...}
LastHeartbeatTime : 1/1/2018 3:44:54 PM
Checkpoints       : {}
Errors            : {}

ActivityId        : xxxx-xxxx-xxxx-xxxx-xxxx
ActivityType      : Connection
StartTime         : 1/1/2018 3:14:15 AM
EndTime           : 1/1/2018 3:18:00 AM
UserName          : user2@contoso.com
RoleInstances     : user2client.contoso.com;mrs-eus2r0c001-rdgateway-prod-staging::RD2818782C3626;mrs-eus2r0c001-rdbroker-prod::RD28187853BC78;sh1.contoso.com;
Outcome           : Success
Status            : Completed
Details           : {[ClientOS, WINDOWS 10.0.17763], [ClientVersion, 10.0.17763.1], [ClientType, MSTSC], [PredecessorConnectionId, ]...}
LastHeartbeatTime : 1/1/2018 3:18:00 AM
Checkpoints       : {LoadBalancedNewConnection, RdpStackAuthenticaticatedUser, RdpStackAuthorization, OnConnected...}
Errors            : {}
```
This command gets detailed activities for the specified tenant.

### Example 3: Retrieve detailed diagnostics of a specific activity
```powershell
PS C:\> Get-RdsDiagnosticActivities -TenantName "Contoso" -ActivityGuid "xxxx-xxxx-xxxx-xxxx-xxxx" -Detailed

ActivityId        : xxxx-xxxx-xxxx-xxxx-xxxx
ActivityType      : Connection
StartTime         : 1/1/2018 3:20:00 PM
EndTime           :
UserName          : user1@contoso.com
RoleInstances     : rdwebclient;mrs-eus2r0c001-rdgateway-prod-staging::RD2818782CE977;mrs-eus2r0c001-rdbroker-prod-staging::RD2818785C1CF1;sh1.contoso.com;
Outcome           :
Status            : Ongoing
Details           : {[ClientOS, ], [ClientVersion, ], [ClientType, ], [PredecessorConnectionId, ]...}
LastHeartbeatTime : 1/1/2018 4:01:00 PM
Checkpoints       : {RdpConnectionProgress, RdpConnectionProgress, RdpConnectionProgress, RdpConnectionProgress...}
Errors            : {}
```
This command gets the specific detailed activity.

### Example 4: Retrieve detailed diagnostics of a specific user
```powershell
PS C:\> Get-RdsDiagnosticActivities -TenantName "Contoso" -UserName "user2@contoso.com" -Detailed

ActivityId        : xxxx-xxxx-xxxx-xxxx-xxxx
ActivityType      : Feed
StartTime         : 1/1/2018 3:52:20 PM
EndTime           : 1/1/2018 3:52:26 PM
UserName          : user2@contoso.com
RoleInstances     : rdwebclient;mrs-eus2r0c001-rdbroker-prod-staging::RD28187853BC78;
Outcome           : Success
Status            : Completed
Details           : {[ClientOS, Win32 Chrome 70.0.3538.110], [ClientVersion, 1.0.4-wvd], [ClientType, HTML], [ClientIPAddress, ]...}
LastHeartbeatTime : 1/1/2018 3:52:26 PM
Checkpoints       : {TenantListComplete, TenantResourceComplete}
Errors            : {}

ActivityId        : xxxx-xxxx-xxxx-xxxx-xxxx
ActivityType      : Connection
StartTime         : 1/1/2018 3:14:15 AM
EndTime           : 1/1/2018 3:18:00 AM
UserName          : user2@contoso.com
RoleInstances     : user2client.contoso.com;mrs-eus2r0c001-rdgateway-prod-staging::RD2818782C3626;mrs-eus2r0c001-rdbroker-prod::RD28187853BC78;sh1.contoso.com;
Outcome           : Success
Status            : Completed
Details           : {[ClientOS, WINDOWS 10.0.17763], [ClientVersion, 10.0.17763.1], [ClientType, MSTSC], [PredecessorConnectionId, ]...}
LastHeartbeatTime : 1/1/2018 3:18:00 AM
Checkpoints       : {LoadBalancedNewConnection, RdpStackAuthenticaticatedUser, RdpStackAuthorization, OnConnected...}
Errors            : {}
```
This command gets detailed activities associated with the specified user name.

### Example 5: Retrieve detailed diagnostics by a start time
```powershell
PS C:\> Get-RdsDiagnosticActivities -TenantName "Contoso" -StartTime "1/1/2018 3:45:00 PM" -Detailed

ActivityId        : xxxx-xxxx-xxxx-xxxx-xxxx
ActivityType      : Connection
StartTime         : 1/1/2018 3:20:00 PM
EndTime           :
UserName          : user1@contoso.com
RoleInstances     : rdwebclient;mrs-eus2r0c001-rdgateway-prod-staging::RD2818782CE977;mrs-eus2r0c001-rdbroker-prod-staging::RD2818785C1CF1;sh1.contoso.com;
Outcome           :
Status            : Ongoing
Details           : {[ClientOS, Win32 Edge 18.17763], [ClientVersion, 1.0.4-wvd], [ClientType, HTML], [PredecessorConnectionId, ]...}
LastHeartbeatTime : 1/1/2018 4:01:00 PM
Checkpoints       : {RdpConnectionProgress, RdpConnectionProgress, RdpConnectionProgress, RdpConnectionProgress...}
Errors            : {}

ActivityId        : xxxx-xxxx-xxxx-xxxx-xxxx
ActivityType      : Feed
StartTime         : 1/1/2018 3:52:20 PM
EndTime           : 1/1/2018 3:52:26 PM
UserName          : user2@contoso.com
RoleInstances     : rdwebclient;mrs-eus2r0c001-rdbroker-prod-staging::RD28187853BC78;
Outcome           : Success
Status            : Completed
Details           : {[ClientOS, Win32 Chrome 70.0.3538.110], [ClientVersion, 1.0.4-wvd], [ClientType, HTML], [ClientIPAddress, ]...}
LastHeartbeatTime : 1/1/2018 3:52:26 PM
Checkpoints       : {TenantListComplete, TenantResourceComplete}
Errors            : {}
```
This command gets detailed activities that have completed after the specified time or that have been ongoing as of the specified time.

### Example 6: Retrieve detailed diagnostics by a start time and end time
```powershell
PS C:\> Get-RdsDiagnosticActivities -TenantName "Contoso" -StartTime "1/1/2018 3:45:00 PM" -EndTime "1/1/2018 3:50:00 PM" -Detailed

ActivityId        : xxxx-xxxx-xxxx-xxxx-xxxx
ActivityType      : Connection
StartTime         : 1/1/2018 3:20:00 PM
EndTime           :
UserName          : user1@contoso.com
RoleInstances     : rdwebclient;mrs-eus2r0c001-rdgateway-prod-staging::RD2818782CE977;mrs-eus2r0c001-rdbroker-prod-staging::RD2818785C1CF1;sh1.contoso.com;
Outcome           :
Status            : Ongoing
Details           : {[ClientOS, Win32 Edge 18.17763], [ClientVersion, 1.0.4-wvd], [ClientType, HTML], [PredecessorConnectionId, ]...}
LastHeartbeatTime : 1/1/2018 4:01:00 PM
Checkpoints       : {RdpConnectionProgress, RdpConnectionProgress, RdpConnectionProgress, RdpConnectionProgress...}
Errors            : {}
```
This command gets detailed activities that have completed during the specified time or that has been ongoing since the specified time range.

### Example 7: Retrieve detailed diagnostics by activity type
```powershell
PS C:\> Get-RdsDiagnosticActivities -TenantName "Contoso" -ActivityType Connection -Detailed

ActivityId        : xxxx-xxxx-xxxx-xxxx-xxxx
ActivityType      : Connection
StartTime         : 1/1/2018 3:20:00 PM
EndTime           :
UserName          : user1@contoso.com
RoleInstances     : rdwebclient;mrs-eus2r0c001-rdgateway-prod-staging::RD2818782CE977;mrs-eus2r0c001-rdbroker-prod-staging::RD2818785C1CF1;sh1.contoso.com;
Outcome           :
Status            : Ongoing
Details           : {[ClientOS, Win32 Edge 18.17763], [ClientVersion, 1.0.4-wvd], [ClientType, HTML], [PredecessorConnectionId, ]...}
LastHeartbeatTime : 1/1/2018 4:01:00 PM
Checkpoints       : {RdpConnectionProgress, RdpConnectionProgress, RdpConnectionProgress, RdpConnectionProgress...}
Errors            : {}

ActivityId        : xxxx-xxxx-xxxx-xxxx-xxxx
ActivityType      : Connection
StartTime         : 1/1/2018 3:14:15 AM
EndTime           : 1/1/2018 3:18:00 AM
UserName          : user2@contoso.com
RoleInstances     : user2client.contoso.com;mrs-eus2r0c001-rdgateway-prod-staging::RD2818782C3626;mrs-eus2r0c001-rdbroker-prod::RD28187853BC78;sh1.contoso.com;
Outcome           : Success
Status            : Completed
Details           : {[ClientOS, WINDOWS 10.0.17763], [ClientVersion, 10.0.17763.1], [ClientType, MSTSC], [PredecessorConnectionId, ]...}
LastHeartbeatTime : 1/1/2018 3:18:00 AM
Checkpoints       : {LoadBalancedNewConnection, RdpStackAuthenticaticatedUser, RdpStackAuthorization, OnConnected...}
Errors            : {}
```
This command gets detailed activities that match the specified activity type.

## PARAMETERS

### -ActivityId
The ID of the activity.

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
The type of the activity. Activities are classified into the following categories:
- Connection
- Feed
- Management

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
A scope specific to Windows Virtual Desktop.

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
A switch indicating to return more detailed information for each activity. The additional information returned will vary depending on the type of each activity.

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
The date time to use as the upper bound for querying activities.

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
The outcome of the activity. Activities can have one of two outcomes:
- Success
- Failure

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
The date time to use as the lower bound for querying activities.

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
The name of the tenant associated with the activity.

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
The user principal name (UPN) of the user associated with the activity.

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
