using MSFT.WVD.Monitoring.Common.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace MSFT.WVD.Monitoring.Models
{
    public class HomePageViewModel
    {
        public RoleAssignment SelectedRole { get; set; }
        public string SelectedTenantGroupName { get; set; }
        public bool ShowDialog { get; set; }
    }

    public class HomePageSubmitModel
    {
        public string TenantGroupName { get; set; }
        public string TenantName { get; set; }
    }
}
