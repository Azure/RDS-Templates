#region "Import Namespaces"
using System;
using System.Collections.Generic;
using System.Text;
#endregion "Import Namespaces"

#region "MSFT.RDMISaaS.API.Model"

namespace MSFT.WVDSaaS.API.Model
{
    #region "RdMgmtRoleAssignment"

    public class RdMgmtRoleAssignment
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
    #endregion "RdMgmtRoleAssignment"


}
#endregion "MSFT.RDMISaaS.API.Model"
