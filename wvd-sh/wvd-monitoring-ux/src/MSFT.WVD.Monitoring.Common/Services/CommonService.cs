using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;

namespace MSFT.WVD.Monitoring.Common.Services
{
   public class CommonService
    {
        private const string tokenUrl = "https://login.microsoftonline.com//common/oauth2/token";
        public string GetAccessToken(string refreshToken)
        {
            //using (var client = new HttpClient())
            //{
            //    HttpRequestMessage request = new HttpRequestMessage(HttpMethod.Post, tokenUrl);

            //    content.Headers.ContentType = new MediaTypeHeaderValue("application/x-www-form-urlencoded");
            //    request.Content = $"grant_type=refresh_token&refresh_token={refreshToken}&resource=https://api.loganalytics.io/";
            //    HttpResponseMessage response = await client.SendAsync(request);
            //    return response;
            //}
            HttpResponseMessage response;

            Dictionary<string, string> requestdata = new Dictionary<string, string>();
            var url = tokenUrl;
            //requestdata.Add("redirect_uri", config.RedirectUrl);
            requestdata.Add("grant_type", "refresh_token");
            requestdata.Add("resource", "https://api.loganalytics.io");
            //requestdata.Add("client_id", "8099355f-6f68-4ea7-9190-59a5480782d2");
            requestdata.Add("refresh_token", refreshToken);
            using (HttpClient client = new HttpClient())
            {
                client.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
                response = client.PostAsync(url, new FormUrlEncodedContent(requestdata)).Result;
                return response.Content.ReadAsStringAsync().Result;
            }

        }

        //public HttpResponseMessage GetAccessTokenByRefreshToken(string refreshToken, ConfigSettings config)
        //{
        //    HttpResponseMessage response;
        //    try
        //    {
        //        Dictionary<string, string> requestdata = new Dictionary<string, string>();
        //        var url = config.TokenEndPoint;
        //        requestdata.Add("redirect_uri", config.RedirectUrl);
        //        requestdata.Add("grant_type", "refresh_token");
        //        requestdata.Add("resource", config.ResopurceUrl);
        //        requestdata.Add("client_id", config.ApplicationID);
        //        requestdata.Add("refresh_token", refreshToken);
        //        using (HttpClient client = new HttpClient())
        //        {
        //            client.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
        //            response = client.PostAsync(url, new FormUrlEncodedContent(requestdata)).Result;
        //            return response;
        //        }
        //    }
        //    catch (Exception ex)
        //    {
        //        return new HttpResponseMessage() { StatusCode = HttpStatusCode.InternalServerError, Content = new StringContent(ex.Message.ToString()) }; //Constants.invalidCode.ToString();
        //    }
        //}
    }
}
