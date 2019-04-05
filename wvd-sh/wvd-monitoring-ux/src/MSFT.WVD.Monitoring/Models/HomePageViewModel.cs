using MSFT.WVD.Monitoring.Common.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace MSFT.WVD.Monitoring.Models
{
    public class HomePageViewModel
    {
        public RoleAssignment selectedRole { get; set; }
        public string selectedTenantGroupName { get; set; }
    }

    public class HomePageSubmitModel
    {
        public string tenantGroupName { get; set; }
        public string tenantName { get; set; }
    }
}
