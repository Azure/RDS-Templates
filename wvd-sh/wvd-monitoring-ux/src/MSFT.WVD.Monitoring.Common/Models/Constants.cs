using System;
using System.Collections.Generic;
using System.Text;

namespace MSFT.WVD.Monitoring.Common.Models
{
    public static class Constants
    {
        public const string invalidToken = "invalid token";
        public const string invalidCode = "invalid code";
        public const string tenantGroupName = "Default Tenant Group";

    }

    public class VMPerfCurrentStateQueries
    {
        public readonly string ProccessorUsage = "Perf | where Computer == '[hostName]' | where ObjectName == 'Processor Information' | where CounterName == '% Processor Time' | where InstanceName == '_Total' | summarize  (TimeGenerated, Value)=arg_min(TimeGenerated,CounterValue) by Computer, ObjectName , CounterName  | project ObjectName , CounterName,  avg = 0, Value, Computer, Status = iff(Value > 80 , false, true)";
        public readonly string LogicalDiskFreeSpace = "Perf | where Computer == '[hostName]' | where ObjectName == 'LogicalDisk' | where CounterName == '% Free Space' | summarize  (TimeGenerated, Value)=arg_min(TimeGenerated,CounterValue) by Computer, ObjectName , CounterName  | project  ObjectName , CounterName , avg = 0, Value, Computer, Status = iff(Value > 20 , false, true)";
        public readonly string AvailableMemory = "Perf | where Computer == '[hostName]' | where ObjectName == 'Memory' | where CounterName == 'Available MBytes' |  summarize  (TimeGenerated, Value)=arg_min(TimeGenerated,CounterValue) by Computer , ObjectName , CounterName | project  ObjectName , CounterName ,avg = 0, Value, Computer, Status = iff(Value > 500 , false, true)";
        public readonly string UserResponse = "Perf | where Computer == '[hostName]' | where ObjectName == 'User Input Delay per Session' | where CounterName == 'Max Input Delay' |  summarize  (TimeGenerated, Value)=arg_min(TimeGenerated,CounterValue) by Computer , ObjectName , CounterName | project  ObjectName , CounterName ,avg = 0, Value, Computer, Status = iff(Value > 2000 , false, true)";
        public readonly string LogicalDiskQueueLength = "Perf | where Computer == '[hostName]' | where ObjectName == 'LogicalDisk' | where CounterName == 'Avg. Disk Queue Length' | where InstanceName == 'C:' |  summarize  (TimeGenerated, Value)=arg_min(TimeGenerated,CounterValue) by Computer , ObjectName , CounterName | project  ObjectName , CounterName ,avg = 0, Value, Computer, Status = iff(Value > 5 , false, true)";


    }

    public class VMPerfTimeFrameQueries
    {
        public readonly string ProccessorUsage = "Perf | where Computer == '[hostName]' | where ObjectName == 'Processor Information' | where CounterName == '% Processor Time' | where InstanceName == '_Total' | where TimeGenerated >= todatetime('[StartTime]') and TimeGenerated <= todatetime('[EndTime]') |  summarize  (TimeGenerated, Value)=arg_min(TimeGenerated,CounterValue) by Computer, ObjectName , CounterName  | project ObjectName , CounterName,  avg = 0, Value, Computer, Status = iff(Value > 80 , false, true)";
        public readonly string LogicalDiskFreeSpace = "Perf | where Computer == '[hostName]' | where ObjectName == 'LogicalDisk' | where CounterName == '% Free Space' | where TimeGenerated >= todatetime('[StartTime]') and TimeGenerated <= todatetime('[EndTime]') | | summarize  (TimeGenerated, Value)=arg_min(TimeGenerated,CounterValue) by Computer, ObjectName , CounterName  | project  ObjectName , CounterName , avg = 0, Value, Computer, Status = iff(Value > 20 , false, true)";
        public readonly string AvailableMemory = "Perf | where Computer == '[hostName]' | where ObjectName == 'Memory' | where CounterName == 'Available MBytes' |  where TimeGenerated >= todatetime('[StartTime]') and TimeGenerated <= todatetime('[EndTime]') | summarize  (TimeGenerated, Value)=arg_min(TimeGenerated,CounterValue) by Computer , ObjectName , CounterName | project  ObjectName , CounterName ,avg = 0, Value, Computer, Status = iff(Value > 500 , false, true)";
        public readonly string UserResponse = "Perf | where Computer == '[hostName]' | where ObjectName == 'User Input Delay per Session' | where CounterName == 'Max Input Delay' |  where TimeGenerated >= todatetime('[StartTime]') and TimeGenerated <= todatetime('[EndTime]') | summarize  (TimeGenerated, Value)=arg_min(TimeGenerated,CounterValue) by Computer , ObjectName , CounterName | project  ObjectName , CounterName ,avg = 0, Value, Computer, Status = iff(Value > 2000 , false, true)";
        public readonly string LogicalDiskQueueLength = "Perf | where Computer == '[hostName]' | where ObjectName == 'LogicalDisk' | where CounterName == 'Avg. Disk Queue Length' | where InstanceName == 'C:' | where TimeGenerated >= todatetime('[StartTime]') and TimeGenerated <= todatetime('[EndTime]') |  summarize  (TimeGenerated, Value)=arg_min(TimeGenerated,CounterValue) by Computer , ObjectName , CounterName | project  ObjectName , CounterName ,avg = 0, Value, Computer, Status = iff(Value > 5 , false, true)";

    }
}
