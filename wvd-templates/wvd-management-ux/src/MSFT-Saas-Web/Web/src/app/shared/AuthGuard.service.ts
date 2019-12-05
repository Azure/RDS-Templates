import { Injectable } from '@angular/core';
import { CanActivate } from '@angular/router';
import { Router, RouterStateSnapshot, ActivatedRouteSnapshot } from '@angular/router';
@Injectable()
export class AuthGuard implements CanActivate {
  private MSFTSaasRoutes;
  private parameter;
  constructor(private router: Router) {
  /*
   * all the restaraunt and admin components routers should be defined over here
   */
    this.MSFTSaasRoutes = ['/admin', '/admin/Tenants', '/admin/tenantDashboard', '/admin/hostpoolDashboard', '/admin/tenantDashboards', '/admin/hostpoolDashboards'];
  }

  /*
   * This Function is used to change URL function
   */
  public changeUrl() {
    var loginUrl = sessionStorage.getItem("LoginUrl");
    sessionStorage.clear();
    window.location.replace(loginUrl);
  }

  /*
   * This Function is used to call can active functionality
   */ 
  canActivate(route: ActivatedRouteSnapshot, state: RouterStateSnapshot) {
    var Code = sessionStorage.getItem("Code");
    if (Code != "undefined" && Code != null) {
      this.parameter = state.url.split('/')[state.url.split('/').length - 1];
      if (this.MSFTSaasRoutes.indexOf(state.url) >= 0 || decodeURIComponent(this.parameter) === route.params["tenantName"] || decodeURIComponent(this.parameter) === route.params["hostpoolName"] || this.parameter) {
        return true;
      }
      else {
        this.changeUrl();
      }
    }
    else {
      this.changeUrl();
      return false;
    }
  }
}

