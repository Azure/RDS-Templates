using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace MSFT.WVD.Monitoring.Common.BAL
{
    public class RoleAssignmentBL
    {
        public HttpResponseMessage GetRoleAssignments(string deploymentUrl, string accessToken, string upn)
        {
            try
            {
                return CommonBL.InitializeHttpClient(deploymentUrl, accessToken).GetAsync("/RdsManagement/V1/Rds.Authorization/roleAssignments?upn=" + upn).Result;//.Result; //.ConfigureAwait(true).GetAwaiter().GetResult();
            }
            catch (Exception ex)
            {
                return new HttpResponseMessage(System.Net.HttpStatusCode.RequestTimeout) { Content = new StringContent(ex.InnerException.Message.ToString(), System.Text.Encoding.UTF8, "application/json") };
            }
        }
    }
}
