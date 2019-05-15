using MSFT.WVD.Monitoring.Common.Models;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Threading.Tasks;

namespace MSFT.WVD.Monitoring.Models
{
    public class HomePageViewModel :IPageViewModel
    {
        public RoleAssignment SelectedRole { get; set; }
        public string SelectedTenantGroupName { get; set; }
        public bool ShowDialog { get; set; }
        public HomePageSubmitModel SubmitData { get; set; }
        public string Message { get; set; }
    }

    public class HomePageSubmitModel
    {
        [Required]
        public string TenantGroupName { get; set; }
        [Required]
        public string TenantName { get; set; }
    }
}
