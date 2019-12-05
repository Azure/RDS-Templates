import { Component, OnInit } from '@angular/core';
import { Http, Response, Headers, RequestOptions } from '@angular/http';
import * as $ from 'jquery';
import { Router, ActivatedRoute, Params } from '@angular/router';
import { AppService } from "./shared/app.service";
import { trigger, state, style, transition, animate, keyframes } from '@angular/animations';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css'],
  /*
   * Animations for User Profile slidetoggle and Notification
   */
  animations: [
    trigger('slidetoggle', [
      state('slideup', style({
        height: '0px',
        visibility: 'hidden',
        transform: 'translateY(-2px)',
      })),
      state('slidedown', style({
        transform: 'translateY(0px)',
        minHeight: '200px'
      })),
      transition('slidedown <=> slideup', animate('125ms ease-in')),
    ]),
    trigger('slideNotification', [
      state('slideRight', style({
        transform: 'translateX(353px)'
      })),
      state('slideLeft', style({
        transform: 'translateX(0px)'
      })),
      transition('slideRight <=> slideLeft', animate('500ms ease-in')),
    ]),
  ]
})
export class AppComponent implements OnInit {
  state: string = 'slideup';
  public static notifications: any = [];
  public profileName: string;
  public profileIcon: string;
  public splitName: any = [];
  public tenantGroupNameList: any = [];
  public profileNameFirstName: string;
  public profileNameLastName: string;
  public roleDefinitionName: string;
  public scope: string;
  public RefreshToken: any;
  public profileEmail: string;
  public redirectUri: string;
  public NotificationHighlight: boolean = false;
  public ShowNotificationTab: boolean = false;
  public isSingoutButton: boolean = false;
  public showNotificationDialog: boolean = false;
  public isInvalidToken: boolean = true;
  public appLoader: boolean = false;
  public tenantGroupName: any;
  public errorMessage: string;
  public InfraPermission: string;
  constructor(private _AppService: AppService, private router: Router, private route: ActivatedRoute, private http: Http, ) {
    //localStorage.removeItem("TenantGroupName");
  }

  /* This function is used to Call Notifications
   * --------------
   * Parameters
   * status - Accepts Status of notification
   * title - Accepts Title of notification
   * msg - Accepts Message of notification
   * date - Accepts Date of notification
   * --------------  
   */
  static GetNotification(status: any, title: any, msg: any, date: any) {
    AppComponent.notifications.push({
      "icon": status,
      "title": title,
      "msg": msg,
      "time": date,
    });
  }

  /*
   * Public event that calls directly on page load
   */
  ngOnInit() {
    this.tenantGroupName = localStorage.getItem("TenantGroupName");
    var code = sessionStorage.getItem("Code");
    var gotCode = sessionStorage.getItem("gotCode");
    var tenantGroup = localStorage.getItem("TenantGroupName");
    this.profileIcon = sessionStorage.getItem("profileIcon");
    this.profileName = sessionStorage.getItem("profileName");
    this.roleDefinitionName = sessionStorage.getItem("roleDefinitionName");
    this.profileEmail = sessionStorage.getItem("profileEmail");
    this.scope = sessionStorage.getItem("Scope");
    this.InfraPermission = sessionStorage.getItem("infraPermission");
    if (code != "undefined" && code != null && gotCode == 'yes') {
      this.appLoader = true;
      this.redirectUri = sessionStorage.getItem('redirectUri');
      var codData = {
        Code: code,
      };
      fetch(this._AppService.ApiUrl + '/api/Login/PostLogin', {
        method: 'POST',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(codData)
      }).then(response => response.json())
        .then((respdata) => {
          if (respdata.Error != null) {
            if (respdata.Error.StatusCode == 400 || respdata.Error.StatusCode == 429) {
              this.errorMessage = respdata.Error.Message;
              this.appLoader = false;
            }
          }
          else {
            this.profileName = respdata.UserName[0].toUpperCase() + respdata.UserName.substring(1);

            /*This block of code is used to Split Letters from Username*/
            //Slit code -starts
            this.splitName = respdata.UserName.trim().replace(/[^a-zA-Z0-9 ]/g, '').trim().split(' ');
            if (this.splitName.length > 1) {
              this.profileNameFirstName = this.splitName[0];
              this.profileNameLastName = this.splitName[this.splitName.length - 1];
              this.profileIcon = this.profileNameFirstName[0].toUpperCase() + this.profileNameLastName[0].toUpperCase();
            }
            else {
              this.profileNameFirstName = this.splitName[0];
              this.profileIcon = this.profileNameFirstName.substring(0, 2).toUpperCase();
            }
            //Slit code -Ends

            /*This block of code is used to get the Role Assignment Acces level*/
            //Role Assignment Acces level -Starts
            this.tenantGroupNameList = respdata.TenantGroups;
            sessionStorage.setItem("profileIcon", this.profileIcon);
            sessionStorage.setItem("profileName", this.profileName);
           
            if(respdata.RoleAssignment==null || respdata.RoleAssignment=="" || respdata.RoleAssignment.length==0)
            {
              this.router.navigate(['/invalid-role-assignment']);
              this.appLoader = false;
            }
            else{
              sessionStorage.setItem("roleAssignments", JSON.stringify(respdata.RoleAssignment));
              if (this.tenantGroupNameList != null && this.tenantGroupNameList.length > 0) {
                this.roleDefinitionName = respdata.RoleAssignment[0].roleDefinitionName;
                sessionStorage.setItem("roleDefinitionName", this.roleDefinitionName);
  
                if (respdata.RoleAssignment[0].scope == '/') {
                  this.scope = 'All (Root)';
                  this.InfraPermission = 'All (Root)';
                }
                else {
                  this.scope = respdata.RoleAssignment[0].scope;
                  this.InfraPermission = respdata.RoleAssignment[0].scope;
  
                }
              }
              else {
                const tenantGroupListData = ['Default Tenant Group'];
                this.tenantGroupNameList = tenantGroupListData;
              }
              const unique = (value, index, self) => {
                return self.indexOf(value) === index;
              };
              const uniqueTenantGroups = this.tenantGroupNameList.filter(unique);
              localStorage.setItem("TenantGroups", JSON.stringify(uniqueTenantGroups));
              this.tenantGroupName = localStorage.getItem("TenantGroupName");
              //Role Assignment Acces level -Ends
              var roleDef = respdata.RoleAssignment[0].scope.substring(1).split("/");
              //sessionStorage.setItem('Scope', this.scope);
              sessionStorage.setItem('Scope', roleDef);
              sessionStorage.setItem('infraPermission', this.scope);
  
  
              this.profileEmail = respdata.Email;
              sessionStorage.setItem("Refresh_Token", respdata.Refresh_Token);
              sessionStorage.setItem("redirectUri", this.redirectUri);
              sessionStorage.setItem('profileEmail', this.profileEmail);
              sessionStorage.setItem('gotCode', 'no');
              this.appLoader = false;
              this.router.navigate(['/admin/Tenants']);
            }
           
           
          }
        }).catch((error: any) => {
          this.router.navigate(['/invalidtokenmessage']);
          this.appLoader = false;
        });
    }
    else if (gotCode != 'no') {
      sessionStorage.clear();
      let headers = new Headers({ 'Accept': 'application/json' });
      var url = this._AppService.ApiUrl + '/api/Login/GetLoginUrl';
      this.http.get(url, {
        headers: headers
      }).subscribe(values => {
        var loginUrl = values.json();
        sessionStorage.setItem("redirectUri", loginUrl.split('&')[2].split('=')[1]);
        sessionStorage.setItem('gotCode', 'yes');
        this.redirectUri = loginUrl.split('&')[2].split('=')[1];
        window.location.replace(loginUrl);
      });
    }
    else if (tenantGroup && window.location.pathname == "/") {
      this.router.navigate(['/admin/Tenants']);
    }
  }

  /*
   * This function is used to get Notification List
   */
  get NotificationList() {
    return AppComponent.notifications;
  }

  /*
   * This function is used to open Notification tray
   * ----------
   * parameters
   * $event - Accepts $event
   * ----------
   */
  public OpenMainNotification(event: any) {
    this.NotificationHighlight = true;
    this.showNotificationDialog = !this.showNotificationDialog;
  }

  /*
   * This function is used to close Notification tray
   * ----------
   * parameters
   * $event - Accepts $event
   * ----------
   */
  public CloseMainNotification(event: any) {
    this.NotificationHighlight = false;
    this.showNotificationDialog = false;
  }

  /*
   * This function is used to shows signout dropdown on click on user Name
   */
  public OpenSignOut() {
    this.showNotificationDialog = false;
    this.state = (this.state === 'slideup' ? 'slidedown' : 'slideup');
    if (this.state === 'slideup') {
      this.isSingoutButton = false;
    }
    else if (this.state === 'slidedown') {
      this.isSingoutButton = true;
    }
  }

  /*
   * This function is used to Signout User
   */
  public Signout() {
    sessionStorage.clear();
    localStorage.clear();
    let headers = new Headers({ 'Accept': 'application/json' });
    var url = this._AppService.ApiUrl + '/api/Login/GetRedirectUrl'
    this.http.get(url, {
      headers: headers
    }).subscribe(values => {
      var signouturl = values.json();
      window.location.replace("https://login.microsoftonline.com/common/oauth2/logout?post_logout_redirect_uri=" + signouturl);
      sessionStorage.removeItem('Code');
      sessionStorage.removeItem('LoginUrl');
      sessionStorage.removeItem('redirectUri');

    });
  }

  /*
   * This function is used to close the User profile on clicking Outside
   */
  public OnClickedOutside() {
    this.state = 'slideup';
    this.isSingoutButton = false;
  }

  /*
   * This function is used to Redirect to Home On click Home Icon
   */
  public OnClickHome() {
    this.router.navigate(['/admin/Tenants']);
  }

  /*
   * This function is used to Close Notification
   * ----------
   * parameters
   * data - Accepts Index of the notification
   * ----------
   */
  public NotifyClose(data: any) {
    AppComponent.notifications.splice(AppComponent.notifications.indexOf(data), 1);
  }

  /*
   * This function is used to Hide Nav Bar and Side Nav bar and it will run at a  new component is being instantiated
   */
  public onActivate() {
    if (window.location.pathname == '/invalidtokenmessage' || window.location.pathname ==  '/invalid-role-assignment') {
      this.isInvalidToken = false;
    }
    else {
      this.isInvalidToken = true;
    }
  }
}
