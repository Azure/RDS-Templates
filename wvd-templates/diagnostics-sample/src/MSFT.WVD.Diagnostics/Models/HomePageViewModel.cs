using MSFT.WVD.Diagnostics.Common.Models;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace MSFT.WVD.Diagnostics.Models
{
    public class HomePageViewModel :IPageViewModel
    {
        public RoleAssignment SelectedRole { get; set; }
        public string SelectedTenantGroupName { get; set; }
        public bool ShowDialog { get; set; }
        public HomePageSubmitModel SubmitData { get; set; }
        public string Message { get; set; }
        public List<string> TenantGroups { get; set; }
    }

    public class HomePageSubmitModel
    {
        [Required]
        public string TenantGroupName { get; set; }
        [Required]
        public string TenantName { get; set; }
    }
}
