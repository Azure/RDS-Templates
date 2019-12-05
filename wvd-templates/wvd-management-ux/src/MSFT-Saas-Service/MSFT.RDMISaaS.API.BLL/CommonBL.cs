#region "Import Namespaces"
using MSFT.WVDSaaS.API.Model;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

#endregion "Import Namespaces" 

#region "MSFT.RDMISaaS.API.BLL"
namespace MSFT.WVDSaaS.API.BLL
{
    #region "class-CommonBL"
    public static class CommonBL
    {

        /// <summary>
        /// Description-Initialize HttpClient
        /// </summary>
        /// <param name="deploymentUrl"></param>
        /// <param name="accessToken"></param>
        /// <returns></returns>
        public static HttpClient InitializeHttpClient(string deploymentUrl, string accessToken)
        {
            HttpClient client = new HttpClient();
            client.BaseAddress = new Uri(deploymentUrl);
            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
            client.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
            client.Timeout = TimeSpan.FromMinutes(10);
            return client;
        }

        /// <summary>
        /// Description : this method is used to extend http client update function call i.e patch
        /// </summary>
        /// <param name="deploymentUrl"></param>
        /// <param name="accessToken"></param>
        /// <param name="requestUri"></param>
        /// <param name="content"></param>
        /// <returns></returns>
        public static Task<HttpResponseMessage> PatchAsync(string deploymentUrl, string accessToken, string requestUri, HttpContent content)
        {
            HttpClient client = InitializeHttpClient(deploymentUrl, accessToken);
            HttpRequestMessage request = new HttpRequestMessage
            {
                Method = new HttpMethod("PATCH"),
                RequestUri = new Uri(client.BaseAddress + requestUri),
                Content = content,
            };
            return client.SendAsync(request);
        }
        /// <summary>
        /// Description : Get error message from consumed rest service
        /// </summary>
        /// <param name="jsondata"></param>
        /// <returns></returns>
        public static string GetErrorMessage(string jsonData)
        {
            string message = "";
            ErrorResult objerrror = Newtonsoft.Json.JsonConvert.DeserializeObject<ErrorResult>(jsonData);
            if (objerrror != null && objerrror.error != null)
            {
                if (objerrror.error.details != null && objerrror.error.details.Count > 0)
                {
                    if (!string.IsNullOrEmpty(objerrror.error.details[objerrror.error.details.Count - 1].message))
                    {
                        message = objerrror.error.details[objerrror.error.details.Count - 1].message.ToString();
                        if (message.StartsWith("{"))
                        {
                            message = objerrror.error.details[0].message.ToString();
                        }
                    }
                }
                else
                {
                    message = objerrror.error.message.ToString();
                }

                if (message == "UnauthorizedAccess")
                {
                    message = "Access denied. You are not authorized user for this operation. You have limited rights to this RDmi. Please contact your administrator.";
                }
            }
            return message;
        }
    }
    #endregion  "Class - CommonBL"
}
#endregion "MSFT.RDMISaaS.API.BLL" 