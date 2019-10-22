using System;
using System.IO;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication.OpenIdConnect;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.FileProviders;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Protocols.OpenIdConnect;
using MSFT.WVD.Diagnostics.Common.Services;

namespace MSFT.WVD.Diagnostics
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
            services.AddAuthentication(options =>
            {
                options.DefaultAuthenticateScheme = CookieAuthenticationDefaults.AuthenticationScheme;
                options.DefaultSignInScheme = CookieAuthenticationDefaults.AuthenticationScheme;
                options.DefaultChallengeScheme = OpenIdConnectDefaults.AuthenticationScheme;

            }).AddOpenIdConnect(options =>
            {
                options.Authority = $"{Configuration.GetSection("AzureAd").GetSection("Instance").Value}{Configuration.GetSection("AzureAd").GetSection("TenantId").Value}"; //+ this.TenantName; //358d0f13-4eda-45ea-886e-a6dcc6a70ae2
                options.ClientId = Configuration.GetSection("AzureAd").GetSection("ClientId").Value;
               options.ClientSecret = Configuration.GetSection("AzureAd").GetSection("ClientSecret").Value;
                options.ResponseType = OpenIdConnectResponseType.Code;
                options.ResponseMode = OpenIdConnectResponseMode.FormPost;
                options.CallbackPath = "/security/signin-callback";
                options.SignedOutRedirectUri = "/home/"; 
                options.TokenValidationParameters.ValidateIssuer = false;
                options.SaveTokens = true;
                options.Resource = Configuration.GetSection("configurations").GetSection("RESOURCE_URL").Value;
                options.UseTokenLifetime = true;
                
            }).AddCookie();
            
            IFileProvider physicalProvider = new PhysicalFileProvider(Directory.GetCurrentDirectory());
            services.AddSingleton<IFileProvider>(physicalProvider);

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

            services.AddSingleton<DiagnozeService>();
            services.AddSingleton<UserSessionService>();
            services.AddSingleton<LogAnalyticsService>();
            services.AddSingleton<CommonService>();
            services.AddSingleton<RoleAssignmentService>();
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IHostingEnvironment env, ILoggerFactory loggerFactory)
        {
            app.UseExceptionHandler("/Home/Error");
            app.UseStatusCodePagesWithRedirects("/Home/Error/{0}");
            app.UseHsts();
            app.UseHttpsRedirection();
            app.UseStaticFiles();
            loggerFactory.AddFile($"Logs/wvdMonitoringLog-{DateTime.Now.ToString("MMddyyyyyhhmmss")}.txt");
            app.UseAuthentication();
            app.UseSession();
            app.UseMvc(routes =>
            {
                routes.MapRoute(
                    name: "default",
                    template: "{controller=Home}/{action=Index}/{id?}");
            });
        }
    }
}