using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.AzureAD.UI;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication.OpenIdConnect;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.HttpsPolicy;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Authorization;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.IdentityModel.Protocols.OpenIdConnect;
using MSFT.WVD.Monitoring.Common.Models;

namespace MSFT.WVD.Monitoring
{
    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
            //var list = new List<RoleAssignment>();
            //list.Add(new RoleAssignment());
            //HttpContext.Session.Set<IEnumerable<RoleAssignment>>("WVDRoles", list);
        }

        public IConfiguration Configuration { get; }

        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {
            //services.configure<cookiepolicyoptions>(options =>
            //{
            //    // this lambda determines whether user consent for non-essential cookies is needed for a given request.
            //    options.checkconsentneeded = context => true;
            //    options.minimumsamesitepolicy = samesitemode.none;
            //});



            services.AddAuthentication(options =>
            {
                options.DefaultAuthenticateScheme = CookieAuthenticationDefaults.AuthenticationScheme;
                options.DefaultSignInScheme = CookieAuthenticationDefaults.AuthenticationScheme;
                options.DefaultChallengeScheme = OpenIdConnectDefaults.AuthenticationScheme;

            }).AddOpenIdConnect(options =>
            {
                options.Authority = Configuration.GetSection("AzureAd").GetSection("Instance").Value+ Configuration.GetSection("AzureAd").GetSection("TenantId").Value; //+ this.TenantName; //358d0f13-4eda-45ea-886e-a6dcc6a70ae2
                options.ClientId = Configuration.GetSection("AzureAd").GetSection("ClientId").Value;
                options.ResponseType = OpenIdConnectResponseType.Code;
                options.CallbackPath = "/security/signin-callback";
                options.SignedOutRedirectUri = "/home/"; //"";

                // options.TokenValidationParameters.NameClaimType = "name";
                options.TokenValidationParameters.ValidateIssuer = false;
                options.SaveTokens = true;
                options.Resource = Configuration.GetSection("configurations").GetSection("RESOURCE_URL").Value;//newly added
            }).AddCookie();


            //services.Configure<CookiePolicyOptions>(options =>
            //{
            //    // This lambda determines whether user consent for non-essential cookies is needed for a given request.
            //    options.CheckConsentNeeded = context => false;
            //    options.MinimumSameSitePolicy = SameSiteMode.None;
            //});

            //services.AddAuthentication(AzureADDefaults.AuthenticationScheme)
            //  .AddAzureAD(options => Configuration.Bind("AzureAd", options)).AddCookie(OpenIdConnectDefaults.AuthenticationScheme);
            //services.Configure<OpenIdConnectOptions>(AzureADDefaults.OpenIdScheme, options =>
            //{
            //    options.Authority = options.Authority;//+ "/v2.0/"
            //    options.Resource = Configuration.GetSection("configurations").GetSection("RESOURCE_URL").Value;
            //    options.TokenValidationParameters.ValidateIssuer = false;
            //    options.ResponseType = OpenIdConnectResponseType.Code;
            //    options.SaveTokens = true;
            //});
            ////    services.AddMvc(options =>
            ////{
            ////    var policy = new AuthorizationPolicyBuilder()
            ////        .RequireAuthenticatedUser()
            ////        .Build();
            ////    options.Filters.Add(new AuthorizeFilter(policy));
            ////}).SetCompatibilityVersion(CompatibilityVersion.Version_2_2);
            services.AddDistributedMemoryCache();
            services.AddMvc();
            services.AddSession(options =>
            {
                options.IdleTimeout = TimeSpan.FromMinutes(60);
            });



        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IHostingEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }
            else
            {
                app.UseExceptionHandler("/Home/Error");
                app.UseHsts();
            }

            app.UseHttpsRedirection();
            app.UseStaticFiles();
            //app.UseCookiePolicy();
            app.UseAuthentication();

            app.UseSession();
            app.UseMvcWithDefaultRoute();

            //app.UseMvc(routes =>
            //{
            //    routes.MapRoute(
            //        name: "default",
            //        template: "{controller=Home}/{action=Index}/{id?}");
            //});
        }
    }
}