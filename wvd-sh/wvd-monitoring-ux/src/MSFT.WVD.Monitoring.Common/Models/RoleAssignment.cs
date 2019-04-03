using System;
using System.Collections.Generic;
using System.Text;

namespace MSFT.WVD.Monitoring.Common.Models
{
    public class RoleAssignment
    {
        public string roleAssignmentId { get; set; }
        public string scope { get; set; }
        public object displayName { get; set; }
        public string signInName { get; set; }
        public string roleDefinitionName { get; set; }
        public string roleDefinitionId { get; set; }
        public string objectId { get; set; }
        public string objectType { get; set; }
    }
    
}
