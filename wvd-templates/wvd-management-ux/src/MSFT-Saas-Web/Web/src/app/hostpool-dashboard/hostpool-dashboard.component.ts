import { Component, OnInit, Input, Output, OnChanges, EventEmitter, ViewChild, ElementRef } from '@angular/core';
import { FormGroup, FormControl, Validators, FormBuilder } from '@angular/forms'; //This is for Model driven form form
import { Http, Response, Headers, RequestOptions } from '@angular/http';
import * as $ from 'jquery';
import { Router, ActivatedRoute, Params } from '@angular/router';
import { AppService } from '../shared/app.service';
import { Observable } from "rxjs";
import { BreadcrumComponent } from "../breadcrum/breadcrum.component";
import { NotificationsService } from "angular2-notifications";
import { AppComponent } from "../app.component";
import * as FileSaver from 'file-saver';
import { IMyOptions, IMyDateModel, IMyDate } from 'mydatepicker';
import { SearchPipe } from "../../assets/Pipes/Search.pipe";
import { ClipboardModule } from 'ngx-clipboard';
import { trigger, state, style, animate, transition } from '@angular/animations';
import { AdminMenuComponent } from '../admin-menu/admin-menu.component';


@Component({

  selector: 'app-hostpool-dashboard',
  templateUrl: './hostpool-dashboard.component.html',
  styleUrls: ['./hostpool-dashboard.component.css'],
  /* Animations for Model slideup, slidedown and Maximize, Minimize */
  animations: [
    trigger('slidemodal', [
      state('down', style({
        transform: 'translateY(400px)',
        visibility: 'hidden',
      })),
      state('up', style({
        transform: 'translateY(0px)',
      })),
      state('maxmize', style({
        height: '75%',
      })),
      state('minimize', style({
        height: '50%',
      })),
      transition('down <=> up', animate('300ms ease-in')),
      transition('maxmize <=> minimize', animate('300ms ease-in')),
    ]),



  ]
})

export class HostpoolDashboardComponent implements OnInit {
  //approups starts 
  public tenantsList: any;
  public AppGrouppreviousPageNo: any = 1;
  public AppGroupCurrentPageNo: any = 1;
  public AppGroupNextPageNo: any = 1;
  public pageSize: any = 10;
  public appgroupsCount: any = 0;
  public initialSkip: any = 0;
  public curentIndex: any;
  public currentNoOfPagesCount: any = 1;
  public ListOfPages: any = [];
  public lastEntry: any = '';
  public listItems: any = 10;
  public userlistItems: any = 5;
  public userSessionlistItems: any = 5;
  public applistItems: any = 5;
  public scopeArray: any;
  public arcount: any = [];
  public isPrevious: boolean = false;
  public isNext: boolean = false;
  public hasError: boolean = false;
  public isDescending: boolean = false;
  public tenantGroupName: any;
  //hosts starts
  public HostpreviousPageNo: any = 1;
  public HostCurrentPageNo: any = 1;
  public HostNextPageNo: any = 1;
  public HostpageSize: any = 10;
  public hostCount: any = 0;
  public hostinitialSkip: any = 0;
  public curentHostIndex: any;
  public currentNoOfPagesHostCount: any = 1;
  public HostlastEntry: any = '';
  //hosts ends
  public state: string = 'down';
  public showAppGroupCreateDialog: boolean = false;
  public isEditAppgroupDisabled: boolean = true;
  public isDeleteAppgroupDisabled: boolean = true;
  public deleteCountSelectedAppgroups: any;
  public searchByDesktop: any;
  public refreshHostpoolLoading: boolean = false;
  public createAppGroupName: boolean = true;
  public appGroupsDeleteUrl: any;
  public AppgroupName: any;
  public appgroupFormEdit: any;
  public updateAppgroupUrl: any;
  public updateAppGroupLoading: any = false;
  public appGroupsList: any;
  public appGroupAppList: any;
  public appGroupAppListGallery: any;
  public editedLBody = false;
  public formCreateNewAppGroup: any;
  public btnSaveDisable: boolean = true;
  public appGroupCreateUrl: any;
  public appUsersList: any = [];
  public selectedAppGroupName: any;
  public appGroupDetails: any = {};
  public selectedResourceType: any;
  public selectedRadioBtn: any;
  public showAddAppDialog: boolean = false;
  public addAppsPathButtonDisable: boolean = true;
  public isDeleteAppsDisabled: boolean = true;
  public deleteCountSelectedApp: any;
  public AppPathName: boolean = true;
  public AppPath: boolean = true;
  public btnAddPathDisable: boolean = true;
  public createappGroupApps: any;
  public usersDeleteUrl: any;
  public newAppCreateGroup2: any;
  public newAppEditGroup: any;
  public selectedRemoteappName: any;
  public appListErrorFound: boolean = false;
  public usersListErrorFound: boolean = false;
  public detailsErrorFound: boolean = false;
  public hostListErrorFound: boolean = false;
  public appGroupListErrorFound: boolean = false;
  public hostpoolDetailsErrorFound: boolean = false;
  public showAddUserDialog: boolean = false;
  public isDeleteUserDisabled: boolean = true;
  public deleteCountSelectedUser: any;
  public userprincipalButtonDisable: boolean = true;
  public userPrincipalName: boolean = false;
  public addNewUser: any;
  public selectedUsergroupName: any;
  public addUserForm: any;
  public regeneratekeyURL: any;
  public tenantName: any;
  public hostPoolDetails: any = {};
  public hostPoolName: any;
  public tenantDashboard: any;
  public edited = false;
  public editedBodyAppGroup = false;
  public editedBodyApp = false;
  public editedBodyUsers = false;
  public editedLbodyUsers = false;
  public hostFormEdit: any;
  public responseValue: any;
  public responseMessage: any;
  public generatekeyURL: any;
  public hostpoolDetailsUrl: any;
  public getAllSessionHostUrl: any;
  public getAllAppGroupsListUrl: any;
  public getAppGroupDetailsUrl: any;
  public getAppGroupUserUrl: any;
  public getAppGroupAppsUrl: any;
  public getAllAppGroupAppsGalleryUrl: any;
  public generatekeyDetails: any;
  public regeneratekeyDetails: any;
  public sessionHostLists: any = [];
  public expiryDate: any;
  public sessionHostName: any;
  public hostDeleteUrl: any;
  public updateHostUrl: any;
  public showHostpoolTab: any;
  public showHostEmpty: boolean = false;
  public showHostCreate: boolean = false;
  public editHostDisabled: boolean = true;
  public deleteHostDisabled: boolean = true;
  public newGAppAdd: boolean = true;
  public GAppslist: boolean = false;
  public appGalleryErrorFound: boolean = false;
  public downloadFile: any;
  public checked: any = [];
  public sessionHostchecked: any = [];
  public checkedMainAppGroup: boolean;
  public checkedMainApp: boolean;
  public checkedMainGApp: boolean;
  public appGroupcheckedTrue: any = [];
  public checkedAllTrueAppGroup: any = [];
  public checkedAllTrueApps: any = [];
  public checkedAllTrueGApps: any = [];
  public appGroupsListSearch: any = [];
  public appGroupsAppListSearch: any = [];
  public sessionHostListsSearch: any = [];
  public appUsersListSearch: any = [];
  public sessionHostCheckedTrue: any = [];
  public sessionHostCheckedAllTrue: any = [];
  public sessionHostCheckedMain: boolean = false;
  public selectedAppGroupRows: any = [];
  public userCheckedTrue: any = [];
  public appCheckedTrue: any = [];
  public gappCheckedTrue: any = [];
  public checkedUsers: any = [];
  public checkedApps: any = [];
  public checkedGApps: any = [];
  public checkedMainUser: boolean;
  public checkedAllTrueUsers: any = [];
  public selectedUsersRows: any = [];
  public selectedAppRows: any = [];
  public selectedGAppRows: any = [];
  public selectedClassMax: any = true;
  public selectedClassMin: any = false;
  public removeAppsTab: boolean = true;
  public resourcetypeId: any;
  public isDate: boolean = false;
  public showAddAppGalleryDialog: boolean = false;
  public galleryAppLoader: boolean = false;
  public hostDeleteData: any;
  public currentNoOfAppsPagesCount: any = 1;
  public currentNoOfUsersPagesCount: any = 1;
  public appsCurentIndex: any;
  public usersCurentIndex: any;
  public appsCount: any = 0;
  public usersCount: any = 0;
  public appsInitialSkip: any = 0;
  public appsLastEntry: any = '';
  public appsPreviousPageNo: any = 1;
  public appsCurrentPageNo: any = 1;
  public appsIsDescending: boolean = false;
  public usersInitialSkip: any = 0;
  public usersLastEntry: any = '';
  public usersPreviousPageNo: any = 1;
  public usersCurrentPageNo: any = 1;
  public usersIsDescending: boolean = false;
  public galleryAppPageSize: any = 10;
  public pageNo: number = 1;
  public errorMessage: string;
  public error: boolean = false;
  public Hostslist: number = 1;
  public appslist: number = 1;
  public appGroupsPageNo: number = 1;
  public userslist: number = 1;
  public SearchByAppUser: any;
  public searchByAppName: any;
  public searchBySHSName: any;
  public showAppGroupDashBoard: boolean = false;
  public showHostDashBoard: boolean = false;
  public hostDetails: any = {};
  public getUserSessionUrl: any;
  public userSessions: any = [];
  public userSessionSearchList: any = [];
  public userSessionsCount: number = 0;
  public SessionsListErrorFound: boolean = false;
  public showSendMessageDialog: boolean = false;
  public sendMessageForm: any;
  public restartHostForm: any;

  //for user sessions
  public checkedUserSessions: any = [];
  public userSessionCheckedTrue: any = [];
  public isLogOffDisabled: boolean = true;
  public isSendMsgDisabled: boolean = true;
  public checkedMainUserSession: boolean;
  public selectedUserSessionsRows: any = [];
  public checkedAllTrueUserSessions: any = [];
  public CountSelectedUserSession: any;
  public userSessionlist: number = 1;
  public userSessionLogOffUrl: any;
  public selectedHostName: any;
  public SendMessageUrl: any;
  public userSessionslist: number = 1;
  public showRestartDialog: boolean = false;
  public RestartHostUrl: any;
  public restartHostDisabled: boolean = true;
  public drainHostDisabled: boolean = true;
  public HostAllowNewSession: boolean;
  public ChangeDrainModeUrl: any;
  public SearchBySessionList: any;
  public sendMesageButtonDisable: boolean = true;
  public UserSessionLoader: boolean = false;
  public Title: boolean = false;
  public Message: boolean = false;
  public isEditAppsDisabled: boolean = true;
  public showEditAppDialog: boolean = false;
  public selectedHostRows: any = [];
  @ViewChild('closeModal') closeModal: ElementRef;

  constructor(private _AppService: AppService, private fb: FormBuilder, private http: Http, private route: ActivatedRoute, private _notificationsService: NotificationsService, private router: Router,
    private adminMenuComponent: AdminMenuComponent) {

  }

  /*
   * Public event that calls directly on page load
   */
  ngOnInit() {
    this.tenantGroupName = localStorage.getItem("TenantGroupName");
    /*This block of code is used to get the Hostpool Name from the Url paramter*/
    this.route.params.subscribe(params => {
      //this.tenantGroupName = sessionStorage.getItem("TenantGroupName");
      this.state = 'down';
      this.checked = [];
      this.appGroupsListSearch = [];
      this.sessionHostListsSearch = [];
      this.hostPoolDetails = [];
      this.checkedMainAppGroup = false;
      this.isEditAppgroupDisabled = true;
      this.isDeleteAppgroupDisabled = true;
      this.tenantGroupName = localStorage.getItem("TenantGroupName");
      this.tenantName = sessionStorage.getItem('TenantName');
      this.hostPoolName = params["hostpoolName"];
      this.adminMenuComponent.getHostpoolIndex(this.hostPoolName, this.tenantName);
      let data = [{
        name: 'Tenants',
        type: 'Tenants',
        path: 'Tenants',
      }];
      BreadcrumComponent.GetCurrentPage(data);
      data = [{
        name: this.tenantName,
        type: 'Tenant',
        path: 'tenantDashboard',
      }];
      BreadcrumComponent.GetCurrentPage(data);
      data = [{
        name: this.hostPoolName,
        type: 'Hostpool',
        path: 'hostpoolDashboard',
      }];
      BreadcrumComponent.GetCurrentPage(data);
      this.scopeArray = sessionStorage.getItem("Scope").split(",");
      this.CheckAppGroupAccess(this.hostPoolName);
    });
    this.tenantDashboard = new FormGroup({
      local: new FormControl("", Validators.required),
      Description: new FormControl('', Validators.required),
    });
    this.newAppCreateGroup2 = new FormGroup({
      AppPath: new FormControl('', Validators.compose([Validators.required])),
      Name: new FormControl('', Validators.compose([Validators.required, Validators.pattern(/^[^\s\W\_]([A-Za-z0-9\s])+$/)])),
      IconPath: new FormControl('', Validators.compose([Validators.required])),
      IconIndex: new FormControl('', Validators.compose([Validators.required])),
      requiredCommandLine: new FormControl(''),
      friendlyName: new FormControl('')
    });
    this.addUserForm = new FormGroup({
      UserPrincipalName: new FormControl('', Validators.required),
    });

    this.sendMessageForm = new FormGroup({
      Title: new FormControl('', Validators.required),
      Message: new FormControl('', Validators.required)
    });

    this.appgroupFormEdit = new FormGroup({
      appGroupName: new FormControl(''),
      friendlyName: new FormControl(''),
      description: new FormControl(''),
      editRadiobtnAppType: new FormControl(''),
    });
    this.hostFormEdit = new FormGroup({
      sessionHostName: new FormControl(""),
      allowNewSession: new FormControl(""),
    });
    this.downloadFile = new FormGroup({
      filetype: new FormControl(""),
      FileName: new FormControl(""),
    });
    this.formCreateNewAppGroup = new FormGroup({
      txtAppGroupName: new FormControl('', Validators.compose([Validators.required, Validators.maxLength(36), Validators.pattern(/^[^\s\W\_]([A-Za-z0-9\s\-\_\.])+$/)])),
      txtAppGroupFrndName: new FormControl(''),
      txtAppGroupDesc: new FormControl(''),
      radiobtnAppType: new FormControl(''),
    });
    this.formCreateNewAppGroup.patchValue({ radiobtnAppType: 'Desktop' });
    this.scopeArray = sessionStorage.getItem("Scope").split(",");
  }

  public options: any = {
    timeOut: 2000,
    position: ["top", "right"]
  };

  /*
   * This Function is called on Component Load and it is used to check the Access level of AppGroup
   * ----------
   * Parameters
   * hostPoolName - Accepts the Hostpool Name
   * ----------
   */
  public CheckAppGroupAccess(hostPoolName: any) {
    if (this.scopeArray != null && this.scopeArray.length >= 4) {
      this.hostPoolDetails = {
        "hostPoolName": this.scopeArray[2],
      };
    }
    else {
      this.GetHostPoolDetails(hostPoolName);
    }
    this.adminMenuComponent.GetAllTenants();
    this.adminMenuComponent.GetHostpools(this.tenantName);
    this.GetAllAppGroupsList(hostPoolName);
    this.GetAllSessionHost();
  }

  /* This function is used to Change the Expiry Data
   * --------------
   * Parameters
   * Data - Accepts Event
   * --------------  
   */
  public ChangeData(data: any) {
    if (data == null || data == undefined || data == '') {
      this.tenantDashboard.local = '';
      this.expiryDate = '';
    }
    else {
      this.expiryDate = data.formatted;
      this.tenantDashboard.local = data.formatted;
      this.isDate = false;
    }
  }

  /*
   * Gets the current time, date and year
   */
  public myTime: Date = new Date();
  currentYear: any = this.myTime.getUTCFullYear();
  currentDate: any = this.myTime.getUTCDate();
  currentMonth: any = this.myTime.getUTCMonth() + 1; //months from 1-12

  /*
   * Date picker function
   */
  public myDatePickerOptions: IMyOptions = {
    disableUntil: { year: this.currentYear, month: this.currentMonth, day: this.currentDate },
    dateFormat: 'yyyy-mm-dd'
  };

  /* This function is used to close the Appgroup details, App & Users split view
    * --------------
    * Parameters
    * event - Accepts Event
    * --------------  
   */
  public AppGroupbottomClose(event: any) {
    this.state = 'down';
    event.preventDefault();
    this.checked = [];
    this.selectedClassMax = true;
    this.selectedClassMin = false;
    this.checkedMainAppGroup = false;
    this.isEditAppgroupDisabled = true;
    this.isDeleteAppgroupDisabled = true;
    this.showAppGroupDashBoard = false;
  }

  public userSesionBottomClose(event: any) {
    this.state = 'down';
    event.preventDefault();
    this.selectedClassMax = true;
    this.selectedClassMin = false;
    this.checkedMainUserSession = false;
    this.sessionHostCheckedMain = false;
    this.isLogOffDisabled = true;
    this.isSendMsgDisabled = true;
    this.sessionHostchecked = [];
    this.editHostDisabled = true;
    this.deleteHostDisabled = true;
    this.restartHostDisabled = true;
    this.drainHostDisabled = true;
    this.showHostDashBoard = false;
  }

  /* This function is used to close the Appgroup details, App & Users split view
   * --------------
   * Parameters
   * event - Accepts Event
   * --------------  
  */
  public AppGroupbottomBtnClose(event: any) {
    this.state = 'down';
    event.preventDefault();
    this.selectedClassMax = true;
    this.selectedClassMin = false;
  }

  /* This function is used to Maximize the Appgroup details, App & Users split view
   * --------------
   * Parameters
   * event - Accepts Event
   * --------------  
   */
  public MaxWindowOpen(event: any) {
    event.preventDefault();
    this.selectedClassMax = false;
    this.selectedClassMin = true;
    this.state = 'maxmize';

  };

  /* This function is used to Minimize the Appgroup details, App & Users split view
   * --------------
   * Parameters
   * event - Accepts Event
   * --------------  
   */
  public MinWindowOpen(event: any) {
    event.preventDefault();
    this.selectedClassMin = false;
    this.selectedClassMax = true;
    this.state = 'minimize';

  };

  public OpenAddHostDialog() {
    this.showHostCreate = true;
    this.tenantDashboard = new FormGroup({
      local: new FormControl('', Validators.required),
      Description: new FormControl('', Validators.required),
    });
    this.expiryDate = '';
    this.isDate = false;
    this.responseValue = "";
    this.responseMessage = "";
    this.AddHostKeyGenerate();
  }

  /*
   * This function is used to make service call to Generate Key for Adding/ Create Host
   */
  public AddHostKeyGenerate() {
    this.tenantDashboard = new FormGroup({
      local: new FormControl('', Validators.required),
      Description: new FormControl('', Validators.required),
    });
    this.expiryDate = '';
    this.isDate = false;
    this.responseValue = "";
    this.responseMessage = "";
    /*
     * Registration key and Expiry Data Service Calling
     */
    let headers = new Headers({ 'Accept': 'application/json' });
    var url = this._AppService.ApiUrl + '/api/RegistrationInfo/GetRegistrationInfo?tenantGroupName=' + this.tenantGroupName + '&tenantName=' + this.tenantName + '&hostPoolName=' + this.hostPoolName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token");
    this.http.get(url, {
      headers: headers
    }).subscribe(values => {
      this.generatekeyDetails = values.json();
      if (this.generatekeyDetails) {
        if (this.generatekeyDetails.code == "Invalid Token") {
          sessionStorage.clear();
          this.router.navigate(['/invalidtokenmessage']);
        }
        else if (this.generatekeyDetails.token.length >= 200) {
          this.responseValue = this.generatekeyDetails.token;
          this.expiryDate = this.generatekeyDetails.expirationTime.substring(0, 10);
          this.tenantDashboard = new FormGroup({
            local: new FormControl(this.expiryDate),
            Description: new FormControl(this.responseValue)
          });
        }
        else if (this.generatekeyDetails.Message == "Unauthorized") {
          sessionStorage.clear();
        }
      }
      else {
        this.tenantDashboard = new FormGroup({
          local: new FormControl('', Validators.required),
          Description: new FormControl('', Validators.required),
        });
        this.expiryDate = '';
      }
    },
      /*
       * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
       */
      (error) => {
        //this.showHostCreate = false;
        let errorBody = JSON.parse(error['_body']);
        if (error.status == 404) {
          this._notificationsService.html(
            '<i class="icon icon-fail angular-NotifyFail col-xs-1 no-pad"></i>' +
            '<label class="notify-label col-xs-10 no-pad">' + errorBody.error.message + '</label>' +
            '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
            '<p class="notify-text col-xs-12 no-pad">' + errorBody.error.target + '</p>',
            'content optional one',
            {
              position: ["top", "right"],
              timeOut: 3000,
              showProgressBar: false,
              pauseOnHover: false,
              clickToClose: true,
              maxLength: 10
            }
          )
          AppComponent.GetNotification('icon icon-fail angular-NotifyFail', errorBody.error.message, errorBody.error.target, new Date());
        }
        else {
          this._notificationsService.html(
            '<i class="icon icon-fail angular-NotifyFail col-xs-1 no-pad"></i>' +
            '<label class="notify-label col-xs-10 no-pad">Failed To Generate Registration Key</label>' +
            '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
            '<p class="notify-text col-xs-12 no-pad">Problem with server, Please try again</p>',
            'content optional one',
            {
              position: ["top", "right"],
              timeOut: 3000,
              showProgressBar: false,
              pauseOnHover: false,
              clickToClose: true,
              maxLength: 10
            }
          )
          AppComponent.GetNotification('icon icon-fail angular-NotifyFail', 'Failed To Generate Registration Key', 'Problem with server, Please try again', new Date());
        }
        //this.RefreshHost();
      }
    );
  }

  /*
   * This function is used to close the Create Host Pop Up
   */
  public CancelHostCreate() {
    this.showHostCreate = false;
  }

  /*
   * This function is used to check the AppGroup Access and refresh Hostpool Details, Host List, Appgroup Lsit
   */
  public RefreshHost() {
    this.sessionHostListsSearch = [];
    sessionStorage.removeItem('Hosts');
    this.CheckAppGroupAccess(this.hostPoolName);
    this.GetAllSessionHost();
  }

  public RefreshAppgroups() {
    this.checked = [];
    this.checkedMainAppGroup = false;
    this.state = "down";
    this.appGroupsListSearch = [];
    sessionStorage.removeItem('Appgroups');
    this.CheckAppGroupAccess(this.hostPoolName);
  }

  /*
   * This function is used to make service call to get the selected hostpool details
   * ----------
   * Paramters
   * hostPoolName - Accepts the hostpool name
   * ----------
   */
  public GetHostPoolDetails(hostPoolName: any) {
    let Hostpools = JSON.parse(sessionStorage.getItem('Hostpools'));
    let data = Hostpools.filter(item => item.hostPoolName == hostPoolName);
    this.hostPoolDetails = data[0];
    //this.GetAllAppGroupsList(hostPoolName);
    // this.refreshHostpoolLoading = true;
    // this.hostpoolDetailsErrorFound = false;
    // this.hostpoolDetailsUrl = this._AppService.ApiUrl + '/api/HostPool/GetHostPoolDetails?tenantGroupName=' + this.tenantGroupName + '&tenantName=' + this.tenantName + '&hostPoolName=' + hostPoolName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token");
    // this._AppService.GetData(this.hostpoolDetailsUrl).subscribe(response => {
    //   let HostPoolList = JSON.parse(response['_body']);
    //   if (HostPoolList) {
    //     if (HostPoolList.code == "Invalid Token") {
    //       this.router.navigate(['/invalidtokenmessage']);
    //       sessionStorage.clear();
    //     }
    //   }
    //   if (HostPoolList.message == null) {
    //     this.hostPoolDetails = JSON.parse(response['_body']);
    //     this.hostCount = this.hostPoolDetails.noOfActivehosts;
    //   }
    //   this.GetcurrentNoOfPagesCountAppgroup();
    //   this.GetcurrentNoOfPagesCountHost();
    //   this.GetAllAppGroupsList(hostPoolName);
    // },
    //   /*
    //    * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
    //    */
    //   (error) => {
    //     this.refreshHostpoolLoading = false;
    //     this.hostpoolDetailsErrorFound = true;
    //   }
    // );
  }

  /*
   * This function is used to get the Remote App list of searched data
   * --------------
   * Parameters
   * value - Gets the Search Box Input box values
   * --------------
   */
  public GetSearchByAppName(value: any) {
    let _SearchPipe = new SearchPipe();
    this.appGroupsListSearch = _SearchPipe.transform(value, 'appGroupName', 'friendlyName', 'description', this.appGroupsList);
  }

  public GetSearchByUserSessionList(value: any) {
    let _SearchPipe = new SearchPipe();
    this.userSessionSearchList = _SearchPipe.transform(value, 'sessionId', 'adUserName', 'applicationType', this.userSessions);
  }

  /*
   * This function is used to get the Remote Session host list of searched data
   * --------------
   * Parameters
   * value - Gets the Search Box Input box values
   * --------------
   */
  public GetSearchBySessionHostName(value: any) {
    let _SearchPipe = new SearchPipe();
    this.sessionHostListsSearch = _SearchPipe.transform(value, 'sessionHostName', 'allowNewSession', 'lastHeartBeat', this.sessionHostLists);
  }

  /*
   * This function is used to get the Remote App User list of searched data
   * --------------
   * Parameters
   * value - Gets the Search Box Input box values
   * --------------
   */
  public GetSearchByAppUser(value: any) {
    let _SearchPipe = new SearchPipe();
    this.appUsersListSearch = _SearchPipe.transform(value, 'Name', 'userPrincipalName', 'MaxSessionLimit', this.appUsersList);
  }

  /*
   * This function is used to select the session host from the table
   * --------------
   * Parameters
   * hostIndex - Accepts the Session Host index
   * --------------
   */
  public SessionHostIsChecked(hostIndex: any, event) {
    this.sessionHostchecked[hostIndex] = !this.sessionHostchecked[hostIndex];

    if (event.target != null && event.target.checked != null && event.target.checked != undefined) {
      this.showHostDashBoard = event.target.checked == false ? true : false;// !event.target.checked;

    }
    else if (event.type == "click") {
      this.showHostDashBoard = this.showHostDashBoard == true ? false : true;// !this.showHostDashBoard;
    }
    this.sessionHostCheckedTrue = [];
    for (let i = 0; i < this.sessionHostchecked.length; i++) {
      if (this.sessionHostchecked[i] == true) {
        this.sessionHostCheckedTrue.push(this.sessionHostchecked[i]);
      }
      if (this.sessionHostchecked[i] == false) {
        this.sessionHostCheckedMain = false;
        break;
      }
      else {
        if (this.sessionHostListsSearch.length == this.sessionHostCheckedTrue.length) {
          this.sessionHostCheckedMain = true;
          this.editHostDisabled = true;
          this.drainHostDisabled = true;
          this.deleteHostDisabled = false;
          this.restartHostDisabled = true;
        }
      }
      if (this.sessionHostCheckedTrue.length == 1) {
        this.editHostDisabled = false;
        this.drainHostDisabled = false;
        this.deleteHostDisabled = false;
        this.restartHostDisabled = sessionStorage.getItem("roleDefinitionName") == "RDS Owner" ? false : true;
        this.state = "up";

      }
      else if (this.sessionHostCheckedTrue.length > 1) {
        this.editHostDisabled = true;
        this.drainHostDisabled = true;
        this.deleteHostDisabled = false;
        this.restartHostDisabled = true;
      }
      else {
        this.editHostDisabled = true;
        this.drainHostDisabled = true;
        this.deleteHostDisabled = true;
        this.restartHostDisabled = true;
      }
    }

  }



  public ChangeDrainMode() {
    // if (data.allowNewSession === 'Yes') {
    //   data.allowNewSession = true;
    // }
    // else {
    //   data.allowNewSession = false;
    // }
    let updateArray = {
      "tenantName": this.hostDetails.tenantName,
      "hostPoolName": this.hostDetails.hostPoolName,
      "sessionHostName": this.hostDetails.sessionHostName,
      "allowNewSession": false, //this.HostAllowNewSession,
      "refresh_token": sessionStorage.getItem("Refresh_Token"),
      "tenantGroupName": this.hostDetails.tenantGroupName,
    };
    this.updateAppGroupLoading = true;
    this.ChangeDrainModeUrl = this._AppService.ApiUrl + '/api/SessionHost/ChangeDrainMode';
    this._AppService.ChangeDrainMode(this.ChangeDrainModeUrl, updateArray).subscribe(response => {
      this.updateAppGroupLoading = false;
      var responseData = JSON.parse(response['_body']);
      if (responseData.message == "Invalid Token") {
        sessionStorage.clear();
        this.router.navigate(['/invalidtokenmessage']);
      }
      /* If response data is success then it enters into if and this block of code will execute to show the 'Host Updated Successfully' notification */
      if (responseData.isSuccess === true) {
        this._notificationsService.html(
          '<i class="icon icon-check angular-Notify col-xs-1 no-pad"></i>' +
          '<label class="notify-label col-xs-10 no-pad">Drain Mode Changed Successfully</label>' +
          '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
          '<p class="notify-text col-xs-12 no-pad">' + responseData.message + '</p>',
          'content optional one',
          {
            position: ["top", "right"],
            timeOut: 3000,
            showProgressBar: false,
            pauseOnHover: false,
            clickToClose: true,
            maxLength: 10
          }
        )
        AppComponent.GetNotification('icon icon-check angular-Notify', 'Drain Mode Changed Successfully', responseData.message, new Date());
        $("#editHostModal .icon-close").trigger('click');
        this.RefreshHost();
      }
      /* If response data is success then it enters into else and this block of code will execute to show the 'Failed To Update Host' notification */
      else {
        this._notificationsService.html(
          '<i class="icon icon-fail angular-NotifyFail col-xs-1 no-pad"></i>' +
          '<label class="notify-label col-xs-10 no-pad">Failed To Change Drain Mode</label>' +
          '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
          '<p class="notify-text col-xs-12 no-pad">' + responseData.message + '</p>',
          'content optional one',
          {
            position: ["top", "right"],
            timeOut: 3000,
            showProgressBar: false,
            pauseOnHover: false,
            clickToClose: true,
            maxLength: 10
          }
        )
        AppComponent.GetNotification('icon icon-fail angular-NotifyFail', 'Failed To Change Drain Mode', responseData.message, new Date());
        this.RefreshHost();
      }
    },
      /*
       * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
       */
      (error) => {
        this._notificationsService.html(
          '<i class="icon icon-fail angular-NotifyFail col-xs-1 no-pad"></i>' +
          '<label class="notify-label col-xs-10 no-pad">Failed To Change Drain Mode</label>' +
          '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
          '<p class="notify-text col-xs-12 no-pad">Problem with server, Please try again</p>',
          'content optional one',
          {
            position: ["top", "right"],
            timeOut: 3000,
            showProgressBar: false,
            pauseOnHover: false,
            clickToClose: true,
            maxLength: 10
          }
        )
        AppComponent.GetNotification('icon icon-fail angular-NotifyFail', 'Failed To Change Drain Mode', 'Problem with server, Please try again', new Date());
      }
    );
    this.sessionHostCheckedMain = false;
    this.sessionHostchecked = [];
  }


  /*
   * This function is used to select all the session host from the table
   * --------------
   * Parameters
   * event - Accepts Event
   * --------------
   */
  public SessionHostCheckAll(event: any) {
    this.showHostDashBoard = false;
    this.sessionHostCheckedMain = !this.sessionHostCheckedMain;
    var index;
    this.selectedHostRows=[];
    for (let i = 0; i < this.sessionHostListsSearch.length; i++) {
      if (event.target.checked) {
        this.sessionHostchecked[i] = true;
      }
      else {
        this.sessionHostchecked[i] = false;
      }
    }
    this.sessionHostCheckedAllTrue = [];
    for (let j = 0; j < this.sessionHostchecked.length; j++) {
      if (this.sessionHostchecked[j] == true) {
        this.sessionHostCheckedAllTrue.push(this.sessionHostchecked[j]);
        this.selectedHostRows.push(j);
        index = j;
      }
    }
    if (this.sessionHostCheckedAllTrue.length == 1) {
      this.editHostDisabled = false;
      this.deleteHostDisabled = false;
      this.drainHostDisabled = false;
      this.state = "up";
      this.showHostDashBoard = true;
      this.restartHostDisabled = sessionStorage.getItem("roleDefinitionName") == "RDS Owner" ? false : true;
      this.hostFormEdit = new FormGroup({
        sessionHostName: new FormControl(this.sessionHostListsSearch[index].sessionHostName),
        allowNewSession: new FormControl(this.sessionHostListsSearch[index].allowNewSession),
      });
      this.hostDeleteData = this.sessionHostListsSearch[index].sessionHostName;
    }
    else if (this.sessionHostCheckedAllTrue.length > 1) {
      this.editHostDisabled = true;
      this.drainHostDisabled = true;
      this.restartHostDisabled = true;
      this.deleteHostDisabled = false;
      this.hostDeleteData = this.sessionHostCheckedAllTrue.length;
    }
    else {
      this.editHostDisabled = true;
      this.deleteHostDisabled = true;
      this.drainHostDisabled = true;
      this.restartHostDisabled = true;
    }
  }

  /*
   * This function is used to get session host from service and load into data
   */
  /* This function is used to  divide the number of pages based on Tenants Count */
  public GetcurrentNoOfPagesCountHost() {
    let currentNoOfPagesCountCount = Math.floor(this.hostCount / this.HostpageSize);
    let remaingCount = this.hostCount % this.HostpageSize;
    if (remaingCount > 0) {
      this.currentNoOfPagesHostCount = currentNoOfPagesCountCount + 1;
    }
    else {
      this.currentNoOfPagesHostCount = currentNoOfPagesCountCount;
    }
    this.curentHostIndex = 0;
  }

  public Hostcounter(i: number) {
    return new Array(i);
  }
  // public previousPageHost() {
  //   this.sessionHostCheckedMain = false;
  //   this.sessionHostchecked = [];
  //   this.hostListErrorFound = false;
  //   this.HostlastEntry = this.sessionHostLists[0].sessionHostName;
  //   this.curentHostIndex = this.curentHostIndex - 1;
  //   this.getAllSessionHostUrl = this._AppService.ApiUrl + '/api/SessionHost/GetSessionhostList?tenantGroupName=' + this.tenantGroupName + '&tenantName=' + this.tenantName + '&hostPoolName=' + this.hostPoolName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token") + '&pageSize=' + this.HostpageSize + '&sortField=SessionHostName&isDescending=true&initialSkip=' + this.hostinitialSkip + '&lastEntry=' + this.HostlastEntry;
  //   this._AppService.GetData(this.getAllSessionHostUrl).subscribe(response => {
  //     let HostList = JSON.parse(response['_body']);
  //     this.sessionHostLists = HostList.reverse();
  //     this.HostpreviousPageNo = this.HostCurrentPageNo;
  //     this.HostCurrentPageNo = this.HostCurrentPageNo - 1;

  //     /* This Block of code is used to Exchange the allowNewSession value 'true' or 'false' to 'Yes' or 'No' */
  //     /*Exchange Block starting*/
  //     for (let j in this.sessionHostLists) {
  //       if (this.sessionHostLists[j].allowNewSession === true) {
  //         this.sessionHostLists[j].allowNewSession = 'Yes';
  //       }
  //       else {
  //         this.sessionHostLists[j].allowNewSession = 'No';
  //       }
  //     }
  //     /*Exchange Block Ending*/

  //     if (this.sessionHostLists) {
  //       if (this.sessionHostLists.code == "Invalid Token") {
  //         sessionStorage.clear();
  //         this.router.navigate(['/invalidtokenmessage']);
  //       }
  //     }
  //     if (this.sessionHostLists.length == 0) {
  //       this.showHostEmpty = true;
  //       this.showHostpoolTab = true;
  //     } else {
  //       this.showHostEmpty = false;
  //       this.showHostpoolTab = false;
  //     }
  //     this.sessionHostListsSearch = JSON.parse(response['_body']);

  //     /* This Block of code is used to Exchange the allowNewSession value 'true' or 'false' to 'Yes' or 'No' */
  //     /*Exchange Block starting*/
  //     for (let i in this.sessionHostListsSearch) {
  //       if (this.sessionHostListsSearch[i].allowNewSession === true) {
  //         this.sessionHostListsSearch[i].allowNewSession = 'Yes';
  //       }
  //       else {
  //         this.sessionHostListsSearch[i].allowNewSession = 'No';
  //       }
  //     }
  //     /*Exchange Block Ending*/

  //     if (this.sessionHostListsSearch.length == 0) {
  //       this.edited = true;
  //     }
  //     else {
  //       if (this.sessionHostListsSearch[0].Message == null) {
  //         this.edited = false;
  //       }
  //     }
  //   },
  //     /*
  //      * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
  //      */
  //     (error) => {
  //       this.hostListErrorFound = true;
  //       this.refreshHostpoolLoading = false;
  //     }
  //   );
  //   this.editHostDisabled = true;
  //   this.deleteHostDisabled = true;
  //   this.drainHostDisabled = true;
  //   this.restartHostDisabled = true;
  // }

  // public CurrentPageHost(index) {
  //   this.HostpreviousPageNo = this.HostCurrentPageNo;
  //   this.HostCurrentPageNo = index + 1;
  //   this.curentHostIndex = index;
  //   let diff = this.HostCurrentPageNo - this.HostpreviousPageNo;
  //   // to get intialskip
  //   if (this.HostCurrentPageNo >= this.HostpreviousPageNo) {
  //     this.isDescending = false;
  //     this.HostpageSize = diff * this.HostpageSize; //this.sessionHostLists[0].sessionHostName
  //     this.HostlastEntry = this.sessionHostLists[this.sessionHostLists.length - 1].sessionHostName;
  //   } else {
  //     this.isDescending = true;
  //     this.HostlastEntry = this.sessionHostLists[0].appGroupName;
  //   }
  //   this.sessionHostCheckedMain = false;
  //   this.sessionHostchecked = [];
  //   this.hostListErrorFound = false;
  //   // '/api/AppGroup/GetAppGroupsList?tenantName=' + this.tenantName + '&hostPoolName=' + this.hostPoolName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token") + ' &pageSize=' + this.pageSize + '&sortField=AppGroupName&isDescending=' + this.isDescending + '&initialSkip=' + this.initialSkip + '&lastEntry=' + this.lastEntry;
  //   this.getAllSessionHostUrl = this._AppService.ApiUrl + '/api/SessionHost/GetSessionhostList?tenantGroupName=' + this.tenantGroupName + '&tenantName=' + this.tenantName + '&hostPoolName=' + this.hostPoolName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token") + '&pageSize=' + this.HostpageSize + '&sortField=SessionHostName&isDescending=' + this.isDescending + '&initialSkip=' + this.hostinitialSkip + '&lastEntry=' + this.HostlastEntry;
  //   this._AppService.GetData(this.getAllSessionHostUrl).subscribe(response => {
  //     this.sessionHostLists = JSON.parse(response['_body']);
  //     /* This Block of code is used to Exchange the allowNewSession value 'true' or 'false' to 'Yes' or 'No' */
  //     /*Exchange Block starting*/
  //     for (let j in this.sessionHostLists) {
  //       if (this.sessionHostLists[j].allowNewSession === true) {
  //         this.sessionHostLists[j].allowNewSession = 'Yes';
  //       }
  //       else {
  //         this.sessionHostLists[j].allowNewSession = 'No';
  //       }
  //     }
  //     /*Exchange Block Ending*/

  //     if (this.sessionHostLists) {
  //       if (this.sessionHostLists.code == "Invalid Token") {
  //         sessionStorage.clear();
  //         this.router.navigate(['/invalidtokenmessage']);
  //       }
  //     }
  //     if (this.sessionHostLists.length == 0) {
  //       this.showHostEmpty = true;
  //       this.showHostpoolTab = true;
  //     } else {
  //       this.showHostEmpty = false;
  //       this.showHostpoolTab = false;
  //     }
  //     this.sessionHostListsSearch = JSON.parse(response['_body']);

  //     /* This Block of code is used to Exchange the allowNewSession value 'true' or 'false' to 'Yes' or 'No' */
  //     /*Exchange Block starting*/
  //     for (let i in this.sessionHostListsSearch) {
  //       if (this.sessionHostListsSearch[i].allowNewSession === true) {
  //         this.sessionHostListsSearch[i].allowNewSession = 'Yes';
  //       }
  //       else {
  //         this.sessionHostListsSearch[i].allowNewSession = 'No';
  //       }
  //     }
  //     /*Exchange Block Ending*/

  //     if (this.sessionHostListsSearch.length == 0) {
  //       this.edited = true;
  //     }
  //     else {
  //       if (this.sessionHostListsSearch[0].Message == null) {
  //         this.edited = false;
  //       }
  //     }
  //   },
  //     /*
  //      * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
  //      */
  //     (error) => {
  //       this.hostListErrorFound = true;
  //       this.refreshHostpoolLoading = false;
  //     }
  //   );
  //   this.editHostDisabled = true;
  //   this.deleteHostDisabled = true;
  //   this.drainHostDisabled = true;
  //   this.restartHostDisabled = true;
  // }

  // public NextPageHost() {
  //   this.HostlastEntry = this.sessionHostLists[this.sessionHostLists.length - 1].sessionHostName;
  //   this.curentHostIndex = this.curentHostIndex + 1;
  //   this.sessionHostCheckedMain = false;
  //   this.sessionHostchecked = [];
  //   this.hostListErrorFound = false;
  //   this.getAllSessionHostUrl = this._AppService.ApiUrl + '/api/SessionHost/GetSessionhostList?tenantGroupName=' + this.tenantGroupName + '&tenantName=' + this.tenantName + '&hostPoolName=' + this.hostPoolName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token") + '&pageSize=' + this.HostpageSize + '&sortField=SessionHostName&isDescending=false&initialSkip=' + this.hostinitialSkip + '&lastEntry=' + this.HostlastEntry;
  //   this._AppService.GetData(this.getAllSessionHostUrl).subscribe(response => {
  //     this.sessionHostLists = JSON.parse(response['_body']);
  //     this.HostpreviousPageNo = this.HostCurrentPageNo;
  //     this.HostCurrentPageNo = this.HostCurrentPageNo + 1;
  //     /* This Block of code is used to Exchange the allowNewSession value 'true' or 'false' to 'Yes' or 'No' */
  //     /*Exchange Block starting*/
  //     for (let j in this.sessionHostLists) {
  //       if (this.sessionHostLists[j].allowNewSession === true) {
  //         this.sessionHostLists[j].allowNewSession = 'Yes';
  //       }
  //       else {
  //         this.sessionHostLists[j].allowNewSession = 'No';
  //       }
  //     }
  //     /*Exchange Block Ending*/

  //     if (this.sessionHostLists) {
  //       if (this.sessionHostLists.code == "Invalid Token") {
  //         sessionStorage.clear();
  //         this.router.navigate(['/invalidtokenmessage']);
  //       }
  //     }
  //     if (this.sessionHostLists.length == 0) {
  //       this.showHostEmpty = true;
  //       this.showHostpoolTab = true;
  //     } else {
  //       this.showHostEmpty = false;
  //       this.showHostpoolTab = false;
  //     }
  //     this.sessionHostListsSearch = JSON.parse(response['_body']);

  //     /* This Block of code is used to Exchange the allowNewSession value 'true' or 'false' to 'Yes' or 'No' */
  //     /*Exchange Block starting*/
  //     for (let i in this.sessionHostListsSearch) {
  //       if (this.sessionHostListsSearch[i].allowNewSession === true) {
  //         this.sessionHostListsSearch[i].allowNewSession = 'Yes';
  //       }
  //       else {
  //         this.sessionHostListsSearch[i].allowNewSession = 'No';
  //       }
  //     }
  //     /*Exchange Block Ending*/

  //     if (this.sessionHostListsSearch.length == 0) {
  //       this.edited = true;
  //     }
  //     else {
  //       if (this.sessionHostListsSearch[0].Message == null) {
  //         this.edited = false;
  //       }
  //     }
  //   },
  //     /*
  //      * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
  //      */
  //     (error) => {
  //       this.hostListErrorFound = true;
  //       this.refreshHostpoolLoading = false;
  //     }
  //   );
  //   this.editHostDisabled = true;
  //   this.deleteHostDisabled = true;
  //   this.drainHostDisabled = true;
  //   this.restartHostDisabled = true;
  // }
  //This.hostsCount=this.hostPoolDetails.noOfActivehosts
  public GetAllSessionHost() {
    this.refreshHostpoolLoading = true;
    this.sessionHostCheckedMain = false;
    this.sessionHostchecked = [];
    this.hostListErrorFound = false;
    let hosts = JSON.parse(sessionStorage.getItem('Hosts'));
    if (sessionStorage.getItem('Hosts') && hosts.length != 0 && hosts != null && sessionStorage.getItem('SelectedHostpool') == this.hostPoolName) {
      this.gettingHosts();
    }
    else {
      sessionStorage.setItem('SelectedHostpool', this.hostPoolName);
      // this.getAllSessionHostUrl = this._AppService.ApiUrl + '/api/SessionHost/GetSessionhostList?tenantGroupName=' + this.tenantGroupName + '&tenantName=' + this.tenantName + '&hostPoolName=' + this.hostPoolName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token") + '&pageSize=' + this.HostpageSize + '&sortField=SessionHostName&isDescending=false&initialSkip=' + this.hostinitialSkip + '&lastEntry=%22%20%22';
      this.getAllSessionHostUrl = this._AppService.ApiUrl + '/api/SessionHost/GetSessionhostList?tenantGroupName=' + this.tenantGroupName + '&tenantName=' + this.tenantName + '&hostPoolName=' + this.hostPoolName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token") + '&subscriptionId=' + sessionStorage.getItem("SubscriptionId");
      this._AppService.GetData(this.getAllSessionHostUrl).subscribe(response => {
        this.refreshHostpoolLoading = false;
        if (response.status == 429) {
          this.error = true;
          this.errorMessage = response.statusText;
        }
        else {
          this.error = false;
          this.sessionHostLists = JSON.parse(response['_body']);
          sessionStorage.setItem('Hosts', JSON.stringify(this.sessionHostLists));
          this.gettingHosts();
        }

      },
        /*
         * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
         */
        (error) => {
          this.error = true;
          let errorBody = JSON.parse(error['_body']);

          if (errorBody.error.code == "403") {
            this.errorMessage = "Access Denied! You are not authorized user to view host details.";
            this.showHostEmpty = true;
            this.hostListErrorFound = false;
          }
          else {
            this.errorMessage = errorBody.error.target;
            this.showHostEmpty = false;
            this.hostListErrorFound = true;
          }
          this.refreshHostpoolLoading = false;
        }
      );
    }
    this.editHostDisabled = true;
    this.deleteHostDisabled = true;
    this.drainHostDisabled = true;
    this.restartHostDisabled = true;
    this.showHostDashBoard = false;
  }

  gettingHosts() {
    this.sessionHostLists = JSON.parse(sessionStorage.getItem('Hosts'));

    if (this.sessionHostLists != null && this.sessionHostLists.length > 0) {
      /* This Block of code is used to Exchange the allowNewSession value 'true' or 'false' to 'Yes' or 'No' */
      /*Exchange Block starting*/
      for (let j in this.sessionHostLists) {
        if (this.sessionHostLists[j].allowNewSession === true) {
          this.sessionHostLists[j].allowNewSession = 'Yes';
        }
        else {
          this.sessionHostLists[j].allowNewSession = 'No';
        }
      }

      /*Exchange Block Ending*/

      if (this.sessionHostLists) {
        if (this.sessionHostLists.code == "Invalid Token") {
          sessionStorage.clear();
          this.router.navigate(['/invalidtokenmessage']);
        }
      }
      if (this.sessionHostLists.length == 0) {
        this.showHostEmpty = true;
        this.showHostpoolTab = true;
      } else {
        this.showHostEmpty = false;
        this.showHostpoolTab = false;
      }
      this.sessionHostListsSearch = JSON.parse(sessionStorage.getItem('Hosts'));

      /* This Block of code is used to Exchange the allowNewSession value 'true' or 'false' to 'Yes' or 'No' */
      /*Exchange Block starting*/
      for (let i in this.sessionHostListsSearch) {
        if (this.sessionHostListsSearch[i].allowNewSession === true) {
          this.sessionHostListsSearch[i].allowNewSession = 'Yes';
        }
        else {
          this.sessionHostListsSearch[i].allowNewSession = 'No';
        }
      }
      /*Exchange Block Ending*/

      if (this.sessionHostListsSearch.length == 0) {
        this.edited = true;
      }
      else {
        if (this.sessionHostListsSearch[0].Message == null) {
          this.edited = false;
        }
      }
    }
    else{
      this.showHostEmpty=true;
    }
    this.refreshHostpoolLoading = false;

  }

  /*
   * This function is used to delete the selected session host
   */
  public DeleteHost() {
    this.refreshHostpoolLoading = true;
    for (let i = 0; i < this.selectedHostRows.length; i++) { 
      let index = this.selectedHostRows[i];
      this.hostDeleteUrl = this._AppService.ApiUrl + '/api/SessionHost/DeleteSessionHost?tenantGroup=' + this.tenantGroupName + '&tenantName=' + this.tenantName + '&hostPoolName=' + this.hostPoolName + '&sessionHostName=' + this.sessionHostListsSearch[index].sessionHostName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token");
      this._AppService.DeleteHostService(this.hostDeleteUrl).subscribe(response => {
        this.refreshHostpoolLoading = false;
        var responseData = JSON.parse(response['_body']);
        if (responseData.message == "Invalid Token") {
          sessionStorage.clear();
          this.router.navigate(['/invalidtokenmessage']);
        }
        /* If response data is success then it enters into if and this block of code will execute to show the 'Host Deleted Successfully' notification */
        if (responseData.isSuccess === true) {
          this._notificationsService.html(
            '<i class="icon icon-check angular-Notify col-xs-1 no-pad"></i>' +
            '<label class="notify-label col-xs-10 no-pad">Host Deleted Successfully</label>' +
            '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
            '<p class="notify-text col-xs-12 no-pad">' + responseData.message + '</p>',
            'content optional one',
            {
              position: ["top", "right"],
              timeOut: 3000,
              showProgressBar: false,
              pauseOnHover: false,
              clickToClose: true,
              maxLength: 10
            }
          )
          AppComponent.GetNotification('icon icon-check angular-Notify', 'Host Deleted Successfully', responseData.message, new Date());
        }
        /* If response data is success then it enters into else and this block of code will execute to show the 'Failed To Delete Host' notification */
        else {
          this._notificationsService.html(
            '<i class="icon icon-fail angular-NotifyFail col-xs-1 no-pad"></i>' +
            '<label class="notify-label col-xs-10 no-pad">Failed To Delete Host</label>' +
            '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
            '<p class="notify-text col-xs-12 no-pad">' + responseData.message + '</p>',
            'content optional one',
            {
              position: ["top", "right"],
              timeOut: 3000,
              showProgressBar: false,
              pauseOnHover: false,
              clickToClose: true,
              maxLength: 10
            }
          )
          AppComponent.GetNotification('icon icon-fail angular-NotifyFail', 'Failed To Delete Host', responseData.message, new Date());
        }
        this.RefreshHost();
      },
        /*
         * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
         */
        (error) => {
          this._notificationsService.html(
            '<i class="icon icon-fail angular-NotifyFail col-xs-1 no-pad"></i>' +
            '<label class="notify-label col-xs-10 no-pad">Failed To Delete Host</label>' +
            '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
            '<p class="notify-text col-xs-12 no-pad">Problem with server, Please try again</p>',
            'content optional one',
            {
              position: ["top", "right"],
              timeOut: 3000,
              showProgressBar: false,
              pauseOnHover: false,
              clickToClose: true,
              maxLength: 10
            }
          )
          AppComponent.GetNotification('icon icon-fail angular-NotifyFail', 'Failed To Delete Host', 'Problem with server, Please try again', new Date());
        }
      );
    }
    this.RefreshHost();

  }

  /*
   * This function is used to select the session host from the table
   * --------------
   * Parameters
   * hostIndex - Accepts Host Index
   * hostName - Accepts Host Name
   * --------------
   */
  public HostClicked(hostIndex: any, hostName: any, event: Event) {
    this.SessionHostIsChecked(hostIndex, event);
    this.sessionHostName = hostName;
    this.sessionHostCheckedTrue = [];
    this.selectedHostRows=[];
    var index = hostIndex;
    for (var i = 0; i < this.sessionHostchecked.length; i++) {
      if (this.sessionHostchecked[i] == true) {
        this.sessionHostCheckedTrue.push(this.sessionHostchecked[i]);
        this.selectedHostRows.push(i);
        index = i;
      }
    }
    if (this.sessionHostCheckedTrue.length == 1) {

      this.editHostDisabled = false;
      this.deleteHostDisabled = false;
      this.drainHostDisabled = false;
      this.restartHostDisabled = sessionStorage.getItem("roleDefinitionName") == "RDS Owner" ? false : true;
      this.hostDeleteData = this.sessionHostListsSearch[index].sessionHostName;
      this.hostDetails = this.sessionHostListsSearch[index];
      this.HostAllowNewSession = this.hostDetails.allowNewSession == "Yes" ? false : true;
      this.state = "up";
      this.selectedHostName = this.sessionHostListsSearch[index].sessionHostName;
      this.showHostDashBoard = true;
      // make service call to get user sessions
      if (this.showHostDashBoard == true) {
        this.GetUserSessions();

      }
    } else if (this.sessionHostCheckedTrue.length > 1) {

      this.editHostDisabled = true;
      this.deleteHostDisabled = false;
      this.drainHostDisabled = true;
      this.restartHostDisabled = true;
      this.hostDeleteData = this.sessionHostCheckedTrue.length;
      this.state = "down";
    } else {
      this.editHostDisabled = true;
      this.deleteHostDisabled = true;
      this.drainHostDisabled = true;
      this.restartHostDisabled = true;
    }
    this.hostFormEdit = new FormGroup({
      sessionHostName: new FormControl(this.sessionHostListsSearch[hostIndex].sessionHostName),
      allowNewSession: new FormControl(this.sessionHostListsSearch[hostIndex].allowNewSession),
    });
  }

  /*
   * This function is used to update/edit the selected session host
   * --------------
   * Parameters
   * data - Accepts Host Edit Form Values
   * --------------
   */
  public UpdateHost(data: any) {
    if (data.allowNewSession === 'Yes') {
      data.allowNewSession = true;
    }
    else {
      data.allowNewSession = false;
    }
    let updateArray = {
      "tenantName": this.tenantName,
      "hostPoolName": this.hostPoolName,
      "sessionHostName": data.sessionHostName,
      "allowNewSession": data.allowNewSession,
      "refresh_token": sessionStorage.getItem("Refresh_Token"),
      "tenantGroupName": this.tenantGroupName,
    };
    this.updateAppGroupLoading = true;
    this.updateHostUrl = this._AppService.ApiUrl + '/api/SessionHost/Put';
    this._AppService.UpdateHost(this.updateHostUrl, updateArray).subscribe(response => {
      this.updateAppGroupLoading = false;
      var responseData = JSON.parse(response['_body']);
      if (responseData.message == "Invalid Token") {
        sessionStorage.clear();
        this.router.navigate(['/invalidtokenmessage']);
      }
      /* If response data is success then it enters into if and this block of code will execute to show the 'Host Updated Successfully' notification */
      if (responseData.isSuccess === true) {
        this._notificationsService.html(
          '<i class="icon icon-check angular-Notify col-xs-1 no-pad"></i>' +
          '<label class="notify-label col-xs-10 no-pad">Host Updated Successfully</label>' +
          '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
          '<p class="notify-text col-xs-12 no-pad">' + responseData.message + '</p>',
          'content optional one',
          {
            position: ["top", "right"],
            timeOut: 3000,
            showProgressBar: false,
            pauseOnHover: false,
            clickToClose: true,
            maxLength: 10
          }
        )
        AppComponent.GetNotification('icon icon-check angular-Notify', 'Host Updated Successfully', responseData.message, new Date());
        $("#editHostModal .icon-close").trigger('click');
        this.RefreshHost();
      }
      /* If response data is success then it enters into else and this block of code will execute to show the 'Failed To Update Host' notification */
      else {
        this._notificationsService.html(
          '<i class="icon icon-fail angular-NotifyFail col-xs-1 no-pad"></i>' +
          '<label class="notify-label col-xs-10 no-pad">Failed To Update Host</label>' +
          '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
          '<p class="notify-text col-xs-12 no-pad">' + responseData.message + '</p>',
          'content optional one',
          {
            position: ["top", "right"],
            timeOut: 3000,
            showProgressBar: false,
            pauseOnHover: false,
            clickToClose: true,
            maxLength: 10
          }
        )
        AppComponent.GetNotification('icon icon-fail angular-NotifyFail', 'Failed To Update Host', responseData.message, new Date());
        this.RefreshHost();
      }
    },
      /*
       * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
       */
      (error) => {
        this._notificationsService.html(
          '<i class="icon icon-fail angular-NotifyFail col-xs-1 no-pad"></i>' +
          '<label class="notify-label col-xs-10 no-pad">Failed To Update Host</label>' +
          '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
          '<p class="notify-text col-xs-12 no-pad">Problem with server, Please try again</p>',
          'content optional one',
          {
            position: ["top", "right"],
            timeOut: 3000,
            showProgressBar: false,
            pauseOnHover: false,
            clickToClose: true,
            maxLength: 10
          }
        )
        AppComponent.GetNotification('icon icon-fail angular-NotifyFail', 'Failed To Update Host', 'Problem with server, Please try again', new Date());
      }
    );
    this.sessionHostCheckedMain = false;
    this.sessionHostchecked = [];
  }

  /*
   * This function is used to call the notification of copied the generated key to clipboard
   */
  public GenarateKey() {
    this._notificationsService.html(
      '<i class="icon icon-check angular-Notify col-xs-1 no-pad"></i>' +
      '<label class="notify-label col-xs-10 no-pad">Registration Key Copied Successfully</label>' +
      '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
      '<p class="notify-text col-xs-12 no-pad">Registration key Successfully copied to clipboard</p>',
      'content optional one',
      {
        position: ["top", "right"],
        timeOut: 3000,
        showProgressBar: false,
        pauseOnHover: false,
        clickToClose: true,
        maxLength: 10
      }
    )
    AppComponent.GetNotification('icon icon-check angular-Notify', 'Registration Key Copied Successfully', 'Registration key successfully copied to clipboard', new Date());
  }

  /*
   * This function is used to save or download the file contains Key
   * ----------
   * parametes
   * data - Accepts the Key Value
   * ----------
   */
  public SaveFile(data) {
    var fileType = 'text/plain;charset=utf-8';
    var blob = new Blob([data.Description], {
      type: fileType
    });
    FileSaver.saveAs(blob, 'RegistrationKey');
  }

  /*
   * This function is used to make service call to Generate Key for Adding/ Create Host
   * ----------
   * parametes
   * generateKeyValueData - Accepts the Expiry Data
   * ----------
   */
  public GenerateKeyValue(generateKeyValueData: any) {
    this.refreshHostpoolLoading = true;
    let date = new Date(generateKeyValueData.local.formatted);
    var expirationTime = date.toISOString();
    var GenerateKeyValueArray = {
      expirationTime: expirationTime,
      tenantGroupName: this.tenantGroupName,
      tenantName: this.tenantName,
      hostPoolName: this.hostPoolName,
      refresh_token: sessionStorage.getItem("Refresh_Token"),
    };
    this.generatekeyURL = this._AppService.ApiUrl + '/api/RegistrationInfo/Post';
    this._AppService.GenerateKeyValue(this.generatekeyURL, GenerateKeyValueArray).subscribe(response => {
      this.generatekeyDetails = response.json();
      if (response['_body'] == '"RegistrationInfo is created Successfully."') {
        this.responseValue = this.generatekeyDetails.Key;
        this.responseMessage = "";
      } else {
        this.responseMessage = this.generatekeyDetails.Message;
      }
      this.refreshHostpoolLoading = false;
      var responseData = JSON.parse(response['_body']);
      if (responseData.message == "Invalid Token") {
        sessionStorage.clear();
        this.router.navigate(['/invalidtokenmessage']);
      }
      /* If response data is success then it enters into if and this block of code will execute to show the 'Registration Key Generated Successfully' notification */
      if (responseData.isSuccess === true) {
        this._notificationsService.html(
          '<i class="icon icon-check angular-Notify col-xs-1 no-pad"></i>' +
          '<label class="notify-label col-xs-10 no-pad">Registration Key Generated Successfully</label>' +
          '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
          '<p class="notify-text col-xs-12 no-pad">' + responseData.message + '</p>',
          'content optional one',
          {
            position: ["top", "right"],
            timeOut: 3000,
            showProgressBar: false,
            pauseOnHover: false,
            clickToClose: true,
            maxLength: 10
          }
        )
        AppComponent.GetNotification('icon icon-check angular-Notify', 'Registration Key Generated Successfully', responseData.message, new Date());
      }
      /* If response data is success then it enters into else and this block of code will execute to show the 'Failed To Generate Registration Key' notification */
      else {
        this._notificationsService.html(
          '<i class="icon icon-fail angular-NotifyFail col-xs-1 no-pad"></i>' +
          '<label class="notify-label col-xs-10 no-pad">Failed To Generate Registration Key</label>' +
          '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
          '<p class="notify-text col-xs-12 no-pad">' + responseData.message + '</p>',
          'content optional one',
          {
            position: ["top", "right"],
            timeOut: 3000,
            showProgressBar: false,
            pauseOnHover: false,
            clickToClose: true,
            maxLength: 10
          }
        )
        AppComponent.GetNotification('icon icon-fail angular-NotifyFail', 'Failed To Generate Registration Key', responseData.message, new Date());
      }
      this.AddHostKeyGenerate();
    },
      /*
       * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
       */
      (error) => {
        this._notificationsService.html(
          '<i class="icon icon-fail angular-NotifyFail col-xs-1 no-pad"></i>' +
          '<label class="notify-label col-xs-10 no-pad">Failed To Generate Registration Key</label>' +
          '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
          '<p class="notify-text col-xs-12 no-pad">Problem with server, Please try again</p>',
          'content optional one',
          {
            position: ["top", "right"],
            timeOut: 3000,
            showProgressBar: false,
            pauseOnHover: false,
            clickToClose: true,
            maxLength: 10
          }
        )
        AppComponent.GetNotification('icon icon-fail angular-NotifyFail', 'Failed To Generate Registration Key', 'Problem with server, Please try again', new Date());
      }
    );
  }

  /*
   * This function is used to make service call to Re-Generate Key for Adding/ Create Host
   * ----------
   * parametes
   * reGenerateKeyValueData - Accepts the Generated Key
   * ----------
   */
  public ReGenerateKeyValue(reGenerateKeyValueData: any) {
    if (this.tenantDashboard.local == "" || this.tenantDashboard.local == undefined || this.tenantDashboard.local == null) {
      this.isDate = true;
    }
    else {
      this.isDate = false;
      this.refreshHostpoolLoading = true;
      this.regeneratekeyURL = this._AppService.ApiUrl + '/api/RegistrationInfo/Delete?tenantGroupName=' + this.tenantGroupName + '&tenantName=' + this.tenantName + '&hostPoolName=' + this.hostPoolName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token");
      this._AppService.DeleteGeneratedHostKey(this.regeneratekeyURL).subscribe(response => {
        this.regeneratekeyDetails = response.json();
        /* If response data is success then it enters into if and this block of code will execute to show the 'Registration key Regenerated successfully' notification */
        if (this.regeneratekeyDetails.isSuccess == true) {
          this.GenerateKeyValue(reGenerateKeyValueData);
        }
        /* If response data is success then it enters into else and this block of code will execute to show the 'Failed To Re-generate Key' notification */
        else {
          this.refreshHostpoolLoading = false;
          this._notificationsService.html(
            '<i class="icon icon-fail angular-NotifyFail col-xs-1 no-pad"></i>' +
            '<label class="notify-label col-xs-10 no-pad">Failed To Re-generate Key</label>' +
            '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
            '<p class="notify-text col-xs-12 no-pad">' + this.regeneratekeyDetails.message + '</p>',
            'content optional one',
            {
              position: ["top", "right"],
              timeOut: 3000,
              showProgressBar: false,
              pauseOnHover: false,
              clickToClose: true,
              maxLength: 10
            }
          )
          AppComponent.GetNotification('icon icon-fail angular-NotifyFail', 'Failed To Re-generate Key', this.regeneratekeyDetails.message, new Date());
          this.showHostCreate = false;
          this.refreshHostpoolLoading = false;
        }
      },
        /*
         * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
         */
        (error) => {
          this.refreshHostpoolLoading = false;
          this._notificationsService.html(
            '<i class="icon icon-fail angular-NotifyFail col-xs-1 no-pad"></i>' +
            '<label class="notify-label col-xs-10 no-pad">Failed To Re-generate Key</label>' +
            '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
            '<p class="notify-text col-xs-12 no-pad">Problem with server, Please try again</p>',
            'content optional one',
            {
              position: ["top", "right"],
              timeOut: 3000,
              showProgressBar: false,
              pauseOnHover: false,
              clickToClose: true,
              maxLength: 10
            }
          )
          AppComponent.GetNotification('icon icon-fail angular-NotifyFail', 'Failed To Re-generate Key', 'Problem with server, Please try again', new Date());
          this.refreshHostpoolLoading = false;
        }
      );
    }
  }

  /*
   * This function is used to open Create New App Group Pop Up
   */
  public OpenNewAppGroup() {
    this.showAppGroupCreateDialog = true;
    this.searchByDesktop = "Desktop";
    this.btnSaveDisable = true;
    this.createAppGroupName = false;
    this.formCreateNewAppGroup = new FormGroup({
      txtAppGroupName: new FormControl('', Validators.required),
      txtAppGroupFrndName: new FormControl(''),
      txtAppGroupDesc: new FormControl(''),
      radiobtnAppType: new FormControl(''),
    });
  }

  /*
   * This function is used to close Create New App Group Pop Up
   */
  public HideNewAppGroup() {
    this.showAppGroupCreateDialog = false;
  }

  /*
   * This function is used to close  the appgroup edit modal Pop Up
   */
  public AppGroupsUpdateClose(): void {
    this.closeModal.nativeElement.click();
  }


  /*
   * This function is used to refresh the AppGroup Details
   */
  // public RefreshBtnClick() {
  //   this.isDeleteAppsDisabled = true;

  //this.GetAppGroupDetails();
  //   this.GetAllAppGroupsList(this.hostPoolName);
  // }
  public RefreshApps() {
    this.isDeleteAppsDisabled = true;
    this.isEditAppsDisabled = true;
    this.appGroupsAppListSearch = [];
    sessionStorage.removeItem('Apps');
    this.GetAllAppGroupApps();
  }
  public RefreshUsers() {
    this.appUsersListSearch = [];
    sessionStorage.removeItem('Users');
    this.GetAppGroupUsers();
  }
  /* This function is used to create an  array of current page numbers */
  public counter(i: number) {
    return new Array(i);
  }

  public RefreshUserSessions() {
    this.isLogOffDisabled = true;
    this.isSendMsgDisabled = true;
    this.userSessions = [];
    sessionStorage.removeItem('UserSessions');
    this.GetUserSessions();
  }

  /* This function is used to  divide the number of pages based on Tenants Count */
  public GetcurrentNoOfPagesCountAppgroup() {
    this.appGroupsList = JSON.parse(sessionStorage.getItem('Appgroups'));
    this.appgroupsCount = this.appGroupsList.length;
    let currentNoOfPagesCountCount = Math.floor(this.appgroupsCount / this.pageSize);
    let remaingCount = this.appgroupsCount % this.pageSize;
    if (remaingCount > 0) {
      this.currentNoOfPagesCount = currentNoOfPagesCountCount + 1;
    }
    else {
      this.currentNoOfPagesCount = currentNoOfPagesCountCount;
    }
    this.curentIndex = 0;
  }
  // public previousPageAppGroup() {
  //   this.refreshHostpoolLoading = true;
  //   this.appGroupListErrorFound = false;
  //   this.editedBodyAppGroup = false;
  //   this.checkedMainAppGroup = false;
  //   this.lastEntry = this.appGroupsListSearch[0].appGroupName;
  //   this.curentIndex = this.curentIndex - 1;
  //   this.getAllAppGroupsListUrl = this._AppService.ApiUrl + '/api/AppGroup/GetAppGroupsList?tenantGroupName=' + this.tenantGroupName + '&tenantName=' + this.tenantName + '&hostPoolName=' + this.hostPoolName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token") + ' &pageSize=' + this.pageSize + '&sortField=AppGroupName&isDescending=true&initialSkip=' + this.initialSkip + '&lastEntry=' + this.appGroupsListSearch[0].appGroupName;
  //   this._AppService.GetData(this.getAllAppGroupsListUrl).subscribe(response => {
  //     let AppGroupList = JSON.parse(response['_body']);
  //     this.appGroupsList = AppGroupList.reverse();
  //     this.AppGrouppreviousPageNo = this.AppGroupCurrentPageNo;
  //     this.AppGroupCurrentPageNo = this.AppGroupCurrentPageNo - 1;


  //     this.refreshHostpoolLoading = false;
  //     if (this.appGroupsList) {
  //       if (this.appGroupsList.code == "Invalid Token") {
  //         sessionStorage.clear();
  //         this.router.navigate(['/invalidtokenmessage']);
  //       }
  //     }
  //     this.appGroupsListSearch = JSON.parse(response['_body']);
  //     if (this.appGroupsListSearch.length == 0) {
  //       this.editedBodyAppGroup = true;
  //       this.editedLBody = false;
  //     }
  //     else {
  //       if (this.appGroupsListSearch[0].Message == null) {
  //         this.editedLBody = true;
  //         this.editedBodyAppGroup = false;
  //       }
  //     }
  //   },
  //     /*
  //      * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
  //      */
  //     (error) => {
  //       this.appGroupListErrorFound = true;
  //     }
  //   );
  //   this.isEditAppgroupDisabled = true;
  //   this.isDeleteAppgroupDisabled = true;
  // }
  // public CurrentPageAppGroup(index) {
  //   this.AppGrouppreviousPageNo = this.AppGroupCurrentPageNo;
  //   this.AppGroupCurrentPageNo = index + 1;
  //   this.curentIndex = index;
  //   let diff = this.AppGroupCurrentPageNo - this.AppGrouppreviousPageNo;
  //   // to get intialskip
  //   if (this.AppGroupCurrentPageNo >= this.AppGrouppreviousPageNo) {
  //     this.isDescending = false;
  //     this.pageSize = diff * this.pageSize;
  //     this.lastEntry = this.appGroupsListSearch[this.appGroupsListSearch.length - 1].appGroupName;
  //   } else {
  //     this.isDescending = true;
  //     this.lastEntry = this.appGroupsListSearch[0].appGroupName;
  //   }
  //   this.refreshHostpoolLoading = true;
  //   this.appGroupListErrorFound = false;
  //   this.editedBodyAppGroup = false;
  //   this.checkedMainAppGroup = false;
  //   this.getAllAppGroupsListUrl = this._AppService.ApiUrl + '/api/AppGroup/GetAppGroupsList?tenantGroupName=' + this.tenantGroupName + '&tenantName=' + this.tenantName + '&hostPoolName=' + this.hostPoolName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token") + ' &pageSize=' + this.pageSize + '&sortField=AppGroupName&isDescending=' + this.isDescending + '&initialSkip=' + this.initialSkip + '&lastEntry=' + this.lastEntry;
  //   this._AppService.GetData(this.getAllAppGroupsListUrl).subscribe(response => {
  //     this.appGroupsList = JSON.parse(response['_body']);
  //     this.refreshHostpoolLoading = false;
  //     if (this.appGroupsList) {
  //       if (this.appGroupsList.code == "Invalid Token") {
  //         sessionStorage.clear();
  //         this.router.navigate(['/invalidtokenmessage']);
  //       }
  //     }
  //     this.appGroupsListSearch = JSON.parse(response['_body']);
  //     if (this.appGroupsListSearch.length == 0) {
  //       this.editedBodyAppGroup = true;
  //       this.editedLBody = false;
  //     }
  //     else {
  //       if (this.appGroupsListSearch[0].Message == null) {
  //         this.editedLBody = true;
  //         this.editedBodyAppGroup = false;
  //       }
  //     }
  //   },
  //     /*
  //      * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
  //      */
  //     (error) => {
  //       this.appGroupListErrorFound = true;
  //     }
  //   );
  //   this.isEditAppgroupDisabled = true;
  //   this.isDeleteAppgroupDisabled = true;
  // }
  // public NextPageAppGroup() {
  //   this.lastEntry = this.appGroupsListSearch[this.appGroupsListSearch.length - 1].appGroupName;
  //   this.curentIndex = this.curentIndex + 1;
  //   this.refreshHostpoolLoading = true;
  //   this.appGroupListErrorFound = false;
  //   this.editedBodyAppGroup = false;
  //   this.checkedMainAppGroup = false;
  //   this.getAllAppGroupsListUrl = this._AppService.ApiUrl + '/api/AppGroup/GetAppGroupsList?tenantGroupName=' + this.tenantGroupName + '&tenantName=' + this.tenantName + '&hostPoolName=' + this.hostPoolName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token") + ' &pageSize=' + this.pageSize + '&sortField=AppGroupName&isDescending=false&initialSkip=' + this.initialSkip + '&lastEntry=' + this.lastEntry;
  //   this._AppService.GetData(this.getAllAppGroupsListUrl).subscribe(response => {
  //     this.appGroupsList = JSON.parse(response['_body']);
  //     this.AppGrouppreviousPageNo = this.AppGroupCurrentPageNo;
  //     this.AppGroupCurrentPageNo = this.AppGroupCurrentPageNo + 1;
  //     this.refreshHostpoolLoading = false;
  //     if (this.appGroupsList) {
  //       if (this.appGroupsList.code == "Invalid Token") {
  //         sessionStorage.clear();
  //         this.router.navigate(['/invalidtokenmessage']);
  //       }
  //     }
  //     this.appGroupsListSearch = JSON.parse(response['_body']);
  //     if (this.appGroupsListSearch.length == 0) {
  //       this.editedBodyAppGroup = true;
  //       this.editedLBody = false;
  //     }
  //     else {
  //       if (this.appGroupsListSearch[0].Message == null) {
  //         this.editedLBody = true;
  //         this.editedBodyAppGroup = false;
  //       }
  //     }
  //   },
  //     /*
  //      * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
  //      */
  //     (error) => {
  //       this.appGroupListErrorFound = true;
  //     }
  //   );
  //   this.isEditAppgroupDisabled = true;
  //   this.isDeleteAppgroupDisabled = true;
  // }
  ///*
  // * This function is used to make service call to get all the respective Appgrops of the selected hostpool
  // */
  public GetAllAppGroupsList(hostPoolName) {
    this.checked = [];
    this.checkedMainAppGroup = false;
    this.refreshHostpoolLoading = true;
    this.appGroupListErrorFound = false;
    this.editedBodyAppGroup = false;
    this.checkedMainAppGroup = false;

    let appGroups = JSON.parse(sessionStorage.getItem('Appgroups'));
    if (sessionStorage.getItem('Appgroups') && appGroups.length != 0 && appGroups != null && sessionStorage.getItem('SelectedHostpool') == this.hostPoolName) {
      this.gettingAppgroups();
      this.refreshHostpoolLoading = false;
    } else {
      //this.getAllAppGroupsListUrl = this._AppService.ApiUrl + '/api/AppGroup/GetAppGroupsList?tenantGroupName=' + this.tenantGroupName + '&tenantName=' + this.tenantName + '&hostPoolName=' + hostPoolName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token") + ' &pageSize=' + this.pageSize + '&sortField=AppGroupName&isDescending=false&initialSkip=' + this.initialSkip + '&lastEntry=%22%20%22';
      this.getAllAppGroupsListUrl = this._AppService.ApiUrl + '/api/AppGroup/GetAppGroupsList?tenantGroupName=' + this.tenantGroupName + '&tenantName=' + this.tenantName + '&hostPoolName=' + hostPoolName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token");// + ' &pageSize=' + this.pageSize + '&sortField=AppGroupName&isDescending=false&initialSkip=' + this.initialSkip + '&lastEntry=%22%20%22';
      this._AppService.GetData(this.getAllAppGroupsListUrl).subscribe(response => {
        this.refreshHostpoolLoading = false;
        if (response.status == 429) {
          this.error = true;
          this.errorMessage = response.statusText;
        }
        else {
          this.error = false;
          this.appGroupsList = JSON.parse(response['_body']);
          sessionStorage.setItem('Appgroups', JSON.stringify(this.appGroupsList));
          this.gettingAppgroups();
        }
      },
        /*
         * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
         */
        (error) => {
          this.error = true;
          let errorBody = JSON.parse(error['_body']);
          this.errorMessage = errorBody.error.target;
          this.appGroupListErrorFound = true;
          this.refreshHostpoolLoading = false;

        }
      );
    }
    this.isEditAppgroupDisabled = true;
    this.isDeleteAppgroupDisabled = true;
    this.showAppGroupDashBoard = false;
  }

  gettingAppgroups() {
    this.appGroupsList = JSON.parse(sessionStorage.getItem('Appgroups'));
    if (this.appGroupsList) {
      if (this.appGroupsList.code == "Invalid Token") {
        sessionStorage.clear();
        this.router.navigate(['/invalidtokenmessage']);
      }
    }
    this.appGroupsListSearch = JSON.parse(sessionStorage.getItem('Appgroups'));
    if (this.appGroupsListSearch.length == 0) {
      this.editedBodyAppGroup = true;
      this.editedLBody = false;
    }
    else {
      if (this.appGroupsListSearch[0].Message == null) {
        this.editedLBody = true;
        this.editedBodyAppGroup = false;
      }
    }
    this.GetcurrentNoOfPagesCountAppgroup();
    this.GetcurrentNoOfPagesCountHost();
  }

  /*
   * This function is used to select App Group
   * ----------
   * Parametes
   * appGroupIndex - Accepts App Group Index value
   * ----------
   */
  public IsCheckedAppGroup(appGroupIndex: any, event) {
    this.checked[appGroupIndex] = !this.checked[appGroupIndex];
    if (event.target.checked != null && event.target.checked != undefined) {
      this.showAppGroupDashBoard = !event.target.checked;// !this.showAppGroupDashBoard;
    }
    else if (event.type == "click") {
      this.showAppGroupDashBoard = this.showAppGroupDashBoard == true ? false : true;// !this.showHostDashBoard;
    }
    //this.showHostDashBoard = false;///addded by susmita
    this.appGroupcheckedTrue = [];
    for (let i = 0; i < this.checked.length; i++) {
      if (this.checked[i] == true) {
        this.appGroupcheckedTrue.push(this.checked[i]);
      }
      if (this.checked[i] == false) {
        this.checkedMainAppGroup = false;
        break;
      }
      else {
        if (this.appGroupsList.length == this.appGroupcheckedTrue.length) {
          this.checkedMainAppGroup = true;
        }
      }
    }
    if(this.appGroupcheckedTrue.length==1)
      {
        this.state = 'up';
      }
  }

  /*
   * This function is used to Select the all the apprgoups by clicking on checkbox
   * ----------
   * parameters
   * event - Accepts Events
   * ----------
   */
  public AppGroupCheckAll(event: any) {
    this.checkedMainAppGroup = !this.checkedMainAppGroup;
    this.selectedAppGroupRows = [];
    for (let i = 0; i < this.appGroupsList.length; i++) {
      var index = i;
      if (event.target.checked) {
        this.checked[i] = true;
        this.appGroupDetails = [];
        this.state = 'down';
      }
      else {
        this.checked[i] = false;
      }
    }
    this.checkedAllTrueAppGroup = [];
    for (let j = 0; j < this.checked.length; j++) {
      if (this.checked[j] == true) {
        this.checkedAllTrueAppGroup.push(this.checked[j]);
        this.selectedAppGroupRows.push(j);
      }
    }
    if (this.checkedAllTrueAppGroup.length == 1) {
      this.appGroupDetails = [];
      this.isEditAppgroupDisabled = false;
      this.isDeleteAppgroupDisabled = false;
      this.state = 'up';
      this.showAppGroupDashBoard = true;
      this.deleteCountSelectedAppgroups = this.appGroupsListSearch[index].appGroupName;
      this.appgroupFormEdit = new FormGroup({
        appGroupName: new FormControl(this.appGroupsListSearch[index].appGroupName),
        friendlyName: new FormControl(this.appGroupsListSearch[index].friendlyName),
        description: new FormControl(this.appGroupsListSearch[index].description),
        editRadiobtnAppType: new FormControl(this.selectedRadioBtn),
      });
      if (this.appGroupsListSearch[index].resourceType == 1) {
        this.removeAppsTab = false;
        this.selectedRadioBtn = 'Desktop'
      }
      else {
        this.removeAppsTab = true;
        this.selectedRadioBtn = 'RemoteApp'
      }
      this.AppgroupName = this.appGroupsListSearch[index].appGroupName;
      this.selectedAppGroupName = this.appGroupsListSearch[index].appGroupName;
      this.GetAppGroupDetails();
    } else if (this.checkedAllTrueAppGroup.length > 1) {
      this.isEditAppgroupDisabled = true;
      this.isDeleteAppgroupDisabled = false;
      this.deleteCountSelectedAppgroups = this.checkedAllTrueAppGroup.length;
    }
    else {
      this.isEditAppgroupDisabled = true;
      this.isDeleteAppgroupDisabled = true;
      this.appGroupDetails = [];
      this.state = 'down';
    }
  }

  /*
   * This function is used to Select the row of the AppGroup Listed Table
   * ----------
   * parameters
   * appGroupIndex - Accepts App Group Index
   * ----------
   */
  public AppGroupsListRowClicked(appGroupIndex: any, event) {
    this.IsCheckedAppGroup(appGroupIndex, event);
    this.appGroupcheckedTrue = [];
    this.selectedAppGroupName = '';
    this.selectedAppGroupRows = [];
    var index;
    for (var i = 0; i < this.checked.length; i++) {
      if (this.checked[i] == true) {
        this.appGroupcheckedTrue.push(this.checked[i]);
        this.selectedAppGroupRows.push(i);
        index = i;
      }
    }
    if (this.appGroupcheckedTrue.length == 1) {
      this.appGroupDetails = [];
      this.state = 'up';
      this.isEditAppgroupDisabled = false;
      this.isDeleteAppgroupDisabled = false;
      if (this.appGroupsListSearch[index].resourceType == 1) {
        this.removeAppsTab = false;
        this.selectedRadioBtn = 'Desktop'
      } else {
        this.removeAppsTab = true;
        this.selectedRadioBtn = 'RemoteApp'
      }
      this.AppgroupName = this.appGroupsListSearch[index].appGroupName;
      this.selectedAppGroupName = this.appGroupsListSearch[index].appGroupName;
      this.GetAppGroupDetails();
      this.deleteCountSelectedAppgroups = this.appGroupsListSearch[index].appGroupName;
      this.appgroupFormEdit = new FormGroup({
        appGroupName: new FormControl(this.appGroupsListSearch[index].appGroupName),
        friendlyName: new FormControl(this.appGroupsListSearch[index].friendlyName),
        description: new FormControl(this.appGroupsListSearch[index].description),
        editRadiobtnAppType: new FormControl(this.selectedRadioBtn),
      });
    }
    else {
      if (this.appGroupcheckedTrue.length > 1) {
        this.isEditAppgroupDisabled = true;
        this.isDeleteAppgroupDisabled = false;
        this.deleteCountSelectedAppgroups = this.appGroupcheckedTrue.length;
        this.AppGroupbottomBtnClose(event);
      }
      else {
        this.isEditAppgroupDisabled = true;
        this.isDeleteAppgroupDisabled = true;
        this.AppGroupbottomBtnClose(event);
      }
    }
  }

  /*
   * This function is used on change event validation for appgroup name
   * ----------
   * parameters
   * value - Accepts Event
   * ----------
   */
  public AppGroupNameChange(value) {
    if (value == "") {
      this.createAppGroupName = true;
      this.btnSaveDisable = true;
    }
    else {
      this.createAppGroupName = false;
      this.btnSaveDisable = false;
    }
  }

  public TitleChange(value) {
    this.Title = value == "" || value == undefined || value == null ? true : false;
    this.sendMesageButtonDisable = value == "" ? true : false;
  }

  public MessageChange(value) {
    this.Message = value == "" || value == undefined || value == null ? true : false;
    this.sendMesageButtonDisable = value == "" ? true : false;
  }

  /*
   * This function is used to create the new AppGroup
   * ----------
   * parameters
   * appGroupCreateData - Accepts the Add App Group Form Values
   * ----------
   */
  public CreateNewAppGroup(appGroupCreateData) {
    this.refreshHostpoolLoading = true;
    if (appGroupCreateData.txtAppGroupName == "") {
      this.createAppGroupName = true;
      this.refreshHostpoolLoading = false;
    }
    else {
      let groupType;
      if (appGroupCreateData.radiobtnAppType == "Desktop") {
        groupType = 1;
      }
      else {
        groupType = 0;
      }
      var Appdata = {
        "tenantGroupName": this.tenantGroupName,
        "tenantName": this.tenantName,
        "hostPoolName": this.hostPoolName,
        "appGroupName": appGroupCreateData.txtAppGroupName.trim(),
        "description": appGroupCreateData.txtAppGroupDesc.trim(),
        "friendlyName": appGroupCreateData.txtAppGroupFrndName.trim(),
        "resourceType": groupType,
        "refresh_token": sessionStorage.getItem("Refresh_Token"),
      };
      this.appGroupCreateUrl = this._AppService.ApiUrl + '/api/AppGroup/Post';
      this._AppService.CreateTenantAppGroup(this.appGroupCreateUrl, Appdata).subscribe(response => {
        this.refreshHostpoolLoading = false;
        var responseData = JSON.parse(response['_body']);
        if (responseData.message == "Invalid Token") {
          sessionStorage.clear();
          this.router.navigate(['/invalidtokenmessage']);
        }
        /* If response data is success then it enters into if and this block of code will execute to show the 'App Group Created Successfully' notification */
        if (responseData.isSuccess === true) {
          this._notificationsService.html(
            '<i class="icon icon-check angular-Notify col-xs-1 no-pad"></i>' +
            '<label class="notify-label col-xs-10 no-pad">App Group Created Successfully</label>' +
            '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
            '<p class="notify-text col-xs-12 no-pad">' + responseData.message + '</p>',
            'content optional one',
            {
              position: ["top", "right"],
              timeOut: 3000,
              showProgressBar: false,
              pauseOnHover: false,
              clickToClose: true,
              maxLength: 10
            }
          )
          AppComponent.GetNotification('icon icon-check angular-Notify', 'App Group Created Successfully', responseData.message, new Date());
          this.HideNewAppGroup();
          this.RefreshAppgroups();
        }
        /* If response data is success then it enters into else and this block of code will execute to show the 'Failed To Create App Group' notification */
        else {
          this._notificationsService.html(
            '<i class="icon icon-fail angular-NotifyFail col-xs-1 no-pad"></i>' +
            '<label class="notify-label col-xs-10 no-pad">Failed To Create App Group</label>' +
            '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
            '<p class="notify-text col-xs-12 no-pad">' + responseData.message + '</p>',
            'content optional one',
            {
              position: ["top", "right"],
              timeOut: 3000,
              showProgressBar: false,
              pauseOnHover: false,
              clickToClose: true,
              maxLength: 10
            }
          )
          AppComponent.GetNotification('icon icon-fail angular-NotifyFail', 'Failed To Create App Group', responseData.message, new Date());
          this.HideNewAppGroup();
          this.RefreshAppgroups();
        }
      },
        /*
         * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
         */
        (error) => {
          this._notificationsService.html(
            '<i class="icon icon-fail angular-NotifyFail col-xs-1 no-pad"></i>' +
            '<label class="notify-label col-xs-10 no-pad">Failed To Create App Group</label>' +
            '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
            '<p class="notify-text col-xs-12 no-pad">Problem with server, Please try again</p>',
            'content optional one',
            {
              position: ["top", "right"],
              timeOut: 3000,
              showProgressBar: false,
              pauseOnHover: false,
              clickToClose: true,
              maxLength: 10
            }
          )
          AppComponent.GetNotification('icon icon-fail angular-NotifyFail', 'Failed To Create App Group', 'Problem with server, Please try again', new Date());
          this.HideNewAppGroup();
          this.RefreshAppgroups();
        }
      );
    }
  }

  /*
   * This function is used to update the selected AppGroup
   * ----------
   * parameters
   * updateAppGroupData - Accepts the Edit App Group Form Values
   * ----------
   */
  public UpdateAppGroup(updateAppGroupData: any) {
    var updateArray = {
      "tenantGroupName": this.tenantGroupName,
      "tenantName": this.tenantName,
      "hostPoolName": this.hostPoolName,
      "appGroupName": this.selectedAppGroupName,
      "description": updateAppGroupData.description.trim(),
      "friendlyName": updateAppGroupData.friendlyName.trim(),
      "resourceType": "0",
      "refresh_token": sessionStorage.getItem("Refresh_Token"),
    };
    this.updateAppGroupLoading = true;
    this.updateAppgroupUrl = this._AppService.ApiUrl + '/api/AppGroup/Put';
    this._AppService.UpdateAppGroup(this.updateAppgroupUrl, updateArray).subscribe(response => {
      this.updateAppGroupLoading = false;
      var responseData = JSON.parse(response['_body']);
      if (responseData.message == "Invalid Token") {
        sessionStorage.clear();
        this.router.navigate(['/invalidtokenmessage']);
      }
      /* If response data is success then it enters into if and this block of code will execute to show the 'App Group Updated Successfully' notification */
      if (responseData.isSuccess === true) {
        this._notificationsService.html(
          '<i class="icon icon-check angular-Notify col-xs-1 no-pad"></i>' +
          '<label class="notify-label col-xs-10 no-pad">App Group Updated Successfully</label>' +
          '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
          '<p class="notify-text col-xs-12 no-pad">' + responseData.message + '</p>',
          'content optional one',
          {
            position: ["top", "right"],
            timeOut: 3000,
            showProgressBar: false,
            pauseOnHover: false,
            clickToClose: true,
            maxLength: 10
          }
        )
        AppComponent.GetNotification('icon icon-check angular-Notify', 'App Group Updated Successfully', responseData.message, new Date());
        this.AppGroupsUpdateClose();
        this.state = 'down';
        this.RefreshAppgroups();
      }
      /* If response data is success then it enters into else and this block of code will execute to show the 'Failed To Update App Group' notification */
      else {
        this._notificationsService.html(
          '<i class="icon icon-fail angular-NotifyFail col-xs-1 no-pad"></i>' +
          '<label class="notify-label col-xs-10 no-pad">Failed To Update App Group</label>' +
          '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
          '<p class="notify-text col-xs-12 no-pad">' + responseData.message + '</p>',
          'content optional one',
          {
            position: ["top", "right"],
            timeOut: 3000,
            showProgressBar: false,
            pauseOnHover: false,
            clickToClose: true,
            maxLength: 10
          }
        )
        AppComponent.GetNotification('icon icon-fail angular-NotifyFail', 'Failed To Update App Group', responseData.message, new Date());
        this.AppGroupsUpdateClose();
        this.RefreshAppgroups();
      }
    },
      /*
       * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
       */
      (error) => {
        this._notificationsService.html(
          '<i class="icon icon-fail angular-NotifyFail col-xs-1 no-pad"></i>' +
          '<label class="notify-label col-xs-10 no-pad">Failed To Update App Group</label>' +
          '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
          '<p class="notify-text col-xs-12 no-pad">Problem with server, Please try again</p>',
          'content optional one',
          {
            position: ["top", "right"],
            timeOut: 3000,
            showProgressBar: false,
            pauseOnHover: false,
            clickToClose: true,
            maxLength: 10
          }
        )
        AppComponent.GetNotification('icon icon-fail angular-NotifyFail', 'Failed To Update App Group', 'Problem with server, Please try again', new Date());
        this.AppGroupsUpdateClose();
        this.RefreshAppgroups();
      }
    );
  }

  /*
   * This function is used to delete the selected AppGroup
   */
  public DeleteAppGroups() {
    this.refreshHostpoolLoading = true;
    for (let i = 0; i < this.selectedAppGroupRows.length; i++) {
      var index = this.selectedAppGroupRows[i];
      this.appGroupsDeleteUrl = this._AppService.ApiUrl + '/api/AppGroup/Delete?tenantGroupName=' + this.tenantGroupName + '&tenantName=' + this.appGroupsListSearch[index].tenantName + '&hostpoolName=' + this.appGroupsListSearch[index].hostPoolName + '&appgroupName=' + this.appGroupsListSearch[index].appGroupName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token");
      this._AppService.DeleteAppGroupsList(this.appGroupsDeleteUrl).subscribe(response => {
        this.refreshHostpoolLoading = false;
        var responseData = JSON.parse(response['_body']);
        if (responseData.message == "Invalid Token") {
          sessionStorage.clear();
          this.router.navigate(['/invalidtokenmessage']);
        }
        /* If response data is success then it enters into if and this block of code will execute to show the 'App Group Deleted Successfully' notification */
        if (responseData.isSuccess === true) {
          this._notificationsService.html(
            '<i class="icon icon-check angular-Notify col-xs-1 no-pad"></i>' +
            '<label class="notify-label col-xs-10 no-pad">App Group Deleted Successfully</label>' +
            '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
            '<p class="notify-text col-xs-12 no-pad">' + responseData.message + '</p>',
            'content optional one',
            {
              position: ["top", "right"],
              timeOut: 3000,
              showProgressBar: false,
              pauseOnHover: false,
              clickToClose: true,
              maxLength: 10
            }
          )
          AppComponent.GetNotification('icon icon-check angular-Notify', 'App Group Deleted Successfully', responseData.message, new Date());
          this.selectedClassMax = true;
          this.selectedClassMin = false;
          this.state = 'down';
          this.RefreshAppgroups();
        }
        /* If response data is success then it enters into else and this block of code will execute to show the 'Failed To Delete App Group' notification */
        else {
          this._notificationsService.html(
            '<i class="icon icon-fail angular-NotifyFail col-xs-1 no-pad"></i>' +
            '<label class="notify-label col-xs-10 no-pad">Failed To Delete App Group</label>' +
            '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
            '<p class="notify-text col-xs-12 no-pad">' + responseData.message + '</p>',
            'content optional one',
            {
              position: ["top", "right"],
              timeOut: 3000,
              showProgressBar: false,
              pauseOnHover: false,
              clickToClose: true,
              maxLength: 10
            }
          )
          AppComponent.GetNotification('icon icon-fail angular-NotifyFail', 'Failed To Delete App Group', responseData.message, new Date());
          this.RefreshAppgroups();
        }
      },
        /*
         * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
         */
        (error) => {
          this._notificationsService.html(
            '<i class="icon icon-fail angular-NotifyFail col-xs-1 no-pad"></i>' +
            '<label class="notify-label col-xs-10 no-pad">Failed To Delete App Group</label>' +
            '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
            '<p class="notify-text col-xs-12 no-pad">Problem with server, Please try again</p>',
            'content optional one',
            {
              position: ["top", "right"],
              timeOut: 3000,
              showProgressBar: false,
              pauseOnHover: false,
              clickToClose: true,
              maxLength: 10
            }
          )
          AppComponent.GetNotification('icon icon-fail angular-NotifyFail', 'Failed To Delete App Group', 'Problem with server, Please try again', new Date());
          this.RefreshAppgroups();
        }
      );
    }
  }

  /*
   * This function is used to get the selected AppGroup details
   */
  public GetAppGroupDetails() {
    let Appgroups = JSON.parse(sessionStorage.getItem('Appgroups'));
    let data = Appgroups.filter(item => item.appGroupName == this.selectedAppGroupName);
    this.appGroupDetails = data[0];
    // this.detailsErrorFound = false;
    // this.refreshHostpoolLoading = true;
    // this.getAppGroupDetailsUrl = this._AppService.ApiUrl + '/api/AppGroup/GetAppGroupDetails?tenantGroupName=' + this.tenantGroupName + '&tenantName=' + this.tenantName + '&hostPoolName=' + this.hostPoolName + '&appGroupName=' + this.selectedAppGroupName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token");
    // this._AppService.GetData(this.getAppGroupDetailsUrl).subscribe(response => {
    //   this.refreshHostpoolLoading = false;
    //   this.appGroupDetails = JSON.parse(response['_body']);
    //   this.appsCount = this.appGroupDetails.noOfApps;
    //   this.usersCount = this.appGroupDetails.noOfusers;
    //   if (this.appGroupDetails) {
    //     if (this.appGroupDetails.code == "Invalid Token") {
    //       sessionStorage.clear();
    //       this.router.navigate(['/invalidtokenmessage']);
    //     }
    //   }
    // },
    //   /*
    //    * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
    //    */
    //   (error) => {
    //     this.detailsErrorFound = true;
    //     this.refreshHostpoolLoading = false;
    //   }
    // );
    if (this.selectedRadioBtn == 'RemoteApp') {
      this.GetAllAppGroupApps();
    } else {
      this.GetAppGroupUsers();
    }
  }

  /*
   * This function is used to get the Appgroup users list and load into table
   */
  public GetAppGroupUsers() {
    this.checkedUsers = [];
    this.checkedMainUser = false;
    this.usersListErrorFound = false;
    this.refreshHostpoolLoading = true;
    // this.getAppGroupUserUrl = this._AppService.ApiUrl + '/api/AppGroup/GetUsersList?tenantGroupName=' + this.tenantGroupName + '&tenantName=' + this.tenantName + '&hostPoolName=' + this.hostPoolName + '&appGroupName=' + this.selectedAppGroupName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token") + '&pageSize=' + this.pageSize + '&sortField=UserPrincipalName&isDescending=false&initialSkip=' + this.usersInitialSkip + '&lastEntry=' + this.usersLastEntry;
    this.getAppGroupUserUrl = this._AppService.ApiUrl + '/api/AppGroup/GetUsersList?tenantGroupName=' + this.tenantGroupName + '&tenantName=' + this.tenantName + '&hostPoolName=' + this.hostPoolName + '&appGroupName=' + this.selectedAppGroupName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token");//+ '&pageSize=' + this.pageSize + '&sortField=UserPrincipalName&isDescending=false&initialSkip=' + this.usersInitialSkip + '&lastEntry=' + this.usersLastEntry;
    this._AppService.GetData(this.getAppGroupUserUrl).subscribe(response => {
      this.refreshHostpoolLoading = false;
      if (response.status == 429) {
        this.error = true;
        this.errorMessage = response.statusText;
      }
      else {
        this.error = false;
        this.appUsersList = JSON.parse(response['_body']);
        this.usersCount = this.appUsersList.length;
        sessionStorage.setItem('Users', JSON.stringify(this.appUsersList));
        sessionStorage.setItem('SelectedAppGroup', this.selectedAppGroupName);
        this.getusers();
      }
    },
      /*
       * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
       */
      (error) => {
        this.error = true;
        let errorBody = JSON.parse(error['_body']);
        this.errorMessage = errorBody.error.target;
        this.usersListErrorFound = true;
        this.refreshHostpoolLoading = false;
      }
    );
    this.isDeleteUserDisabled = true;
  }


  /**
   * 
   */
  public GetUserSessions() {
    this.refreshHostpoolLoading = true;
    this.checkedUserSessions = [];
    this.checkedMainUserSession = false;
    this.SessionsListErrorFound = false;
    this.getUserSessionUrl = this._AppService.ApiUrl + '/api/UserSession/GetListOfUserSessions?tenantGroupName=' + this.tenantGroupName + '&tenantName=' + this.tenantName + '&hostPoolName=' + this.hostPoolName + '&hostName=' + this.selectedHostName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token");
    this._AppService.GetData(this.getUserSessionUrl).subscribe(response => {
      this.refreshHostpoolLoading = false;
      if (response.status == 429) {
        this.error = true;
        this.errorMessage = response.statusText;
      }
      else {
        this.error = false;
        this.UserSessionLoader = false;
        this.userSessions = JSON.parse(response['_body']);
        this.userSessionSearchList = this.userSessions;
        this.userSessionsCount = this.userSessions.length;
        sessionStorage.setItem('UserSessions', JSON.stringify(this.userSessions));
      }
    },
      /*
       * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
       */
      (error) => {
        this.error = true;
        let errorBody = JSON.parse(error['_body']);
        this.errorMessage = errorBody.error.target;
        this.SessionsListErrorFound = true;
      }
    );
    this.isDeleteUserDisabled = true;
  }

  public getusers() {
    let appUsersList = JSON.parse(sessionStorage.getItem('Users'));
    if (this.appUsersList) {
      if (this.appUsersList.code == "Invalid Token") {
        sessionStorage.clear();
        this.router.navigate(['/invalidtokenmessage']);
      }
    }
    this.GetcurrentNoOfUsersPagesCount(this.usersCount);
    this.appUsersListSearch = appUsersList;
    if (this.appUsersListSearch.length == 0) {
      this.editedLbodyUsers = true;
      this.editedBodyUsers = false;
    }
    else {
      if (this.appUsersListSearch[0].Message == null) {
        this.editedBodyUsers = true;
        this.editedLbodyUsers = false;
      }
    }

  }

  /* This function is used to  loads all the Users into table on click of Previous button in the table */
  // public usersPreviousPage() {
  //   this.checkedUsers = [];
  //   this.checkedMainUser = false;
  //   this.usersListErrorFound = false;
  //   this.refreshHostpoolLoading = true;
  //   this.usersLastEntry = this.appUsersList[0].userPrincipalName;
  //   this.usersCurentIndex = this.usersCurentIndex - 1;
  //   this.getAppGroupUserUrl = this._AppService.ApiUrl + '/api/AppGroup/GetUsersList?tenantGroupName=' + this.tenantGroupName + '&tenantName=' + this.tenantName + '&hostPoolName=' + this.hostPoolName + '&appGroupName=' + this.selectedAppGroupName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token") + '&pageSize=' + this.pageSize + '&sortField=UserPrincipalName&isDescending=true&initialSkip=' + this.usersInitialSkip + '&lastEntry=' + this.usersLastEntry;
  //   this._AppService.GetData(this.getAppGroupUserUrl).subscribe(response => {
  //     this.appUsersList = JSON.parse(response['_body']);
  //     this.usersPreviousPageNo = this.usersCurrentPageNo;
  //     this.usersCurrentPageNo = this.usersCurrentPageNo - 1;
  //     if (this.appUsersList) {
  //       if (this.appUsersList.code == "Invalid Token") {
  //         sessionStorage.clear();
  //         this.router.navigate(['/invalidtokenmessage']);
  //       }
  //     }
  //     this.GetcurrentNoOfUsersPagesCount(this.usersCount);
  //     this.appUsersListSearch = JSON.parse(response['_body']);
  //     if (this.appUsersListSearch.length == 0) {
  //       this.editedLbodyUsers = true;
  //       this.editedBodyUsers = false;
  //     }
  //     else {
  //       if (this.appUsersListSearch[0].Message == null) {
  //         this.editedBodyUsers = true;
  //         this.editedLbodyUsers = false;
  //       }
  //     }
  //     this.refreshHostpoolLoading = false;
  //   },
  //     /*
  //      * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
  //      */
  //     (error) => {
  //       this.usersListErrorFound = true;
  //       this.refreshHostpoolLoading = false;
  //     }
  //   );
  //   this.isDeleteUserDisabled = true;
  // }

  /* This function is used to  loads all the Users into table on click of Current page number values  in the table
    * ---------
   * Parameters
   * index - Accepts current index  count 
   * ---------
   */
  // public usersCurrentPage(index) {
  //   this.usersPreviousPageNo = this.usersCurrentPageNo;
  //   this.usersCurrentPageNo = index + 1;
  //   this.usersCurentIndex = index;
  //   this.checkedUsers = [];
  //   this.checkedMainUser = false;
  //   this.usersListErrorFound = false;
  //   this.refreshHostpoolLoading = true;
  //   let diff = this.usersCurrentPageNo - this.usersPreviousPageNo;
  //   // to get intialskip
  //   if (this.usersCurrentPageNo >= this.usersPreviousPageNo) {
  //     this.usersIsDescending = false;
  //     this.pageSize = diff * this.pageSize;
  //     this.usersLastEntry = this.appUsersList[this.appUsersList.length - 1].userPrincipalName;
  //   } else {
  //     this.usersIsDescending = true;
  //     this.usersLastEntry = this.appUsersList[0].userPrincipalName;
  //   }
  //   this.getAppGroupUserUrl = this._AppService.ApiUrl + '/api/AppGroup/GetUsersList?tenantGroupName=' + this.tenantGroupName + '&tenantName=' + this.tenantName + '&hostPoolName=' + this.hostPoolName + '&appGroupName=' + this.selectedAppGroupName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token") + '&pageSize=' + this.pageSize + '&sortField=UserPrincipalName&isDescending=' + this.usersIsDescending + '&initialSkip=' + this.usersInitialSkip + '&lastEntry=' + this.usersLastEntry;
  //   this._AppService.GetData(this.getAppGroupUserUrl).subscribe(response => {
  //     this.appUsersList = JSON.parse(response['_body']);
  //     if (this.appUsersList) {
  //       if (this.appUsersList.code == "Invalid Token") {
  //         sessionStorage.clear();
  //         this.router.navigate(['/invalidtokenmessage']);
  //       }
  //     }
  //     this.appUsersListSearch = JSON.parse(response['_body']);
  //     if (this.appUsersListSearch.length == 0) {
  //       this.editedLbodyUsers = true;
  //       this.editedBodyUsers = false;
  //     }
  //     else {
  //       if (this.appUsersListSearch[0].Message == null) {
  //         this.editedBodyUsers = true;
  //         this.editedLbodyUsers = false;
  //       }
  //     }
  //     this.refreshHostpoolLoading = false;
  //   },
  //     /*
  //      * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
  //      */
  //     (error) => {
  //       this.usersListErrorFound = true;
  //       this.refreshHostpoolLoading = false;
  //     }
  //   );
  //   this.isDeleteUserDisabled = true;
  // }



  /* This function is used to  loads all the Users into table on click of Next button in the table */
  // public usersNextPage() {
  //   this.checkedUsers = [];
  //   this.checkedMainUser = false;
  //   this.usersListErrorFound = false;
  //   this.refreshHostpoolLoading = true;
  //   this.usersLastEntry = this.appUsersList[this.appUsersList.length - 1].userPrincipalName;
  //   this.usersCurentIndex = this.usersCurentIndex + 1;
  //   this.getAppGroupUserUrl = this._AppService.ApiUrl + '/api/AppGroup/GetUsersList?tenantGroupName=' + this.tenantGroupName + '&tenantName=' + this.tenantName + '&hostPoolName=' + this.hostPoolName + '&appGroupName=' + this.selectedAppGroupName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token") + '&pageSize=' + this.pageSize + '&sortField=UserPrincipalName&isDescending=false&initialSkip=' + this.usersInitialSkip + '&lastEntry=' + this.usersLastEntry;
  //   this._AppService.GetData(this.getAppGroupUserUrl).subscribe(response => {
  //     this.appUsersList = JSON.parse(response['_body']);
  //     this.usersPreviousPageNo = this.usersCurrentPageNo;
  //     this.usersCurrentPageNo = this.usersCurrentPageNo + 1;
  //     if (this.appUsersList) {
  //       if (this.appUsersList.code == "Invalid Token") {
  //         sessionStorage.clear();
  //         this.router.navigate(['/invalidtokenmessage']);
  //       }
  //     }
  //     this.appUsersListSearch = JSON.parse(response['_body']);
  //     if (this.appUsersListSearch.length == 0) {
  //       this.editedLbodyUsers = true;
  //       this.editedBodyUsers = false;
  //     }
  //     else {
  //       if (this.appUsersListSearch[0].Message == null) {
  //         this.editedBodyUsers = true;
  //         this.editedLbodyUsers = false;
  //       }
  //     }
  //     this.refreshHostpoolLoading = false;
  //   },
  //     /*
  //      * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
  //      */
  //     (error) => {
  //       this.usersListErrorFound = true;
  //       this.refreshHostpoolLoading = false;
  //     }
  //   );
  //   this.isDeleteUserDisabled = true;
  // };

  /*
   * This function is used to select all the AppGroup users in the table using checkbox or rowclick
   * ----------
   * parameters
   * event - Accepts Event
   * ----------
   */
  public AppUsersCheckAll(event: any) {
    this.checkedMainUser = !this.checkedMainUser;
    this.userCheckedTrue = [];
    this.selectedUsersRows = [];
    /* If we check the checkbox then this block of code executes*/
    for (let i = 0; i < this.appUsersListSearch.length; i++) {
      if (event.target.checked) {
        this.checkedUsers[i] = true;
      }
      /* If we uncheck the checkbox then this block of code executes*/
      else {
        this.checkedUsers[i] = false;
      }
    }
    /* If we check the multiple checkboxes then this block of code executes*/
    this.checkedAllTrueUsers = [];
    for (let j = 0; j < this.checkedUsers.length; j++) {
      if (this.checkedUsers[j] == true) {
        this.checkedAllTrueUsers.push(this.checkedUsers[j]);
        this.selectedUsersRows.push(j);
      }
    }
    this.deleteCountSelectedUser = this.checkedAllTrueUsers.length;
    this.selectedUsersRows.length = this.deleteCountSelectedUser;
    if (this.checkedAllTrueUsers.length >= 1) {
      this.isDeleteUserDisabled = false;
    }
    else if (this.checkedAllTrueUsers.length == 0) {
      this.isDeleteUserDisabled = true;
    }
  }

  public UserSessionCheckAll(event: any) {
    this.checkedMainUserSession = !this.checkedMainUserSession;
    this.userSessionCheckedTrue = [];
    this.selectedUserSessionsRows = [];
    /* If we check the checkbox then this block of code executes*/
    for (let i = 0; i < this.userSessions.length; i++) {
      if (event.target.checked) {
        this.checkedUserSessions[i] = true;
      }
      /* If we uncheck the checkbox then this block of code executes*/
      else {
        this.checkedUserSessions[i] = false;
      }
    }
    /* If we check the multiple checkboxes then this block of code executes*/
    this.checkedAllTrueUserSessions = [];
    for (let j = 0; j < this.checkedUserSessions.length; j++) {
      if (this.checkedUserSessions[j] == true) {
        this.checkedAllTrueUserSessions.push(this.checkedUserSessions[j]);
        this.selectedUserSessionsRows.push(j);
      }
    }
    this.CountSelectedUserSession = this.checkedAllTrueUserSessions.length;
    this.selectedUserSessionsRows.length = this.CountSelectedUserSession;
    if (this.checkedAllTrueUserSessions.length >= 1) {
      this.isLogOffDisabled = false;
      this.isSendMsgDisabled = false;
    }
    else if (this.checkedAllTrueUserSessions.length == 0) {
      this.isLogOffDisabled = true;
      this.isSendMsgDisabled = true;
    }
  }

  /*
   * This function is used to select single AppGroup users from the table using checkbox or rowclick
   * ----------
   * parameters
   * ind - Accepts User Index
   * ----------
   */
  public AppUsersIsChecked(ind: any) {
    this.checkedUsers[ind] = !this.checkedUsers[ind];
    this.userCheckedTrue = [];
    for (let i = 0; i < this.checkedUsers.length; i++) {
      if (this.checkedUsers[i] == true) {
        this.userCheckedTrue.push(this.checkedUsers[i]);
        this.isDeleteUserDisabled = true;
      }
      if (this.checkedUsers[i] == false) {
        this.checkedMainUser = false;
        this.isDeleteUserDisabled = false;
        break;
      }
      else {

        if (this.appUsersListSearch.length == this.userCheckedTrue.length) {
          this.checkedMainUser = true;
        }
      }
    }
  }

  /**
   * This function is used to select single user session from the table using checkbox or rowclick
   */

  public UserSessionIsChecked(ind: any) {

    this.checkedUserSessions[ind] = !this.checkedUserSessions[ind];
    this.userSessionCheckedTrue = [];
    for (let i = 0; i < this.checkedUserSessions.length; i++) {
      if (this.checkedUserSessions[i] == true) {
        this.userSessionCheckedTrue.push(this.checkedUserSessions[i]);
        this.isLogOffDisabled = true;
        this.isSendMsgDisabled = true;
      }
      if (this.checkedUserSessions[i] == false) {
        this.checkedMainUserSession = false;
        this.isLogOffDisabled = false;
        this.isSendMsgDisabled = false;
        break;
      }
      else {

        if (this.userSessions.length == this.userSessionCheckedTrue.length) {
          this.checkedMainUserSession = true;
        }
      }
    }
  }

  /*
   * This function is used to select single AppGroup users from the table rowclick
   * ----------
   * parameters
   * userPrincipalName - Accepts User Principle Name
   * ind - Accepts User Index
   * ----------
   */
  public AppUserRowClick(userPrincipalName: any, ind: any) {
    this.AppUsersIsChecked(ind);
    this.selectedUsersRows = [];
    this.selectedUsergroupName = '';
    this.userCheckedTrue = [];
    var index = null;
    for (var i = 0; i < this.checkedUsers.length; i++) {
      if (this.checkedUsers[i] == true) {
        this.userCheckedTrue.push(this.checkedUsers[i]);
        this.selectedUsersRows.push(i);
        index = i;
      }
    }
    if (this.userCheckedTrue.length == 1) {
      this.selectedUsergroupName = userPrincipalName;
      this.deleteCountSelectedUser = this.appUsersListSearch[index].userPrincipalName;
      this.isDeleteUserDisabled = false;
    }
    else if (this.userCheckedTrue.length > 1) {
      this.deleteCountSelectedUser = this.selectedUsersRows.length;
      this.isDeleteUserDisabled = false;
    }
    else {
      this.userCheckedTrue = [];
      this.isDeleteUserDisabled = true;
    }
  }

  public UserSessionRowClick(session: any, ind: any) {
    this.UserSessionIsChecked(ind);
    this.selectedUserSessionsRows = [];
    //this.selectedUserSession ;
    this.userSessionCheckedTrue = [];
    var index = null;
    for (var i = 0; i < this.checkedUserSessions.length; i++) {
      if (this.checkedUserSessions[i] == true) {
        this.userSessionCheckedTrue.push(this.checkedUserSessions[i]);
        this.selectedUserSessionsRows.push(i);
        index = i;
      }
    }
    if (this.userSessionCheckedTrue.length == 1) {
      //this.selectedUsergroupName = session;
      this.CountSelectedUserSession = this.userSessions[index].adUserName;
      this.isLogOffDisabled = false;
      this.isSendMsgDisabled = false;
    }
    else if (this.userSessionCheckedTrue.length > 1) {
      this.CountSelectedUserSession = this.selectedUserSessionsRows.length;
      this.isLogOffDisabled = false;
      this.isSendMsgDisabled = false;
    }
    else {
      this.userSessionCheckedTrue = [];
      this.isLogOffDisabled = true;
      this.isSendMsgDisabled = true;
    }
  }

  /*
   * This function is used to refresh appp users list
   */
  public RefreshAppUsersList() {
    this.refreshHostpoolLoading = true;
    this.GetAppGroupUsers();
    this.refreshHostpoolLoading = false;
  }

  /*
   * This function is used On change event validation for user principal name
   * ----------
   * parameters
   * value - Accepts event
   * ----------
   */
  public UserPrincipalNameChange(value) {
    if (value != "") {
      this.userprincipalButtonDisable = false;
    } else {
      this.userprincipalButtonDisable = true;

    }
  }

  /*
   * This function is used to open Add user modal Pop Up
   */
  public OpenAddUser() {
    this.showAddUserDialog = true;
    this.userprincipalButtonDisable = true;
    this.addUserForm = new FormGroup({
      // UserPrincipalName: new FormControl('', Validators.compose([Validators.required, Validators.pattern(/^[^\W\_]([\w]+?.[\w]+)@([\w]+?.[\w]+)\.([a-zA-Z]{2,5})$/)])),
      UserPrincipalName: new FormControl('', Validators.compose([Validators.required, Validators.pattern(/^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/)])),
    });
    this.userPrincipalName = false;
  }

  public OpenSendMessagePanel() {
    this.showSendMessageDialog = true;
    this.sendMesageButtonDisable = true;
    this.sendMessageForm = new FormGroup({
      Title: new FormControl('', Validators.compose([Validators.required])),
      Message: new FormControl('', Validators.compose([Validators.required])),
    });
    this.Title = false;
    this.Message = false;
  }

  public OpenRestartPanel() {
    this.showRestartDialog = true;
    //this.userprincipalButtonDisable = true;
    this.restartHostForm = new FormGroup({
      SubscriptionId: new FormControl('', Validators.compose([Validators.required])),
      ResourceGroup: new FormControl('', Validators.compose([Validators.required])),
    });

  }



  /*
   * This function is used to Close Add user modal Pop Up
   */
  public HideAppUserDialog() {
    this.showAddUserDialog = false;
  }

  /**
   * this function is used to close send message panel
   */
  public HideSendMessageDialog() {
    this.showSendMessageDialog = false;
  }



  /**
   * send message
   */
  public SendMessage(formdata) {
    if ((formdata.Title == "" || formdata.Title == undefined || formdata.Title == null) || (formdata.Message == "" || formdata.Message == undefined || formdata.Message == null)) {
      this.Title = formdata.Title == "" ? true : false;
      this.Message = formdata.Message == "" ? true : false;

    }
    else {
      for (let i = 0; i < this.selectedUserSessionsRows.length; i++) {
        var index = this.selectedUserSessionsRows[i];
        var objSendMessage = {
          "tenantGroupName": this.tenantGroupName,
          "tenantName": this.tenantName,
          "hostPoolName": this.hostPoolName,
          "sessionHostName": this.selectedHostName,
          "sessionId": this.userSessions[index].sessionId,
          "adUserName": this.userSessions[index].adUserName,
          "refresh_token": sessionStorage.getItem("Refresh_Token"),
          "messageTitle": formdata.Title,
          "messageBody": formdata.Message
        };
        this.SendMessageUrl = this._AppService.ApiUrl + '/api/UserSession/SendMessage';
        this._AppService.SendMessage(this.SendMessageUrl, objSendMessage).subscribe(response => {
          this.refreshHostpoolLoading = false;
          var responseData = JSON.parse(response['_body']);
          if (responseData.message == "Invalid Token") {
            sessionStorage.clear();
            this.router.navigate(['/invalidtokenmessage']);
          }
          /* If response data is success then it enters into if and this block of code will execute to show the ' Remote App Removed Successfully' notification */
          if (responseData.isSuccess === true) {
            this._notificationsService.html(
              '<i class="icon icon-check angular-Notify col-xs-1 no-pad"></i>' +
              '<label class="notify-label col-xs-10 no-pad"> Message Sent Successfully</label>' +
              '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
              '<p class="notify-text col-xs-12 no-pad">' + responseData.message + '</p>',
              'content optional one',
              {
                position: ["top", "right"],
                timeOut: 3000,
                showProgressBar: false,
                pauseOnHover: false,
                clickToClose: true,
                maxLength: 10
              }
            )
            AppComponent.GetNotification('icon icon-check angular-Notify', ' Message Sent Successfully', responseData.message, new Date());
            this.RefreshUserSessions();
          }
          /* If response data is success then it enters into else and this block of code will execute to show the 'Failed To Remove Remote App' notification */
          else {
            this._notificationsService.html(
              '<i class="icon icon-fail angular-NotifyFail col-xs-1 no-pad"></i>' +
              '<label class="notify-label col-xs-10 no-pad">Failed To send message</label>' +
              '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
              '<p class="notify-text col-xs-12 no-pad">' + responseData.message + '</p>',
              'content optional one',
              {
                position: ["top", "right"],
                timeOut: 3000,
                showProgressBar: false,
                pauseOnHover: false,
                clickToClose: true,
                maxLength: 10
              }
            )
            AppComponent.GetNotification('icon icon-fail angular-NotifyFail', 'Failed To send message', responseData.message, new Date());
            this.RefreshUserSessions();
          }
        },
          /*
           * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
           */
          (error) => {
            this._notificationsService.html(
              '<i class="icon icon-fail angular-NotifyFail col-xs-1 no-pad"></i>' +
              '<label class="notify-label col-xs-10 no-pad">Failed To send message</label>' +
              '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
              '<p class="notify-text col-xs-12 no-pad">Problem with server, Please try again</p>',
              'content optional one',
              {
                position: ["top", "right"],
                timeOut: 3000,
                showProgressBar: false,
                pauseOnHover: false,
                clickToClose: true,
                maxLength: 10
              }
            )
            AppComponent.GetNotification('icon icon-fail angular-NotifyFail', 'Failed To send message', 'Problem with server, Please try again', new Date());
            this.RefreshUserSessions();
          }
        );
      }
      this.checkedUserSessions = [];
      this.checkedMainUserSession = false;
      this.HideSendMessageDialog();
      this.Title = this.Message = false;
    }

  }


  /**Restart Host */
  public RestartHost() {
    var hostName = this.selectedHostName;
    let subscriptionId = this.hostDetails.subscriptionId != null ? this.hostDetails.subscriptionId : sessionStorage.getItem("SubscriptionId");
    this.RestartHostUrl = this._AppService.ApiUrl + '/api/SessionHost/RestartHost?subscriptionId=' + subscriptionId + '&resourceGroupName=' + this.hostDetails.resourceGroupName + '&sessionHostName=' + this.hostDetails.vmName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token");
    this._AppService.RestartHost(this.RestartHostUrl).subscribe(response => {
      this.refreshHostpoolLoading = false;
      var responseData = JSON.parse(response['_body']);
      if (responseData.message == "Invalid Token") {
        sessionStorage.clear();
        this.router.navigate(['/invalidtokenmessage']);
      }
      /* If response data is success then it enters into if and this block of code will execute to show the ' Remote App Removed Successfully' notification */
      if (responseData.isSuccess === true) {
        this._notificationsService.html(
          '<i class="icon icon-check angular-Notify col-xs-1 no-pad"></i>' +
          '<label class="notify-label col-xs-10 no-pad"> Host Restarted Successfully</label>' +
          '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
          '<p class="notify-text col-xs-12 no-pad">' + responseData.message + '</p>',
          'content optional one',
          {
            position: ["top", "right"],
            timeOut: 3000,
            showProgressBar: false,
            pauseOnHover: false,
            clickToClose: true,
            maxLength: 10
          }
        )
        AppComponent.GetNotification('icon icon-check angular-Notify', ' Host Restarted Successfully', responseData.message, new Date());
        this.RefreshHost();
      }
      /* If response data is success then it enters into else and this block of code will execute to show the 'Failed To Remove Remote App' notification */
      else {
        this._notificationsService.html(
          '<i class="icon icon-fail angular-NotifyFail col-xs-1 no-pad"></i>' +
          '<label class="notify-label col-xs-10 no-pad">Failed To Restart Host</label>' +
          '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
          '<p class="notify-text col-xs-12 no-pad">' + responseData.message + '</p>',
          'content optional one',
          {
            position: ["top", "right"],
            timeOut: 3000,
            showProgressBar: false,
            pauseOnHover: false,
            clickToClose: true,
            maxLength: 10
          }
        )
        AppComponent.GetNotification('icon icon-fail angular-NotifyFail', 'Failed To Restart Host', responseData.message, new Date());
        this.RefreshHost();
      }
    },
      /*
       * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
       */
      (error) => {
        this._notificationsService.html(
          '<i class="icon icon-fail angular-NotifyFail col-xs-1 no-pad"></i>' +
          '<label class="notify-label col-xs-10 no-pad">Failed To Restart Host</label>' +
          '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
          '<p class="notify-text col-xs-12 no-pad">Problem with server, Please try again</p>',
          'content optional one',
          {
            position: ["top", "right"],
            timeOut: 3000,
            showProgressBar: false,
            pauseOnHover: false,
            clickToClose: true,
            maxLength: 10
          }
        )
        AppComponent.GetNotification('icon icon-fail angular-NotifyFail', 'Failed To Restart Host', 'Problem with server, Please try again', new Date());
        this.RefreshHost();
      }
    );
    // this.HideRestartHostDialog();
  }


  /*
   * This function is used to Create\Add the Appgroup AppUser from Active directory
   * ----------
   * parameters
   * createNewActiveDrctryData - Accepts Add User Form Values
   * ----------
   */
  public CreateNewAppUser(createNewActiveDrctryData: any) {
    this.refreshHostpoolLoading = true;
    var AddUserdata = {
      tenantName: this.tenantName,
      hostPoolName: this.hostPoolName,
      appGroupName: this.AppgroupName,
      userPrincipalName: createNewActiveDrctryData.UserPrincipalName,
      refresh_token: sessionStorage.getItem("Refresh_Token"),
      tenantGroupName: this.tenantGroupName
    };
    this.addNewUser = this._AppService.ApiUrl + '/api/AppGroup/PostUsers';
    this._AppService.AddingUserstoAppGroup(this.addNewUser, AddUserdata).subscribe(response => {
      this.refreshHostpoolLoading = false;
      var responseData = JSON.parse(response['_body']);
      if (responseData.message == "Invalid Token") {
        sessionStorage.clear();
        this.router.navigate(['/invalidtokenmessage']);
      }
      /* If response data is success then it enters into if and this block of code will execute to show the 'User Added Successfully' notification */
      if (responseData.isSuccess === true) {
        this._notificationsService.html(
          '<i class="icon icon-check angular-Notify col-xs-1 no-pad"></i>' +
          '<label class="notify-label col-xs-10 no-pad">User Added Successfully</label>' +
          '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
          '<p class="notify-text col-xs-12 no-pad">' + responseData.message + '</p>',
          'content optional one',
          {
            position: ["top", "right"],
            timeOut: 3000,
            showProgressBar: false,
            pauseOnHover: false,
            clickToClose: true,
            maxLength: 10
          }
        )
        AppComponent.GetNotification('icon icon-check angular-Notify', 'User Added Successfully', responseData.message, new Date());
        this.HideAppUserDialog();
        this.RefreshUsers();
      }
      /* If response data is success then it enters into else and this block of code will execute to show the 'Failed To Add User' notification */
      else {
        this._notificationsService.html(
          '<i class="icon icon-fail angular-NotifyFail col-xs-1 no-pad"></i>' +
          '<label class="notify-label col-xs-10 no-pad">Failed To Add User</label>' +
          '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
          '<p class="notify-text col-xs-12 no-pad">' + responseData.message + '</p>',
          'content optional one',
          {
            position: ["top", "right"],
            timeOut: 3000,
            showProgressBar: false,
            pauseOnHover: false,
            clickToClose: true,
            maxLength: 10
          }
        )
        AppComponent.GetNotification('icon icon-fail angular-NotifyFail', 'Failed To Add User', responseData.message, new Date());
        this.HideAppUserDialog();
        this.RefreshUsers();
      }
    },
      /*
       * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
       */
      (error) => {
        let errorMsg = JSON.parse(error['_body']);
        this._notificationsService.html(
          '<i class="icon icon-fail angular-NotifyFail col-xs-1 no-pad"></i>' +
          '<label class="notify-label col-xs-10 no-pad">Failed To Add User</label>' +
          '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
          '<p class="notify-text col-xs-12 no-pad">Problem with server, Please try again</p>',
          'content optional one',
          {
            position: ["top", "right"],
            timeOut: 3000,
            showProgressBar: false,
            pauseOnHover: false,
            clickToClose: true,
            maxLength: 10
          }
        )
        AppComponent.GetNotification('icon icon-fail angular-NotifyFail', 'Failed To Add User', 'Problem with server, Please try again', new Date());
        this.HideAppUserDialog();
        this.RefreshUsers();
      }
    );
  }

  /*
   * This function is used to delete the selected Appgroup user
   */
  public DeleteAppUser() {
    this.refreshHostpoolLoading = true;
    for (let i = 0; i < this.selectedUsersRows.length; i++) {
      let index = this.selectedUsersRows[i];
      let selectedUserName = this.appUsersListSearch[index].userPrincipalName;
      this.usersDeleteUrl = this._AppService.ApiUrl + '/api/AppGroup/DeleteAssignedUser?tenantGroupName=' + this.tenantGroupName + '&tenantName=' + this.tenantName + '&hostPoolName=' + this.hostPoolName + '&appGroupName=' + this.selectedAppGroupName + '&appGroupUser=' + selectedUserName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token");
      this._AppService.DeleteUsersList(this.usersDeleteUrl).subscribe(response => {
        this.refreshHostpoolLoading = false;
        var responseData = JSON.parse(response['_body']);
        if (responseData.message == "Invalid Token") {
          sessionStorage.clear();
          this.router.navigate(['/invalidtokenmessage']);
        }
        /* If response data is success then it enters into if and this block of code will execute to show the 'User Removed Successfully' notification */
        if (responseData.isSuccess === true) {
          this._notificationsService.html(
            '<i class="icon icon-check angular-Notify col-xs-1 no-pad"></i>' +
            '<label class="notify-label col-xs-10 no-pad">User Removed Successfully</label>' +
            '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
            '<p class="notify-text col-xs-12 no-pad">' + responseData.message + '</p>',
            'content optional one',
            {
              position: ["top", "right"],
              timeOut: 3000,
              showProgressBar: false,
              pauseOnHover: false,
              clickToClose: true,
              maxLength: 10
            }
          )
          AppComponent.GetNotification('icon icon-check angular-Notify', 'User Removed Successfully', responseData.message, new Date());
          this.RefreshUsers();
        }
        /* If response data is success then it enters into else and this block of code will execute to show the 'Failed To Remove User' notification */
        else {
          this._notificationsService.html(
            '<i class="icon icon-fail angular-NotifyFail col-xs-1 no-pad"></i>' +
            '<label class="notify-label col-xs-10 no-pad">Failed To Remove User</label>' +
            '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
            '<p class="notify-text col-xs-12 no-pad">' + responseData.message + '</p>',
            'content optional one',
            {
              position: ["top", "right"],
              timeOut: 3000,
              showProgressBar: false,
              pauseOnHover: false,
              clickToClose: true,
              maxLength: 10
            }
          )
          AppComponent.GetNotification('icon icon-fail angular-NotifyFail', 'Failed To Remove User', responseData.message, new Date());
          this.RefreshUsers();
        }
      },
        /*
         * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
         */
        (error) => {
          this._notificationsService.html(
            '<i class="icon icon-fail angular-NotifyFail col-xs-1 no-pad"></i>' +
            '<label class="notify-label col-xs-10 no-pad">Failed To Remove User</label>' +
            '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
            '<p class="notify-text col-xs-12 no-pad">Problem with server, Please try again</p>',
            'content optional one',
            {
              position: ["top", "right"],
              timeOut: 3000,
              showProgressBar: false,
              pauseOnHover: false,
              clickToClose: true,
              maxLength: 10
            }
          )
          AppComponent.GetNotification('icon icon-fail angular-NotifyFail', 'Failed To Remove User', 'Problem with server, Please try again', new Date());
          this.RefreshUsers();
        }
      );
    }
  }

  /* This function is used to create an Apps array of current page numbers */
  public appsCounter(i: number) {
    return new Array(i);
  }

  /* This function is used to create an Users array of current page numbers */
  public usersCounter(i: number) {
    return new Array(i);
  }

  /* This function is used to  divide the number of pages based on Apps Count */
  public GetcurrentNoOfUsersPagesCount(counts: any) {
    let currentNoOfPagesCountCount = Math.floor(counts / this.pageSize);
    let remaingCount = counts % this.pageSize;
    if (remaingCount > 0) {
      this.currentNoOfUsersPagesCount = currentNoOfPagesCountCount + 1;
    }
    else {
      this.currentNoOfUsersPagesCount = currentNoOfPagesCountCount;
    }
    this.usersCurentIndex = 0;
  }

  /* This function is used to  divide the number of pages based on Users Count */
  public GetcurrentNoOfAppsPagesCount(counts: any) {
    let currentNoOfPagesCountCount = Math.floor(counts / this.pageSize);
    let remaingCount = counts % this.pageSize;
    if (remaingCount > 0) {
      this.currentNoOfAppsPagesCount = currentNoOfPagesCountCount + 1;
    }
    else {
      this.currentNoOfAppsPagesCount = currentNoOfPagesCountCount;
    }
    this.appsCurentIndex = 0;
  }

  /* This function is used to  loads all the tenants into table on click of Previous button in the table */
  // public appsPreviousPage() {
  //   this.checkedApps = [];
  //   this.checkedMainApp = false;
  //   this.appListErrorFound = false;
  //   this.refreshHostpoolLoading = true;
  //   this.appsLastEntry = this.appGroupAppList[0].remoteAppName;
  //   this.appsCurentIndex = this.appsCurentIndex - 1;
  //   this.getAppGroupAppsUrl = this._AppService.ApiUrl + '/api/RemoteApp/GetRemoteAppList?tenantGroupName=' + this.tenantGroupName + '&tenantName=' + this.tenantName + '&hostPoolName=' + this.hostPoolName + '&appGroupName=' + this.selectedAppGroupName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token") + '&pageSize=' + this.pageSize + '&sortField=RemoteAppName&isDescending=true&initialSkip=' + this.appsInitialSkip + '&lastEntry=' + this.appsLastEntry;
  //   this._AppService.GetData(this.getAppGroupAppsUrl).subscribe(response => {
  //     this.appsPreviousPageNo = this.appsCurrentPageNo;
  //     this.appsCurrentPageNo = this.appsCurrentPageNo - 1;
  //     this.appGroupAppList = JSON.parse(response['_body']);
  //     if (this.appGroupAppList) {
  //       if (this.appGroupAppList.code == "Invalid Token") {
  //         sessionStorage.clear();
  //         this.router.navigate(['/invalidtokenmessage']);
  //       }
  //     }
  //     this.appGroupsAppListSearch = JSON.parse(response['_body']);
  //     if (this.appGroupsAppListSearch.length == 0) {
  //       this.editedBodyApp = true;
  //     }
  //     else {
  //       if (this.appGroupsAppListSearch[0].Message == null) {
  //         this.editedBodyApp = false;
  //       }
  //       else if (this.appGroupsAppListSearch[0].Message == "Unauthorized") {
  //         sessionStorage.clear();
  //       }
  //     }
  //   },
  //     /*
  //      * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
  //      */
  //     (error) => {
  //       this.appListErrorFound = true;
  //       this.refreshHostpoolLoading = false;
  //     }
  //   );
  //   this.GetAppGroupUsers();
  // }

  /* This function is used to  loads all the tenants into table on click of Current page number values  in the table
    * ---------
   * Parameters
   * index - Accepts current index  count 
   * ---------
   */
  // public appsCurrentPage(index) {
  //   this.appsPreviousPageNo = this.appsCurrentPageNo;
  //   this.appsCurrentPageNo = index + 1;
  //   this.appsCurentIndex = index;
  //   this.checkedApps = [];
  //   this.checkedMainApp = false;
  //   this.appListErrorFound = false;
  //   this.refreshHostpoolLoading = true;
  //   let diff = this.appsCurrentPageNo - this.appsPreviousPageNo;
  //   // to get intialskip
  //   if (this.appsCurrentPageNo >= this.appsPreviousPageNo) {
  //     this.appsIsDescending = false;
  //     this.pageSize = diff * this.pageSize;
  //     this.appsLastEntry = this.appGroupAppList[this.appGroupAppList.length - 1].remoteAppName;
  //   } else {
  //     this.appsIsDescending = true;
  //     this.appsLastEntry = this.appGroupAppList[0].remoteAppName;
  //   }
  //   this.getAppGroupAppsUrl = this._AppService.ApiUrl + '/api/RemoteApp/GetRemoteAppList?tenantGroupName=' + this.tenantGroupName + '&tenantName=' + this.tenantName + '&hostPoolName=' + this.hostPoolName + '&appGroupName=' + this.selectedAppGroupName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token") + '&pageSize=' + this.pageSize + '&sortField=RemoteAppName&isDescending=' + this.appsIsDescending + '&initialSkip=' + this.appsInitialSkip + '&lastEntry=' + this.appsLastEntry;
  //   this._AppService.GetData(this.getAppGroupAppsUrl).subscribe(response => {
  //     this.appGroupAppList = JSON.parse(response['_body']);
  //     if (this.appGroupAppList) {
  //       if (this.appGroupAppList.code == "Invalid Token") {
  //         sessionStorage.clear();
  //         this.router.navigate(['/invalidtokenmessage']);
  //       }
  //     }
  //     this.appGroupsAppListSearch = JSON.parse(response['_body']);
  //     if (this.appGroupsAppListSearch.length == 0) {
  //       this.editedBodyApp = true;
  //     }
  //     else {
  //       if (this.appGroupsAppListSearch[0].Message == null) {
  //         this.editedBodyApp = false;
  //       }
  //       else if (this.appGroupsAppListSearch[0].Message == "Unauthorized") {
  //         sessionStorage.clear();
  //       }
  //     }
  //   },
  //     /*
  //      * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
  //      */
  //     (error) => {
  //       this.appListErrorFound = true;
  //       this.refreshHostpoolLoading = false;
  //     }
  //   );
  //   this.GetAppGroupUsers();
  // }

  /* This function is used to  loads all the tenants into table on click of Next button in the table */
  // public appsNextPage() {
  //   this.checkedApps = [];
  //   this.checkedMainApp = false;
  //   this.appListErrorFound = false;
  //   this.refreshHostpoolLoading = true;
  //   this.appsLastEntry = this.appGroupAppList[this.appGroupAppList.length - 1].remoteAppName;
  //   this.appsCurentIndex = this.appsCurentIndex + 1;
  //   this.getAppGroupAppsUrl = this._AppService.ApiUrl + '/api/RemoteApp/GetRemoteAppList?tenantGroupName=' + this.tenantGroupName + '&tenantName=' + this.tenantName + '&hostPoolName=' + this.hostPoolName + '&appGroupName=' + this.selectedAppGroupName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token") + '&pageSize=' + this.pageSize + '&sortField=RemoteAppName&isDescending=false&initialSkip=' + this.appsInitialSkip + '&lastEntry=' + this.appsLastEntry;
  //   this._AppService.GetData(this.getAppGroupAppsUrl).subscribe(response => {
  //     this.appGroupAppList = JSON.parse(response['_body']);
  //     this.appsPreviousPageNo = this.appsCurrentPageNo;
  //     this.appsCurrentPageNo = this.appsCurrentPageNo + 1;
  //     if (this.appGroupAppList) {
  //       if (this.appGroupAppList.code == "Invalid Token") {
  //         sessionStorage.clear();
  //         this.router.navigate(['/invalidtokenmessage']);
  //       }
  //     }
  //     this.appGroupsAppListSearch = JSON.parse(response['_body']);
  //     if (this.appGroupsAppListSearch.length == 0) {
  //       this.editedBodyApp = true;
  //     }
  //     else {
  //       if (this.appGroupsAppListSearch[0].Message == null) {
  //         this.editedBodyApp = false;
  //       }
  //       else if (this.appGroupsAppListSearch[0].Message == "Unauthorized") {
  //         sessionStorage.clear();
  //       }
  //     }
  //   },
  //     /*
  //      * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
  //      */
  //     (error) => {
  //       this.appListErrorFound = true;
  //       this.refreshHostpoolLoading = false;
  //     }
  //   );
  //   this.GetAppGroupUsers();
  // };

  /*
   * This function is used to get All AppGroup RemoteApps
   */
  public GetAllAppGroupApps() {
    this.checkedApps = [];
    this.checkedMainApp = false;
    this.appListErrorFound = false;
    let Apps = JSON.parse(sessionStorage.getItem('Apps'));

    let selectedApproup = sessionStorage.getItem('SelectedAppGroup');
    if (sessionStorage.getItem('Apps') && Apps.length != 0 && Apps != null && selectedApproup == this.selectedAppGroupName) {
      this.appsCount = Apps.length;
      this.getapps()
    } else {
      this.checkedApps = [];
      this.checkedMainApp = false;
      this.appListErrorFound = false;
      this.refreshHostpoolLoading = true;
      //this.getAppGroupAppsUrl = this._AppService.ApiUrl + '/api/RemoteApp/GetRemoteAppList?tenantGroupName=' + this.tenantGroupName + '&tenantName=' + this.tenantName + '&hostPoolName=' + this.hostPoolName + '&appGroupName=' + this.selectedAppGroupName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token") + '&pageSize=' + this.pageSize + '&sortField=RemoteAppName&isDescending=false&initialSkip=' + this.appsInitialSkip + '&lastEntry=' + this.appsLastEntry;
      this.getAppGroupAppsUrl = this._AppService.ApiUrl + '/api/RemoteApp/GetRemoteAppList?tenantGroupName=' + this.tenantGroupName + '&tenantName=' + this.tenantName + '&hostPoolName=' + this.hostPoolName + '&appGroupName=' + this.selectedAppGroupName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token");//+ '&pageSize=' + this.pageSize + '&sortField=RemoteAppName&isDescending=false&initialSkip=' + this.appsInitialSkip + '&lastEntry=' + this.appsLastEntry;
      this._AppService.GetData(this.getAppGroupAppsUrl).subscribe(response => {
        this.refreshHostpoolLoading = false;
        if (response.status == 429) {
          this.error = true;
          this.errorMessage = response.statusText;
        }
        else {
          this.error = false;
          this.appGroupAppList = JSON.parse(response['_body']);
          this.appsCount = this.appGroupAppList.length;
          sessionStorage.setItem('Apps', JSON.stringify(this.appGroupAppList));
          sessionStorage.setItem('SelectedAppGroup', this.selectedAppGroupName);
          this.getapps();
        }
      },
        /*
         * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
         */
        (error) => {
          this.error = true;
          let errorBody = JSON.parse(error['_body']);
          this.errorMessage = errorBody.error.target;
          this.appListErrorFound = true;
          this.refreshHostpoolLoading = false;
        }
      );
    }
    this.isDeleteAppsDisabled = true;
    this.isEditAppsDisabled = true;
    this.GetAppGroupUsers();
  }


  public getapps() {
    let appGroupAppList = JSON.parse(sessionStorage.getItem('Apps'));
    if (this.appGroupAppList) {
      if (this.appGroupAppList.code == "Invalid Token") {
        sessionStorage.clear();
        this.router.navigate(['/invalidtokenmessage']);
      }
    }
    this.GetcurrentNoOfAppsPagesCount(this.appsCount);
    this.appGroupsAppListSearch = appGroupAppList;
    if (this.appGroupsAppListSearch.length == 0) {
      this.editedBodyApp = true;
    }
    else {
      if (this.appGroupsAppListSearch[0].Message == null) {
        this.editedBodyApp = false;
      }
      else if (this.appGroupsAppListSearch[0].Message == "Unauthorized") {
        sessionStorage.clear();
      }
    }
  }

  /*
   * This function is used to get All AppGroup RemoteApps from Gallery
   */
  public GetAllAppGroupAppsGallery() {
    this.galleryAppLoader = true;
    this.appGroupAppListGallery = [];
    //this.getAllAppGroupAppsGalleryUrl = this._AppService.ApiUrl + '/api/AppGroup/GetStartMenuAppsList?tenantGroupName=' + this.tenantGroupName + '&tenantName=' + this.tenantName + '&appGroupName=' + this.selectedAppGroupName + '&hostPoolName=' + this.hostPoolName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token") + '&pageSize=10&sortField=AppAlias&isDescending=false&initialSkip=0';
    this.getAllAppGroupAppsGalleryUrl = this._AppService.ApiUrl + '/api/AppGroup/GetStartMenuAppsList?tenantGroupName=' + this.tenantGroupName + '&tenantName=' + this.tenantName + '&appGroupName=' + this.selectedAppGroupName + '&hostPoolName=' + this.hostPoolName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token");// + '&pageSize=10&sortField=AppAlias&isDescending=false&initialSkip=0';
    this._AppService.GetData(this.getAllAppGroupAppsGalleryUrl).subscribe(response => {
      if (response.status == 429) {
        this.error = true;
        this.errorMessage = response.statusText;
      }
      else {
        this.error = false;
        this.GAppslist = false;
        this.appGroupAppListGallery = JSON.parse(response['_body']);
        if (this.appGroupAppListGallery) {
          if (this.appGroupAppListGallery.code == "Invalid Token") {
            sessionStorage.clear();
            this.router.navigate(['/invalidtokenmessage']);
          }
          else if (this.appGroupAppListGallery.length == 0) {
            this.GAppslist = true;
            this.appGalleryErrorFound = false;
          }
          else {
            this.GAppslist = false;
            this.appGalleryErrorFound = false;
          }
          this.galleryAppLoader = false;
        }
        this.refreshHostpoolLoading = false;
      }
    },
      /*
       * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
       */
      (error) => {
        this.error = true;
        let errorBody = JSON.parse(error['_body']);
        this.errorMessage = errorBody.error.target;
        this.galleryAppLoader = false;
        this.refreshHostpoolLoading = false;
        this.appGalleryErrorFound = true;
        this.GAppslist = false;
      }
    );
  }

  /*
   * This function is used to select all the single App(App from Gallery)
   * ----------
   * parameters
   * event -  Accepts Event
   * ----------
   */
  public GalleryAppCheckAll(event: any) {
    this.checkedMainGApp = !this.checkedMainGApp;
    this.gappCheckedTrue = [];
    /* If we check the checkbox then this block of code executes*/
    for (let i = 0; i < this.appGroupAppListGallery.length; i++) {
      if (event.target.checked) {
        this.checkedGApps[i] = true;
        this.newGAppAdd = false;
      }
      /* If we uncheck the checkbox then this block of code executes*/
      else {
        this.checkedGApps[i] = false;
        this.newGAppAdd = true;
      }
    }
    /* If we check the multiple checkboxes then this block of code executes*/
    this.checkedAllTrueGApps = [];
    for (let j = 0; j < this.checkedGApps.length; j++) {
      if (this.checkedGApps[j] == true) {
        this.checkedAllTrueGApps.push(this.checkedGApps[j]);
      }
    }
    this.selectedGAppRows = this.checkedAllTrueGApps;
  }

  /**
   * This function will calculate and return absolute index of gallery apps.
   * -------------------
   * @param indexOnPage - Accepts App Index from gallery Apps
   * -------------------
   */
  absoluteIndex(indexOnPage: number, pageSize: number, pageNo: number): number {
    return pageSize * (pageNo - 1) + indexOnPage;
  }

  /*
   * This function is used to Row click for AppGroup app list(From Gallery)
   * ----------
   * parameters
   * appGroupIndex -  Accepts App grom Grallery Index
   * ----------
   */
  public GalleryAppListRowClicked(appGroupIndex: any) {
    let index = appGroupIndex;
    this.GalleryAppIsChecked(appGroupIndex);
    this.gappCheckedTrue = [];
    this.selectedGAppRows = [];
    for (var i = 0; i < this.checkedGApps.length; i++) {
      if (this.checkedGApps[i] == true) {
        this.gappCheckedTrue.push(this.checkedGApps[i]);
      }
    }
    if (this.gappCheckedTrue.length >= 1) {
      for (var i = 0; i < this.checkedGApps.length; i++) {
        if (this.checkedGApps[i] == true) {
          this.selectedGAppRows.push(i);
          this.newGAppAdd = false;
        }
      }
    }
  }

  /*
   * This function is used to select the single App from Gallery
   * ----------
   * parameters
   * appGroupIndex -  Accepts App grom Grallery Index
   * ----------
   */
  public GalleryAppIsChecked(appGroupIndex: any) {
    this.checkedGApps[appGroupIndex] = !this.checkedGApps[appGroupIndex];
    this.gappCheckedTrue = [];
    for (let i = 0; i < this.checkedGApps.length; i++) {
      if (this.checkedGApps[i] == false) {
        this.checkedMainGApp = false;
        this.newGAppAdd = true;
        break;
      }
      else {
        if (this.appGroupAppListGallery.length == this.gappCheckedTrue.length) {
          this.checkedMainGApp = true;
          this.newGAppAdd = false;
        }
        this.newGAppAdd = false;
      }
    }
  }

  /*
   * This function is used to searched data from the Appgroup App list table
   * ----------
   * parameters
   * value -  Accepts search box input value
   * ----------
   */
  public GetSearchByAppList(value: any) {
    let _SearchPipe = new SearchPipe();
    this.appGroupsAppListSearch = _SearchPipe.transform(value, 'remoteAppName', 'appAlias', 'iconPath', this.appGroupAppList);
  }

  /*
   * This function is used to  Row click for AppGroup app list
   * ----------
   * parameters
   * remoteAppName -  Accepts Remote App Name from App
   * appInd - Accepts App index value
   * ----------
   */
  public AppListRowClicked(remoteAppName: any, appInd: any) {
    this.IsCheckedApp(appInd);

    this.isDeleteAppsDisabled = false;
    this.isEditAppsDisabled = false;

    this.selectedRemoteappName = '';
    this.appCheckedTrue = [];
    this.selectedAppRows = [];
    var index = null;
    for (var i = 0; i < this.checkedApps.length; i++) {
      if (this.checkedApps[i] == true) {
        this.appCheckedTrue.push(this.checkedApps[i]);
        this.selectedAppRows.push(i);
        index = i;
      }
    }
    if (this.appCheckedTrue.length == 1) {
      this.selectedRemoteappName = remoteAppName;
      this.deleteCountSelectedApp = this.appGroupsAppListSearch[index].remoteAppName;
      this.isDeleteAppsDisabled = false;
      this.isEditAppsDisabled = false;

      this.newAppEditGroup = new FormGroup({
        AppPath: new FormControl(this.appGroupsAppListSearch[index].filePath, Validators.compose([Validators.required])),
        Name: new FormControl(this.appGroupsAppListSearch[index].remoteAppName, Validators.compose([Validators.required, Validators.pattern(/^[^\s\W\_]([A-Za-z0-9\s])+$/)])),
        IconPath: new FormControl(this.appGroupsAppListSearch[index].iconPath),
        IconIndex: new FormControl(this.appGroupsAppListSearch[index].iconIndex),
        friendlyName: new FormControl(this.appGroupsAppListSearch[index].friendlyName),
        requiredCommandLine: new FormControl(this.appGroupsAppListSearch[index].requiredCommandLine)
      });

    } else if (this.appCheckedTrue.length > 1) {
      this.deleteCountSelectedApp = this.selectedAppRows.length;
      this.isDeleteAppsDisabled = false;
      this.isEditAppsDisabled = true;
    }
    else {
      this.isDeleteAppsDisabled = true;
      this.isEditAppsDisabled = true;
    }
  }

  /*
   * This function is used to select the single App
   * ----------
   * parameters
   * ind - Accepts App index value
   * ----------
   */
  public IsCheckedApp(ind: any) {
    this.checkedApps[ind] = !this.checkedApps[ind];
    this.appCheckedTrue = [];
    for (let i = 0; i < this.checkedApps.length; i++) {
      if (this.checkedApps[i] == true) {
        this.appCheckedTrue.push(this.checkedApps[i]);
      }
      if (this.checkedApps[i] == false) {
        this.checkedMainApp = false;
        break;
      }
      else {
        if (this.appGroupsAppListSearch.length == this.appCheckedTrue.length) {
          this.checkedMainApp = true;
        }
      }
    }
  }

  /*
   * This function is used to select all the single App(App from path)
   * ----------
   * parameters
   * event - Accepts event
   * ----------
   */
  public AppCheckAll(event: any) {
    this.selectedAppRows = [];
    this.checkedMainApp = !this.checkedMainApp;
    this.appCheckedTrue = [];
    /* If we check the checkbox then this block of code executes*/
    for (let i = 0; i < this.appGroupsAppListSearch.length; i++) {
      if (event.target.checked) {
        this.checkedApps[i] = true;
      }
      /* If we uncheck the checkbox then this block of code executes*/
      else {
        this.checkedApps[i] = false;
      }
    }
    /* If we check the multiple checkboxes then this block of code executes*/
    this.checkedAllTrueApps = [];
    for (let j = 0; j < this.checkedApps.length; j++) {
      var index = j;
      if (this.checkedApps[j] == true) {
        this.checkedAllTrueApps.push(this.checkedApps[j]);
        this.selectedAppRows.push(j);
      }
    }
    /*If the selected checkbox length>1 then this block of code executes to show the no of selected remoteapps(i.e; if we select multiple checkboxes) */
    if (this.checkedAllTrueApps.length >= 1) {
      /*If the selected checkbox length=1 then this block of code executes to show the selected remoteapp name */
      if (this.checkedAllTrueApps.length == 1) {
        this.isDeleteAppsDisabled = false;
        this.deleteCountSelectedApp = this.appGroupsAppListSearch[index].remoteAppName;
        this.newAppEditGroup = new FormGroup({
          AppPath: new FormControl(this.appGroupsAppListSearch[index].filePath, Validators.compose([Validators.required])),
          Name: new FormControl(this.appGroupsAppListSearch[index].remoteAppName, Validators.compose([Validators.required, Validators.pattern(/^[^\s\W\_]([A-Za-z0-9\s])+$/)])),
          IconPath: new FormControl(this.appGroupsAppListSearch[index].iconPath),
          IconIndex: new FormControl(this.appGroupsAppListSearch[index].iconIndex),
          friendlyName: new FormControl(this.appGroupsAppListSearch[index].friendlyName),
          requiredCommandLine: new FormControl(this.appGroupsAppListSearch[index].requiredCommandLine)
        });
      }
      else {
        this.isDeleteAppsDisabled = false;
        this.deleteCountSelectedApp = this.checkedAllTrueApps.length;
      }
    }
    else {
      this.isDeleteAppsDisabled = true;
    }
  }

  /*
   * This function is used to Closing Create\Add Apps from path  modal
   */
  public HideAppPathDialog() {
    this.showAddAppDialog = false;
  }

  public HideAppEditDialog() {
    this.showEditAppDialog = false;
  }



  /*
   * This function is used to Closing Create\Add Apps from Gallery  modal
   */
  public HideAppGalleryDialog() {
    this.showAddAppGalleryDialog = false;
  }


  /*
   * This function is used to open app from path popup
   */
  public OpenAddAppsFromPath(event) {
    event.preventDefault();
    this.showAddAppGalleryDialog = false;
    this.showAddAppDialog = true;
    this.newAppCreateGroup2 = new FormGroup({
      AppPath: new FormControl('', Validators.compose([Validators.required])),
      Name: new FormControl('', Validators.compose([Validators.required, Validators.pattern(/^[^\s\W\_]([A-Za-z0-9\s])+$/)])),
      IconPath: new FormControl('', Validators.compose([Validators.required])),
      IconIndex: new FormControl('', Validators.compose([Validators.required])),
      requiredCommandLine: new FormControl(''),
      friendlyName: new FormControl('')
    });
  }

  /*** Edit App */
  public OpenEditApp(event) {
    event.preventDefault();
    this.showAddAppGalleryDialog = false;
    this.showEditAppDialog = true;
    // this.newAppCreateGroup2 = new FormGroup({
    //   AppPath: new FormControl('', Validators.compose([Validators.required])),
    //   Name: new FormControl('', Validators.compose([Validators.required, Validators.pattern(/^[^\s\W\_]([A-Za-z0-9\s])+$/)])),
    //   IconPath: new FormControl('', Validators.compose([Validators.required])),
    //   IconIndex: new FormControl('', Validators.compose([Validators.required])),
    // });
  }



  /*
   * This function is used to open app from Gallery popup
   */
  public OpenAddAppsFromGallery() {
    this.pageNo = 1;
    this.showAddAppGalleryDialog = true;
    this.appGalleryErrorFound = false;
    this.gappCheckedTrue = [];
    this.selectedGAppRows = [];
    this.checkedGApps = [];
    this.newGAppAdd = true;
    this.GetAllAppGroupAppsGallery();
  }

  /*
   * This function is used to Create\Add Apps from path
   * ----------
   * Parameters
   * createAppGroupData - Accepts Add App from Path Form values
   * ----------
   */
  public CreatingAppFromPath(createAppGroupData: any) {
    this.refreshHostpoolLoading = true;
    var AppdataRds = {
      "tenantGroupName": this.tenantGroupName,
      "tenantName": this.tenantName,
      "hostPoolName": this.hostPoolName,
      "appGroupName": this.selectedAppGroupName,
      "remoteAppName": createAppGroupData.Name,
      "appAlias": createAppGroupData.Name,
      "filePath": createAppGroupData.AppPath,
      "commandLineSetting": 1,
      "description": null,
      "friendlyName": createAppGroupData.friendlyName,
      "iconIndex": createAppGroupData.IconIndex != null ? createAppGroupData.IconIndex : 0,
      "iconPath": createAppGroupData.IconPath,
      "requiredCommandLine": createAppGroupData.requiredCommandLine,
      "showInWebFeed": true,
      "refresh_token": sessionStorage.getItem("Refresh_Token"),

    };
    this.createappGroupApps = this._AppService.ApiUrl + '/api/RemoteApp/Post';
    this._AppService.CreateAppGroup(this.createappGroupApps, AppdataRds).subscribe(response => {
      this.refreshHostpoolLoading = false;
      var responseData = JSON.parse(response['_body']);
      if (responseData.message == "Invalid Token") {
        sessionStorage.clear();
        this.router.navigate(['/invalidtokenmessage']);
      }
      /* If response data is success then it enters into if and this block of code will execute to show the 'Remote App Published Successfully' notification */
      if (responseData.isSuccess === true) {
        this._notificationsService.html(
          '<i class="icon icon-check angular-Notify col-xs-1 no-pad"></i>' +
          '<label class="notify-label col-xs-10 no-pad">Remote App Published Successfully</label>' +
          '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
          '<p class="notify-text col-xs-12 no-pad">' + responseData.message + '</p>',
          'content optional one',
          {
            position: ["top", "right"],
            timeOut: 3000,
            showProgressBar: false,
            pauseOnHover: false,
            clickToClose: true,
            maxLength: 10
          }
        )
        AppComponent.GetNotification('icon icon-check angular-Notify', 'Remote App Published Successfully', responseData.message, new Date());
        this.HideAppPathDialog();
        this.RefreshApps();
      }
      /* If response data is success then it enters into else and this block of code will execute to show the 'Failed To Publish Remote App' notification */
      else {
        this._notificationsService.html(
          '<i class="icon icon-fail angular-NotifyFail col-xs-1 no-pad"></i>' +
          '<label class="notify-label col-xs-10 no-pad">Failed To Publish Remote App</label>' +
          '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
          '<p class="notify-text col-xs-12 no-pad">' + responseData.message + '</p>',
          'content optional one',
          {
            position: ["top", "right"],
            timeOut: 3000,
            showProgressBar: false,
            pauseOnHover: false,
            clickToClose: true,
            maxLength: 10
          }
        )
        AppComponent.GetNotification('icon icon-fail angular-NotifyFail', 'Failed To Publish Remote App', responseData.message, new Date());
        this.HideAppPathDialog();
        this.RefreshApps();
      }
    },
      /*
       * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
       */
      (error) => {
        this._notificationsService.html(
          '<i class="icon icon-fail angular-NotifyFail col-xs-1 no-pad"></i>' +
          '<label class="notify-label col-xs-10 no-pad">Failed To Publish Remote App</label>' +
          '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
          '<p class="notify-text col-xs-12 no-pad">Problem with server, Please try again</p>',
          'content optional one',
          {
            position: ["top", "right"],
            timeOut: 3000,
            showProgressBar: false,
            pauseOnHover: false,
            clickToClose: true,
            maxLength: 10
          }
        )
        AppComponent.GetNotification('icon icon-fail angular-NotifyFail', 'Failed To Publish Remote App', 'Problem with server, Please try again', new Date());
        this.HideAppPathDialog();
        this.RefreshApps();
      }
    );
  }

  public UpdateApp(data: any) {
    var updateArray = {
      "tenantGroupName": this.tenantGroupName,
      "tenantName": this.tenantName,
      "hostPoolName": this.hostPoolName,
      "appGroupName": this.selectedAppGroupName,
      "remoteAppName": data.Name,
      "friendlyName": data.friendlyName,
      "filePath": data.AppPath,
      "iconIndex": data.IconIndex != null ? data.IconIndex : 0,
      "iconPath": data.IconPath,
      "requiredCommandLine": data.requiredCommandLine,
      "refresh_token": sessionStorage.getItem("Refresh_Token"),
    };

    let updateRemoteAppUrl = this._AppService.ApiUrl + '/api/RemoteApp/Put';
    this._AppService.UpdateRemoteApp(updateRemoteAppUrl, updateArray).subscribe(response => {
      var responseData = JSON.parse(response['_body']);
      if (responseData.message == "Invalid Token") {
        sessionStorage.clear();
        this.router.navigate(['/invalidtokenmessage']);
      }
      /* If response data is success then it enters into if and this block of code will execute to show the 'Remote App Updated Successfully' notification */
      if (responseData.isSuccess === true) {
        this._notificationsService.html(
          '<i class="icon icon-check angular-Notify col-xs-1 no-pad"></i>' +
          '<label class="notify-label col-xs-10 no-pad">Remote App Updated Successfully</label>' +
          '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
          '<p class="notify-text col-xs-12 no-pad">' + responseData.message + '</p>',
          'content optional one',
          {
            position: ["top", "right"],
            timeOut: 3000,
            showProgressBar: false,
            pauseOnHover: false,
            clickToClose: true,
            maxLength: 10
          }
        )
        AppComponent.GetNotification('icon icon-check angular-Notify', 'Remote App Updated Successfully', responseData.message, new Date());
        this.HideAppEditDialog();
        this.RefreshApps();
      }
      /* If response data is success then it enters into else and this block of code will execute to show the 'Failed To Update Host' notification */
      else {
        this._notificationsService.html(
          '<i class="icon icon-fail angular-NotifyFail col-xs-1 no-pad"></i>' +
          '<label class="notify-label col-xs-10 no-pad">Failed To Update Remote App</label>' +
          '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
          '<p class="notify-text col-xs-12 no-pad">' + responseData.message + '</p>',
          'content optional one',
          {
            position: ["top", "right"],
            timeOut: 3000,
            showProgressBar: false,
            pauseOnHover: false,
            clickToClose: true,
            maxLength: 10
          }
        )
        AppComponent.GetNotification('icon icon-fail angular-NotifyFail', 'Failed To Update Remote App', responseData.message, new Date());
        this.HideAppEditDialog();
        this.RefreshHost();
      }
    },
      /*
       * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
       */
      (error) => {
        this._notificationsService.html(
          '<i class="icon icon-fail angular-NotifyFail col-xs-1 no-pad"></i>' +
          '<label class="notify-label col-xs-10 no-pad">Failed To Update Host</label>' +
          '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
          '<p class="notify-text col-xs-12 no-pad">Problem with server, Please try again</p>',
          'content optional one',
          {
            position: ["top", "right"],
            timeOut: 3000,
            showProgressBar: false,
            pauseOnHover: false,
            clickToClose: true,
            maxLength: 10
          }
        )
        AppComponent.GetNotification('icon icon-fail angular-NotifyFail', 'Failed To Update Host', 'Problem with server, Please try again', new Date());
        this.HideAppEditDialog();
        this.RefreshApps();
      }
    );
    this.sessionHostCheckedMain = false;
    this.sessionHostchecked = [];
  }

  HideAppGroupDetails() {
    this.showAppGroupDashBoard = false;
    this.sessionHostCheckedMain = false;
    this.sessionHostchecked = [];
  }

  HideHostDetails() {
    this.showHostDashBoard = false;
    this.checkedMainAppGroup = false;
    this.checked = [];
  }

  /*
   * This function is used to Create\Add Apps from Gallery
   */
  public CreatingAppFromGallery() {
    this.refreshHostpoolLoading = true;
    for (let i = 0; i < this.selectedGAppRows.length; i++) {
      let index = this.selectedGAppRows[i];
      var AppdataRds = {
        "tenantName": this.appGroupAppListGallery[index].tenantName,
        "hostPoolName": this.appGroupAppListGallery[index].hostPoolName,
        "appGroupName": this.appGroupAppListGallery[index].appGroupName,
        "remoteAppName": this.appGroupAppListGallery[index].appAlias,
        "appAlias": this.appGroupAppListGallery[index].appAlias,
        "filePath": this.appGroupAppListGallery[index].filePath,
        "commandLineSetting": 1,
        "description": null,
        "friendlyName": this.appGroupAppListGallery[index].friendlyName,
        "iconIndex": 0,
        "iconPath": null,
        "requiredCommandLine": null,
        "showInWebFeed": true,
        "refresh_token": sessionStorage.getItem("Refresh_Token"),
        "tenantGroupName": this.tenantGroupName,
      };
      this.createappGroupApps = this._AppService.ApiUrl + '/api/RemoteApp/Post';
      this._AppService.CreateAppGroup(this.createappGroupApps, AppdataRds).subscribe(response => {
        this.refreshHostpoolLoading = false;
        var responseData = JSON.parse(response['_body']);
        if (responseData.message == "Invalid Token") {
          sessionStorage.clear();
          this.router.navigate(['/invalidtokenmessage']);
        }
        /* If response data is success then it enters into if and this block of code will execute to show the 'Remote App Published Successfully' notification */
        if (responseData.isSuccess === true) {
          this._notificationsService.html(
            '<i class="icon icon-check angular-Notify col-xs-1 no-pad"></i>' +
            '<label class="notify-label col-xs-10 no-pad">Remote App Published Successfully</label>' +
            '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
            '<p class="notify-text col-xs-12 no-pad">' + responseData.message + '</p>',
            'content optional one',
            {
              position: ["top", "right"],
              timeOut: 3000,
              showProgressBar: false,
              pauseOnHover: false,
              clickToClose: true,
              maxLength: 10
            }
          )
          AppComponent.GetNotification('icon icon-check angular-Notify', 'Remote App Published Successfully', responseData.message, new Date());
          this.showAddAppGalleryDialog = false;
          this.refreshHostpoolLoading = false;
          this.RefreshApps();
        }
        /* If response data is success then it enters into else and this block of code will execute to show the 'Failed To Publish Remote App' notification */
        else {
          this._notificationsService.html(
            '<i class="icon icon-fail angular-NotifyFail col-xs-1 no-pad"></i>' +
            '<label class="notify-label col-xs-10 no-pad">Failed To Publish Remote App</label>' +
            '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
            '<p class="notify-text col-xs-12 no-pad">' + responseData.message + '</p>',
            'content optional one',
            {
              position: ["top", "right"],
              timeOut: 3000,
              showProgressBar: false,
              pauseOnHover: false,
              clickToClose: true,
              maxLength: 10
            }
          )
          AppComponent.GetNotification('icon icon-fail angular-NotifyFail', 'Failed To Publish Remote App', responseData.message, new Date());
          this.showAddAppGalleryDialog = false;
          this.RefreshApps();
        }
      },
        /*
         * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
         */
        (error) => {
          this._notificationsService.html(
            '<i class="icon icon-fail angular-NotifyFail col-xs-1 no-pad"></i>' +
            '<label class="notify-label col-xs-10 no-pad">Failed To Publish Remote App</label>' +
            '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
            '<p class="notify-text col-xs-12 no-pad">Problem with server, Please try again</p>',
            'content optional one',
            {
              position: ["top", "right"],
              timeOut: 3000,
              showProgressBar: false,
              pauseOnHover: false,
              clickToClose: true,
              maxLength: 10
            }
          )
          AppComponent.GetNotification('icon icon-fail angular-NotifyFail', 'Failed To Publish Remote App', 'Problem with server, Please try again', new Date());
          this.showAddAppGalleryDialog = false;
          this.refreshHostpoolLoading = false;
          this.RefreshApps();
        }
      );
    }
  }

  /*
   * This function is used to Delete/Unpublish the publish RemoteApp (Apps from path)
   */
  public DeleteRemoteapps() {
    this.refreshHostpoolLoading = true;
    for (let i = 0; i < this.selectedAppRows.length; i++) {
      var index = this.selectedAppRows[i];
      this.appGroupCreateUrl = this._AppService.ApiUrl + '/api/RemoteApp/Delete?tenantGroupName=' + this.tenantGroupName + '&tenantName=' + this.appGroupsAppListSearch[index].tenantName + '&hostPoolName=' + this.appGroupsAppListSearch[index].hostPoolName + '&appGroupName=' + this.appGroupsAppListSearch[index].appGroupName + '&remoteAppName=' + this.appGroupsAppListSearch[index].remoteAppName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token");
      this._AppService.RemoveRemoteApps(this.appGroupCreateUrl).subscribe(response => {
        this.refreshHostpoolLoading = false;
        var responseData = JSON.parse(response['_body']);
        if (responseData.message == "Invalid Token") {
          sessionStorage.clear();
          this.router.navigate(['/invalidtokenmessage']);
        }
        /* If response data is success then it enters into if and this block of code will execute to show the ' Remote App Removed Successfully' notification */
        if (responseData.isSuccess === true) {
          this._notificationsService.html(
            '<i class="icon icon-check angular-Notify col-xs-1 no-pad"></i>' +
            '<label class="notify-label col-xs-10 no-pad"> Remote App Removed Successfully</label>' +
            '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
            '<p class="notify-text col-xs-12 no-pad">' + responseData.message + '</p>',
            'content optional one',
            {
              position: ["top", "right"],
              timeOut: 3000,
              showProgressBar: false,
              pauseOnHover: false,
              clickToClose: true,
              maxLength: 10
            }
          )
          AppComponent.GetNotification('icon icon-check angular-Notify', ' Remote App Removed Successfully', responseData.message, new Date());
          this.RefreshApps();
        }
        /* If response data is success then it enters into else and this block of code will execute to show the 'Failed To Remove Remote App' notification */
        else {
          this._notificationsService.html(
            '<i class="icon icon-fail angular-NotifyFail col-xs-1 no-pad"></i>' +
            '<label class="notify-label col-xs-10 no-pad">Failed To Remove Remote App</label>' +
            '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
            '<p class="notify-text col-xs-12 no-pad">' + responseData.message + '</p>',
            'content optional one',
            {
              position: ["top", "right"],
              timeOut: 3000,
              showProgressBar: false,
              pauseOnHover: false,
              clickToClose: true,
              maxLength: 10
            }
          )
          AppComponent.GetNotification('icon icon-fail angular-NotifyFail', 'Failed To Remove Remote App', responseData.message, new Date());
          this.RefreshApps();
        }
      },
        /*
         * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
         */
        (error) => {
          this._notificationsService.html(
            '<i class="icon icon-fail angular-NotifyFail col-xs-1 no-pad"></i>' +
            '<label class="notify-label col-xs-10 no-pad">Failed To Remove Remote App</label>' +
            '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
            '<p class="notify-text col-xs-12 no-pad">Problem with server, Please try again</p>',
            'content optional one',
            {
              position: ["top", "right"],
              timeOut: 3000,
              showProgressBar: false,
              pauseOnHover: false,
              clickToClose: true,
              maxLength: 10
            }
          )
          AppComponent.GetNotification('icon icon-fail angular-NotifyFail', 'Failed To Remove Remote App', 'Problem with server, Please try again', new Date());
          this.RefreshApps();
        }
      );
    }
    this.checkedApps = [];
    this.checkedMainApp = false;
  }

  public LogOffUserSessions() {
    //this.refreshHostpoolLoading = true;
    for (let i = 0; i < this.selectedUserSessionsRows.length; i++) {
      var index = this.selectedUserSessionsRows[i];
      var objLogOff = {
        "tenantGroupName": this.tenantGroupName,
        "tenantName": this.tenantName,
        "hostPoolName": this.hostPoolName,
        "sessionHostName": this.selectedHostName,
        "sessionId": this.userSessions[index].sessionId,
        "adUserName": this.userSessions[index].adUserName,
        "refresh_token": sessionStorage.getItem("Refresh_Token")
      };
      this.userSessionLogOffUrl = this._AppService.ApiUrl + '/api/UserSession/LogOffUserSesion';
      this._AppService.UserSessionLogOff(this.userSessionLogOffUrl, objLogOff).subscribe(response => {
        this.refreshHostpoolLoading = false;
        var responseData = JSON.parse(response['_body']);
        if (responseData.message == "Invalid Token") {
          sessionStorage.clear();
          this.router.navigate(['/invalidtokenmessage']);
        }
        /* If response data is success then it enters into if and this block of code will execute to show the ' Remote App Removed Successfully' notification */
        if (responseData.isSuccess === true) {
          this._notificationsService.html(
            '<i class="icon icon-check angular-Notify col-xs-1 no-pad"></i>' +
            '<label class="notify-label col-xs-10 no-pad"> Session(s) Log Off Successfully</label>' +
            '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
            '<p class="notify-text col-xs-12 no-pad">' + responseData.message + '</p>',
            'content optional one',
            {
              position: ["top", "right"],
              timeOut: 3000,
              showProgressBar: false,
              pauseOnHover: false,
              clickToClose: true,
              maxLength: 10
            }
          )
          AppComponent.GetNotification('icon icon-check angular-Notify', ' Session(s) Log Off Successfully', responseData.message, new Date());
          this.RefreshUserSessions();
        }
        /* If response data is success then it enters into else and this block of code will execute to show the 'Failed To Remove Remote App' notification */
        else {
          this._notificationsService.html(
            '<i class="icon icon-fail angular-NotifyFail col-xs-1 no-pad"></i>' +
            '<label class="notify-label col-xs-10 no-pad">Failed To logoff session(s)</label>' +
            '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
            '<p class="notify-text col-xs-12 no-pad">' + responseData.message + '</p>',
            'content optional one',
            {
              position: ["top", "right"],
              timeOut: 3000,
              showProgressBar: false,
              pauseOnHover: false,
              clickToClose: true,
              maxLength: 10
            }
          )
          AppComponent.GetNotification('icon icon-fail angular-NotifyFail', 'Failed To logoff session(s)', responseData.message, new Date());
          this.RefreshUserSessions();
        }
      },
        /*
         * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
         */
        (error) => {
          this._notificationsService.html(
            '<i class="icon icon-fail angular-NotifyFail col-xs-1 no-pad"></i>' +
            '<label class="notify-label col-xs-10 no-pad">Failed To logoff session(s)</label>' +
            '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
            '<p class="notify-text col-xs-12 no-pad">Problem with server, Please try again</p>',
            'content optional one',
            {
              position: ["top", "right"],
              timeOut: 3000,
              showProgressBar: false,
              pauseOnHover: false,
              clickToClose: true,
              maxLength: 10
            }
          )
          AppComponent.GetNotification('icon icon-fail angular-NotifyFail', 'Failed To logoff session(s)', 'Problem with server, Please try again', new Date());
          this.RefreshUserSessions();
        }
      );
    }
    this.checkedUserSessions = [];
    this.checkedMainUserSession = false;
  }

  SetSelectedHost(index: number, hostName: string) {
    //sessionStorage.setItem("TenantName", TenantName);
    //sessionStorage.setItem("TenantNameIndex", index);
    // this.adminMenuComponent.SetSelectedTenant(index, TenantName);
    this.router.navigate(['/admin/hostDashboard/', hostName]);
    let data = [{
      name: hostName,
      type: 'Host',
      path: 'hostDashboard',
    }];
    BreadcrumComponent.GetCurrentPage(data);
  }
}