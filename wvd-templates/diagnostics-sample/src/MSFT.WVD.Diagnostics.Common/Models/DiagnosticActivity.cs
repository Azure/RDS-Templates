using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Text;

namespace MSFT.WVD.Diagnostics.Common.Models
{
   
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
        All = 2,
    }
    public enum startDateEnum
    {
        Lastonehour=1,
        sixhoursago=6,
        onedayago=24,
        oneweekago=168,
    }
    //public class Errors
    //{
    //    public string isInternalError { get; set; }
    //    public string errorMessage { get; set; }
    //}
    public class ConnectionActivity
    {
        public string activityId { get; set; }
        public string activityType { get; set; }
        public Nullable<DateTime> startTime { get; set; }
        public Nullable<DateTime> endTime { get; set; }
        public string userName { get; set; }
        public string outcome { get; set; }
        public string Tenants { get; set; }
        public string SessionHostPoolName { get; set; }
        public string SessionHostName { get; set; }
        public List<JObject> errors { get; set; }
        public string ClientIPAddress { get; set; }
        public string ClientOS { get; set; }
        public ErrorDetails ErrorDetails { get; set; }
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
        public ErrorDetails ErrorDetails { get; set; }
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
        public ErrorDetails ErrorDetails { get; set; }
    }
}
