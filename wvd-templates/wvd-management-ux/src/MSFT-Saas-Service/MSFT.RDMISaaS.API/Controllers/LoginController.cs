#region "Import Namespaces"
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web;
using System.Web.Http;
using System.Web.Http.Cors;
using MSFT.WVDSaaS.API.Common;
using MSFT.WVDSaaS.API.Model;
#endregion "Import Namespaces" 

#region "MSFT.WVDSaaS.API.Controllers"
namespace MSFT.WVDSaaS.API.Controllers
{
    [EnableCors(origins: "*", headers: "*", methods: "*")]

    #region "Class - LoginController"
    public class LoginController : ApiController
    {

        Configurations configurations = new Configurations();

        /// <summary>
        /// Description : Posting data To get logged in user details.
        /// </summary>
        /// <param name="data"></param>
        /// <returns></returns>
        [HttpPost]
        public async Task<IHttpActionResult> PostLogin([FromBody] Login data)
        {
            Login login = new Login();
            try
            {
                Common.Common obj = new Common.Common();
                List<Login> lst = new List<Login>();
                login =await obj.Login(data.Code);
            }
            catch (Exception ex)
            {
                return null;
            }
            return Ok(login);
        }

        /// <summary>
        /// Description - Get Application Login Url
        /// </summary>
        /// <returns></returns>
        [HttpGet]
        public string GetLoginUrl()
        {
            string stateGuid = Guid.NewGuid().ToString();
            string url = "";
            url = url + "https://login.microsoftonline.com/common/oauth2/authorize?";
            url = url + "client_id=" + configurations.applicationId;
            url = url + "&response_type=code";
            url = url + "&redirect_uri=" + configurations.redirectUrl;
            url = url + "&response_mode=query";
            url = url + "&resource=" + configurations.resourceUrl + "&state=" + stateGuid;
            //url = url + "&prompt=admin_consent";
            return url;
        }

        /// <summary>
        /// Description - Get Redirect Url i.e. Hosted Web Url
        /// </summary>
        /// <returns></returns>

        [HttpGet]
        public string GetRedirectUrl()
        {
            return configurations.redirectUrl;
        }
    }
    #endregion  "Class - LoginController"
}
#endregion "MSFT.RDMISaaS.API.Controllers" 