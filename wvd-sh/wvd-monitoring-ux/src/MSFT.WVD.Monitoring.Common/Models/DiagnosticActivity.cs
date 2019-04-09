using System;
using System.Collections.Generic;
using System.Text;

namespace MSFT.WVD.Monitoring.Common.Models
{
    public class DiagnosticActivity
    {
        public string activityId { get; set; }
        public string activityType { get; set; }
        public Nullable<DateTime> startTime { get; set; }
        public Nullable<DateTime> endTime { get; set; }
        public string userName { get; set; }
        public string roleInstances { get; set; }
        public string outcome { get; set; }
        public Nullable<int> status { get; set; }
        public ConnectionDetails connectionDetails { get; set; }
        public ManagementDetails managementDetails { get; set; }
        public FeedDetails feedDetails { get; set; }
        public Nullable<DateTime> lastHeartbeatTime { get; set; }
        public List<Checkpoint> checkpoints { get; set; }
        public List<Error> errors { get; set; }
    }

    public class ConnectionDetails
    {
        public string ClientOS { get; set; }
        public string ClientVersion { get; set; }
        public string ClientType { get; set; }
        public object PredecessorConnectionId { get; set; }
        public string ClientIPAddress { get; set; }
        public string TenantId { get; set; }
        public string SessionHostPoolId { get; set; }
        public string ResourceAlias { get; set; }
        public string ResourceType { get; set; }
        public object LoadBalanceInfo { get; set; }
        public string SessionHostPoolName { get; set; }
        public string SessionHostName { get; set; }
        public string SessionHostIPAddress { get; set; }
        public object Resolution { get; set; }
        public object DisplayCount { get; set; }
        public string AgentOSVersion { get; set; }
        public string AgentOSDescription { get; set; }
        public string AgentSxsStackVersion { get; set; }
        public string Tenants { get; set; }
    }

    public class ManagementDetails
    {
        public string Object { get; set; }
        public string Method { get; set; }
        public string Route { get; set; }
        public int ObjectsFetched { get; set; }
        public int ObjectsCreated { get; set; }
        public int ObjectsUpdated { get; set; }
        public int ObjectsDeleted { get; set; }
        public string Tenants { get; set; }
    }

    public class FeedDetails
    {
        public string ClientOS { get; set; }
        public string ClientVersion { get; set; }
        public string ClientType { get; set; }
        public object ClientIPAddress { get; set; }
        public int TenantTotal { get; set; }
        public int TenantDownload { get; set; }
        public int TenantFailed { get; set; }
        public int RDPTotal { get; set; }
        public int RDPDownload { get; set; }
        public int RDPCache { get; set; }
        public int RDPFail { get; set; }
        public int IconTotal { get; set; }
        public int IconDownload { get; set; }
        public int IconCache { get; set; }
        public int IconFail { get; set; }
        public string Tenants { get; set; }
    }
    public class Parameters
    {
        public string disconnectType { get; set; }
        public string LoadBalanceOutcome { get; set; }
    }

    public class Checkpoint
    {
        public string name { get; set; }
        public DateTime time { get; set; }
        public int reportedBy { get; set; }
        public Parameters parameters { get; set; }
    }
    public class Error
    {
        public int errorSource { get; set; }
        public int errorOperation { get; set; }
        public int errorCode { get; set; }
        public string errorCodeSymbolic { get; set; }
        public string errorMessage { get; set; }
        public bool errorInternal { get; set; }
        public int reportedBy { get; set; }
        public Nullable<DateTime> time { get; set; }
    }


    public enum ActivityType
    {

        Connection = 0,
        Management = 1,
        Feed = 2,
        None = 3
    }


    public enum ActivityOutcome
    {
        Success = 0,
        Failure = 1,
        All = -1,
    }


    /***Activity class for each activity*****/

    public class ConnectionActivity
    {
        public string activityId { get; set; }
        public string activityType { get; set; }

        public Nullable<DateTime> startTime { get; set; }
        public Nullable<DateTime> endTime { get; set; }
        public string userName { get; set; }
        public string outcome { get; set; }
        public string Tenants { get; set; }
        public string SessionHostName { get; set; }
        public string isInternalError { get; set; }
        public string errorMessage { get; set; }
        public string ClientIPAddress { get; set; }
        public string ClientOS { get; set; }
    }

    public class ManagementActivity
    {
        public string activityId { get; set; }
        public string activityType { get; set; }
        public Nullable<DateTime> startTime { get; set; }
        public Nullable<DateTime> endTime { get; set; }
        public string userName { get; set; }
        public string outcome { get; set; }
        public string isInternalError { get; set; }
        public string errorMessage { get; set; }
        public string Tenants { get; set; }
        public string Object { get; set; }
        public string Method { get; set; }
        public string Route { get; set; }
        public int ObjectsFetched { get; set; }
        public int ObjectsCreated { get; set; }
        public int ObjectsUpdated { get; set; }
        public int ObjectsDeleted { get; set; }
    }

    public class FeedActivity
    {
        public string activityId { get; set; }
        public string activityType { get; set; }
        public Nullable<DateTime> startTime { get; set; }
        public Nullable<DateTime> endTime { get; set; }
        public string userName { get; set; }
        public string outcome { get; set; }
        public string isInternalError { get; set; }
        public string errorMessage { get; set; }
        public object ClientIPAddress { get; set; }
        public string ClientOS { get; set; }
    }
}
