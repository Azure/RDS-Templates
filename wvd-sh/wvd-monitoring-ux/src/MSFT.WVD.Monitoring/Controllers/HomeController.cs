﻿using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.AzureAD.UI;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication.OpenIdConnect;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MSFT.WVD.Monitoring.Common.Models;
using MSFT.WVD.Monitoring.Models;
using Newtonsoft.Json.Linq;

namespace MSFT.WVD.Monitoring.Controllers
{
    [Authorize]
    public class HomeController : Controller
    {
        public async Task<IActionResult> Index()
        {
            if (User.Identity.IsAuthenticated)
            {
                string upn = User.Claims.First(claim => claim.Type.Contains("upn")).Value;
                string accessToken = await HttpContext.GetTokenAsync("access_token");
                string refresh_token = await HttpContext.GetTokenAsync("refresh_token");
                string idToken = await HttpContext.GetTokenAsync("id_token");
                IEnumerable<RoleAssignment> tenantGroups = null;
                using (var client = new HttpClient())
                {
                    client.BaseAddress = new Uri("https://localhost:44393/api/");
                    //HTTP GET
                    var responseTask = client.GetAsync("RoleAssignment/TenantGroups?accessToken=" + accessToken + "&upn=" + upn );
                    responseTask.Wait();
                    
                    var result = responseTask.Result;
                    if (result.IsSuccessStatusCode)
                    {
                        //var readTask = result.Content.ReadAsAsync<JArray>();
                        var readTask = result.Content.ReadAsAsync<IList<RoleAssignment>>();
                        readTask.Wait();

                        tenantGroups = (IEnumerable<RoleAssignment>)readTask.Result;
                    }
                    else //web api sent error response 
                    {
                        //log response status here..

                        //tenantGroups = Enumerable.Empty<TenantGroup>();

                        ModelState.AddModelError(string.Empty, "Server error. Please contact administrator.");
                    }
                }
                //List<TenantGroup> lst = new List<TenantGroup>();
                //lst.Add(tenantGroups);
               
                return View(tenantGroups);
            }
            else
            {
                return null;
            }
        }

        public IActionResult Login()
        {
            return Challenge(new AuthenticationProperties { RedirectUri = "/" });
        }

        public IActionResult LoginCallback()
        {
            return Challenge(new AuthenticationProperties { RedirectUri = "/" });
        }
        //[HttpPost]
        //public SignOutResult  Logout()
        //{
        //    // await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
        //    //  await HttpContext.SignOutAsync(OpenIdConnectDefaults.AuthenticationScheme);
        //    //  await HttpContext.SignOutAsync(AzureADDefaults.AuthenticationScheme);
        //    return SignOut(
        //      new AuthenticationProperties { RedirectUri = "/" },
        //    //  CookieAuthenticationDefaults.AuthenticationScheme,
        //    //OpenIdConnectDefaults.AuthenticationScheme,
        //      AzureADDefaults.AuthenticationScheme);

        //}

        [HttpPost]
        public async Task<IActionResult> Logout()
        {
            await HttpContext.SignOutAsync(OpenIdConnectDefaults.AuthenticationScheme);
            await HttpContext.SignOutAsync(AzureADDefaults.AuthenticationScheme);
            return RedirectToAction("Login", "Home");
        }

        //public IActionResult SignOut()
        //{
        //    var callbackUrl = Url.Action("SignedOut", "Home", values: null, protocol: Request.Scheme);
        //    return SignOut(new AuthenticationProperties { RedirectUri = callbackUrl },
        //        AzureADDefaults.AuthenticationScheme);
        //}

        //public async Task EndSession()
        //{
        //    // If AAD sends a single sign-out message to the app, end the user's session, but don't redirect to AAD for sign out.
        //    await HttpContext.Authentication.SignOutAsync(AzureADDefaults.AuthenticationScheme);
        //}

        //public async Task<IActionResult> SignedOut()
        //{
        //    if (HttpContext.User.Identity.IsAuthenticated)
        //    {
        //        await EndSession();
        //    }

        //    return View();
        //}

        //public IActionResult About()
        //{
        //    ViewData["Message"] = "Your application description page.";

        //    return View();
        //}

        //public IActionResult Contact()
        //{
        //    ViewData["Message"] = "Your contact page.";

        //    return View();
        //}

        //public IActionResult Privacy()
        //{
        //    return View();
        //}

        //[ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
        //public IActionResult Error()
        //{
        //    return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
        //}

    }
}