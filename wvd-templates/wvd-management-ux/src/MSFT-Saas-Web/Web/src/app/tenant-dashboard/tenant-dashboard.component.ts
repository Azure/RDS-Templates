import { Component, OnInit, ViewChild, ElementRef } from '@angular/core';
import { FormGroup, FormControl, Validators } from '@angular/forms'; //This is for Model driven form
import { Router, ActivatedRoute } from '@angular/router';
import { Http, Headers } from '@angular/http';
import { AppService } from '../shared/app.service';
import { NotificationsService } from "angular2-notifications";
import { SearchPipe } from "../../assets/Pipes/Search.pipe";
import { AppComponent } from "../app.component";
import { BreadcrumComponent } from "../breadcrum/breadcrum.component";
import { AdminMenuComponent } from "../admin-menu/admin-menu.component";

@Component({
  selector: 'app-tenant-dashboard',
  templateUrl: './tenant-dashboard.component.html',
  styleUrls: ['./tenant-dashboard.component.css'],
  animations: []
})

export class TenantDashboardComponent implements OnInit {
  public previousPageNo: any = 1;
  public currentPageNo: any = 1;
  public nextPageNo: any = 1;
  public pageSize: any = 10;
  public tenantsCount: any = 0;
  public initialSkip: any = 0;
  public curentIndex: any = 0;
  public currentNoOfPagesCountHostpool: any = 1;
  public ListOfPages: any = [];
  public lastEntry: any = '';
  public listItems: any = 10;
  public scopeArray: any;
  public arcount: any = [];
  public isPrevious: boolean = false;
  public isNext: boolean = false;
  public hasError: boolean = false;
  public isDescending: boolean = false;
  public hostpoolsCount: any = 0;
  public listItem: any = 10;  // pagination
  public createHostpoolUniqueName: boolean = false;
  public hostpoolNextButtonDisable: boolean = true;
  public tenantInfo: any = {};
  public checkedAllTrue: any = [];
  public tenantName: any;
  public editedBody = false;
  public searchHostPools: any = [];
  public checkedMain: boolean;
  public checkedTrue: any = [];
  private sub: any;
  public refreshHostpoolLoading: any = false;
  private hostPoolsList: any;
  public hostUrl: any;
  public checked: any = [];
  public selectedRows: any = [];
  public selectedTenantName: any;
  public selectedHostpoolName: any;
  public getTenantDetailsUrl: any;
  public getHostpoolsUrl: any;
  public hostpoolDeleteUrl: any;
  public updateHostpoolUrl: any;
  public showCreateHostpool: any;
  public showHostpoolDialog: boolean = false;
  public isEditDisabled: boolean = true;
  public isDeleteDisabled: boolean = true;
  public hostpoollistErrorFound: boolean = false;
  public getTenantlistErrorFound: boolean = false;
  public nonpersistentChecked: any = 'checked';
  public nonPersistant: boolean = true;
  public PersistentChecked: any;
  public selectedHostpoolradio: any;
  public options: any = {
    timeOut: 2000,
    position: ["top", "right"]
  };
  public hostpoolForm;
  public hostpoolFormEdit;
  public showHostpoolTab2: boolean;
  public deleteCount: any;
  public isEnableUser: boolean;
  public refreshToken: any;
  public tenantGroupName: any;
  public errorMessage: string;
  public error: boolean = false;
  public Hostpoollist: number = 1;
  public searchByHostName: any;


  /*This  is used to close the edit modal popup*/
  @ViewChild('closeModal') closeModal: ElementRef;

  constructor(private _AppService: AppService, private http: Http, private route: ActivatedRoute,
    private _notificationsService: NotificationsService, private router: Router, private adminMenuComponent: AdminMenuComponent) {
  }

  /* This function is  called directly on page load */
  public ngOnInit() {
    this.tenantGroupName = localStorage.getItem("TenantGroupName");
    /*This block of code is used to get the Tenant Name from the Url paramter*/
    this.route.params.subscribe(params => {
      this.showCreateHostpool = false;
      this.editedBody = false;
      this.tenantInfo = {};
      this.adminMenuComponent.hostPoolList = [];
      this.tenantGroupName = this.tenantGroupName;
      this.refreshToken = sessionStorage.getItem("Refresh_Token");
      this.tenantName = params["tenantName"];
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

      var index = +sessionStorage.getItem("TenantNameIndex");
      this.adminMenuComponent.selectedTenant = index;
      this.adminMenuComponent.getTenantIndex(this.tenantName);
      this.scopeArray = sessionStorage.getItem("Scope").split(",");
      this.CheckHostpoolAccess(this.tenantName);
      BreadcrumComponent.GetCurrentPage(data);
    });
    this.adminMenuComponent.SetSelectedhostPool(null, '', '');
    this.refreshToken = sessionStorage.getItem("Refresh_Token");
    this.hostpoolForm = new FormGroup({
      hostPoolName: new FormControl('', Validators.compose([Validators.required, Validators.maxLength(36), Validators.pattern(/^[^\s\W\_]([A-Za-z0-9\s\-\_\.])+$/)])),
      friendlyName: new FormControl("", Validators.compose([Validators.required, Validators.pattern(/^[^\s\W\_]([A-Za-z0-9\s\.\-\_])+$/)])),
      description: new FormControl("", Validators.compose([Validators.required, Validators.pattern(/^[\dA-Za-z]+[\dA-Za-z\s\.\-\_\!\@\#\$\%\^\&\*\(\)\{\}\[\]\:\'\"\?\>\<\,\;\/\+\=\|]{0,1600}$/)])),
      IsPersistent: new FormControl("false")
    });
    this.hostpoolFormEdit = new FormGroup({
      hostPoolName: new FormControl('', Validators.compose([Validators.required, Validators.maxLength(36), Validators.pattern(/^[^\s\W\_]([A-Za-z0-9\s\-\_\.])+$/)])),
      friendlyName: new FormControl("", Validators.compose([Validators.required, Validators.pattern(/^[^\s\W\_]([A-Za-z0-9\s\.\-\_])+$/)])),
      description: new FormControl("", Validators.compose([Validators.required, Validators.pattern(/^[\dA-Za-z]+[\dA-Za-z\s\.\-\_\!\@\#\$\%\^\&\*\(\)\{\}\[\]\:\'\"\?\>\<\,\;\/\+\=\|]{0,1600}$/)])),
      diskPath: new FormControl("", Validators.compose([Validators.required, Validators.pattern(/^((\\|\\\\)[a-z A-Z]+)+((\\|\\\\)[a-z0-9A-Z]+)$/)])),
      enableUserProfileDisk: new FormControl(""),
      IsPersistent: new FormControl("false")
    });
  }

  /*
   * This Function is called on Component Load and it is used to check the Access level of Hostpool 
   */
  public CheckHostpoolAccess(tenantName) {
    if (this.scopeArray != null && this.scopeArray.length > 3) {
      this.hostPoolsList = [{
        "tenantName": this.scopeArray[1],
        "hostPoolName": this.scopeArray[2],
        "friendlyName": "",
        "description": "",
        "diskPath": "",
        "enableUserProfileDisk": "",
        "excludeFolderPath": "",
        "excludeFilePath": "",
        "includeFilePath": "",
        "includeFolderPath": "",
        "customRdpProperty": "",
        "maxSessionLimit": "",
        "persistent": "",
        "loadBalancerType": 1,
        "validationEnv": "",
        "ring": null
      }];
      this.searchHostPools = this.hostPoolsList;
      this.hostpoolsCount = this.hostPoolsList.length;
      sessionStorage.setItem('sideMenuHostpools', JSON.stringify(this.hostPoolsList));
      this.tenantInfo = {
        "tenantName": this.scopeArray[1]
      };
      this.adminMenuComponent.GetHostpools(this.scopeArray[1]);
    }
    else {
      this.GetHostpoolsList(tenantName);
    }
  }

  /* This function is used to show validation error messages  on change of Hostpool Name */
  public HostpoolNameChange(value) {
    if (value != "") {
      this.createHostpoolUniqueName = false;
      this.hostpoolNextButtonDisable = false;
    } else {
      this.createHostpoolUniqueName = true;
      this.hostpoolNextButtonDisable = true;
    }
  }

  /* This function is called on Click of Create Hostpool and  it clears the input fields and open the Create hostpool slide
     * --------------
    * Parameters
    * event - Accepts event
    * --------------
 */
  public openCreateHostpool(event: any) {
    this.createHostpoolUniqueName = false;
    this.hostpoolForm = new FormGroup({
      hostPoolName: new FormControl("", Validators.compose([Validators.required, Validators.maxLength(36), Validators.pattern(/^[^\s\W\_]([A-Za-z0-9\s\-\_\.])+$/)])),
      friendlyName: new FormControl("", Validators.compose([Validators.required, Validators.pattern(/^[^\s\W\_]([A-Za-z0-9\s\.\-\_])+$/)])),
      description: new FormControl("", Validators.compose([Validators.required, Validators.pattern(/^[\dA-Za-z]+[\dA-Za-z\s\.\-\_\!\@\#\$\%\^\&\*\(\)\{\}\[\]\:\'\"\?\>\<\,\;\/\+\=\|]{0,1600}$/)])),
    });
    event.preventDefault();
    this.showHostpoolDialog = true;
  }

  /* This function is used to  to close the create host pool slider
  * --------------
   * Parameters
   * event - Accepts event
   * --------------
*/
  public BtnCancel(event: any) {
    this.showHostpoolDialog = false;
  }

  /* This function is used to  to close the Edit hostpool modal popup */
  public hostpoolUpdateClose(): void {
    this.closeModal.nativeElement.click();
  }

  /* This function is used to close the create host pool slider
   * --------------
   * Parameters
   * event - Accepts event
   * --------------
   */
  public CreateHostPoolSlideClose(event: any) {
    this.hostpoolNextButtonDisable = true;
    event.preventDefault();
    this.BtnCancel(event);
    this.ShowPreviousTab();
  }

  /* This function is used to show next slider of create host pool modal */
  public ShowNextTab() {
    this.showHostpoolTab2 = true;
  }

  /* This function is used to show previous slider of create host pool modal */
  public ShowPreviousTab() {
    this.showHostpoolTab2 = false;
  }

  /* This function is used to load only the searched hostpool
    * --------------
   * Parameters
   * value -Accepts the searchbox text value
   * --------------
   */
  public GetSearchByHostName(value: any) {
    let _SearchPipe = new SearchPipe();
    this.searchHostPools = _SearchPipe.transform(value, 'hostPoolName', 'friendlyName', 'description', this.hostPoolsList);
  }

  /* This function is used to show validate radio buttons of Enable user profile disk
      * --------------
   * Parameters
   * event - Accepts event
   * --------------
   */
  public profileDiskChange(event: any) {
    if (event === 'Yes') {
      this.isEnableUser = true;
    }
    else {
      this.isEnableUser = false;
    }
  }

  /* This function is used to create an  array of current page numbers */
  public counter(i: number) {
    return new Array(i);
  }

  /* This function is used to  divide the number of pages based on Tenants Count */
  public GetcurrentNoOfPagesHostpoolsCount() {
    let cnt = Math.floor(this.hostpoolsCount / this.pageSize);
    let remaingCount = this.hostpoolsCount % this.pageSize;
    if (remaingCount > 0) {
      this.currentNoOfPagesCountHostpool = cnt + 1;
    }
    else {
      this.currentNoOfPagesCountHostpool = cnt;
    }
  }

  /* This function is used to  get the tenant details
    * --------------
   * Parameters
   * tenantName - Accepts the value of selected tenant name
   * --------------
   */
  public GetTenantDetails(tenantName: any) {
    let Tenants = JSON.parse(sessionStorage.getItem('Tenants'));
    let SelectedTenant = JSON.parse(sessionStorage.getItem('SelectedTenant'));
    // if(SelectedTenant!=null && SelectedTenant!=undefined)
    // {
    //   this.tenantInfo=SelectedTenant;
    // }
    // else
    // {
    //   let data = Tenants.filter(item => item.tenantName == tenantName);
    //   this.tenantInfo = data[0];
    // }

    // this.refreshHostpoolLoading = true;

    this.getTenantlistErrorFound = false;
    this.getTenantDetailsUrl = this._AppService.ApiUrl + '/api/Tenant/GetTenantDetails?tenantGroupName=' + this.tenantGroupName + '&tenantName=' + tenantName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token");
    this._AppService.GetTenantDetails(this.getTenantDetailsUrl).subscribe(response => {
      this.tenantInfo = JSON.parse(response['_body']);
      // this.hostpoolsCount = this.tenantInfo.noOfHostpool;
      this.GetcurrentNoOfPagesHostpoolsCount();
      if (this.tenantInfo) {
        if (this.tenantInfo.code == "Invalid Token") {
          sessionStorage.clear();
          this.router.navigate(['/invalidtokenmessage']);
        }
      }
      this.refreshHostpoolLoading = false;
    },
      /*
       * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
       */
      error => {
        this.refreshHostpoolLoading = false;
        this.getTenantlistErrorFound = false;
        let data = Tenants.filter(item => item.tenantName == tenantName);
        this.tenantInfo = data[0];
      }
    );
  }


  /*This function is used select all the hostpools in the table using checkbox
  * --------------
  * Parameters
  * event - Accepts event
  * --------------
  */
  public CheckAll(event: any) {
    this.checkedMain = !this.checkedMain;
    this.checkedTrue = [];
    this.checkedAllTrue = [];
    /* If we check the checkbox then this block of code executes*/
    for (let i = 0; i < this.searchHostPools.length; i++) {
      var index = i;
      if (event.target.checked) {
        this.checked[i] = true;
      }
      /* If we uncheck the checkbox then this block of code executes*/
      else {
        this.checked[i] = false;
      }
    }
    /* If we check the multiple checkboxes then this block of code executes*/
    for (let j = 0; j < this.checked.length; j++) {
      if (this.checked[j] == true) {
        this.checkedAllTrue.push(this.checked[j]);
        this.selectedRows.push(j);
      }
    }
    /*If the selected checkbox length=1 then this block of code executes to show the selected hostpool name */
    if (this.checkedAllTrue.length == 1) {
      this.isEditDisabled = false;
      this.isDeleteDisabled = false;
      this.deleteCount = this.searchHostPools[index].hostPoolName;
      this.hostpoolFormEdit = new FormGroup({
        hostPoolName: new FormControl(this.searchHostPools[index].hostPoolName),
        friendlyName: new FormControl(this.searchHostPools[index].friendlyName),
        description: new FormControl(this.searchHostPools[index].description),
        diskPath: new FormControl(this.searchHostPools[index].diskPath, Validators.compose([Validators.required, Validators.pattern(/^((\\|\\\\)[a-z A-Z]+)+((\\|\\\\)[a-z0-9A-Z]+)$/)])),
        enableUserProfileDisk: new FormControl(this.searchHostPools[index].enableUserProfileDisk),
      });
    }
    /*If the selected checkbox length>1 then this block of code executes to show the no of selected hostpools(i.e; if we select multiple checkboxes) */
    else if (this.checkedAllTrue.length > 1) {
      this.isEditDisabled = true;
      this.isDeleteDisabled = false;
      this.deleteCount = this.checkedAllTrue.length;
    }
    else {
      this.isEditDisabled = true;
      this.isDeleteDisabled = true;
    }
  }

  /* This function is used to  specified hostpool in the table using checkbox
   * --------------
   * Parameters
   * hInd - Accepts selected index value 
   * tenantName - Accepts value of checked tenantname
   * hostpoolName- Accepts value of checked hostpool name
   * --------------
  */
  public IsChecked(hInd: any, tenantName: any, hostpoolName: any) {
    this.selectedTenantName = tenantName;
    this.selectedHostpoolName = hostpoolName;
    this.checked[hInd] = !this.checked[hInd];
    this.checkedTrue = [];
    for (let i = 0; i < this.checked.length; i++) {
      if (this.checked[i] == true) {
        this.checkedTrue.push(this.checked[i]);
      }
      if (this.checked[i] == false) {
        this.checkedMain = false;
        break;
      }
      else {
        if (this.searchHostPools.length == this.checkedTrue.length) {
          this.checkedMain = true;
          break;
        }
      }
    }
  }

  /**
   * This function will calculate and return absolute index of gallery apps.
   * -------------------
   * @param indexOnPage - Accepts App Index from gallery Apps
   * -------------------
   */
  absoluteIndex(indexOnPage: number): number {
    return this.listItem * (this.Hostpoollist - 1) + indexOnPage;
  }

  /* This function that triggers on click of  Hostpool table row click
  * --------------
  * Parameters
  * hInd -  Accepts selected index value  rowclicked
  * tenantName - Accepts value of  tenantName rowclicked
  * hostpoolname- Accepts value of  hostpoolname rowclicked
  * --------------
  */
  public HostPoolRowClicked(hInd: any, tenantName: any, hostpoolname: any) {
    this.IsChecked(hInd, tenantName, hostpoolname);
    this.selectedTenantName = tenantName;
    this.checkedTrue = [];
    this.selectedRows = [];
    for (var i = 0; i < this.checked.length; i++) {
      if (this.checked[i] == true) {
        this.checkedTrue.push(this.checked[i]);
      }
    }
    if (this.checkedTrue.length >= 1) {
      for (var i = 0; i < this.checked.length; i++) {
        if (this.checked[i] == true) {
          this.selectedRows.push(i);
        }
      }
      if (this.checkedTrue.length == 1) {
        this.isEditDisabled = false;
        this.isDeleteDisabled = false;
        for (var i = 0; i < this.checked.length; i++) {
          if (this.checked[i] == true) {
            var index = i;
          }
        }
        this.hostpoolFormEdit = new FormGroup({
          hostPoolName: new FormControl(this.searchHostPools[index].hostPoolName, Validators.compose([Validators.required, Validators.maxLength(36), Validators.pattern(/^[^\s\W\_]([A-Za-z0-9\s\-\_\.])+$/)])),
          friendlyName: new FormControl(this.searchHostPools[index].friendlyName, Validators.compose([Validators.required, Validators.pattern(/^[^\s\W\_]([A-Za-z0-9\s\.\-\_])+$/)])),
          description: new FormControl(this.searchHostPools[index].description, Validators.compose([Validators.required, Validators.pattern(/^[\dA-Za-z]+[\dA-Za-z\s\.\-\_\!\@\#\$\%\^\&\*\(\)\{\}\[\]\:\'\"\?\>\<\,\;\/\+\=\|]{0,1600}$/)])),
          diskPath: new FormControl(this.searchHostPools[index].diskPath, Validators.compose([Validators.required, Validators.pattern(/^((\\|\\\\)[a-z A-Z]+)+((\\|\\\\)[a-z0-9A-Z]+)$/)])),
          enableUserProfileDisk: new FormControl(this.searchHostPools[index].enableUserProfileDisk),
        });
        this.deleteCount = this.searchHostPools[index].hostPoolName;
        if (this.searchHostPools[index].enableUserProfileDisk === 'Yes') {
          this.selectedHostpoolradio = true;
          this.isEnableUser = true;
        }
        else {
          this.selectedHostpoolradio = false;
          this.isEnableUser = false;
        }
      }
      else if (this.checkedTrue.length > 1) {
        this.isDeleteDisabled = false;
        this.isEditDisabled = true;
        this.deleteCount = this.checkedTrue.length;
      }
      else {
        this.isDeleteDisabled = true;
        this.isEditDisabled = true;
      }

    }
    else if (this.checkedTrue.length == this.searchHostPools.length) {
      this.checkedMain = true;
    }
    else if (this.checkedTrue.length < 1) {
      this.checkedTrue = [];
      this.selectedRows = [];
      this.isDeleteDisabled = true;
      this.isEditDisabled = true;
      this.deleteCount = this.checkedTrue.length;
      this.checkedMain = false;
    }
  }


  /*  Router Navigation on click of Hostpool Name in the table
  * --------------
  * Parameters
  * index - Accepts Hostpool Index value
  * tenantName - Accepts Tenant Name
  * hostpoolName - Accepts hostpoolName
  * --------------
  */
  public SetSelectedHostRoute(index: any, tenantName: any, hostpoolName: any) {
    this.adminMenuComponent.SetSelectedhostPool(index, tenantName, hostpoolName);

    let data = [{
      name: hostpoolName,
      type: 'Hostpool',
      path: 'hostpoolDashboard',
      TenantName: this.tenantName,
    }];
    BreadcrumComponent.GetCurrentPage(data);
    sessionStorage.setItem('selectedhostpoolname', hostpoolName);
    this.router.navigate(['/admin/hostpoolDashboard', hostpoolName]);
  }
  /* This function is used to create an  array of current page numbers */


  /* This function is used to  loads all the Hostpools into table on page load
   * ----------
   * parameters
   * tenantName - Accepts Tenant Name
   * ----------
   */
  // public previousPage() {
  //   this.refreshHostpoolLoading = true;
  //   this.hostpoollistErrorFound = false;
  //   this.lastEntry = this.searchHostPools[0].hostPoolName;
  //   this.curentIndex = this.curentIndex - 1;
  //   let headers = new Headers({ 'Accept': 'application/json', 'Access-Control-Allow-Origin': '*' });
  //   /*
  //    * This block of code is used to check the Access level of Tenant
  //    * Access level of Tenant block Start
  //    */
  //   if (this.scopeArray.length <= 2 || this.scopeArray.length > 3) {
  //     this.GetTenantDetails(this.tenantName);
  //   }
  //   else {
  //     this.tenantInfo = {
  //       'tenantName': this.scopeArray[1]
  //     };
  //   }
  //   /*
  //    * Access level of Tenant block End
  //    */
  //   this.getHostpoolsUrl = this._AppService.ApiUrl + '/api/HostPool/GetHostPoolList?tenantGroupName=' + this.tenantGroupName + '&tenantName=' + this.tenantName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token") + '&pageSize=' + this.pageSize + '&sortField=HostPoolName&isDescending=true&initialSkip=' + this.initialSkip + '&lastEntry=' + this.lastEntry;
  //   this._AppService.GetTenantDetails(this.getHostpoolsUrl).subscribe(response => {
  //     this.hostPoolsList = JSON.parse(response['_body']);
  //     this.previousPageNo = this.currentPageNo;
  //     this.currentPageNo = this.currentPageNo - 1;
  //     //this.hostpoolsCount = this.tenantInfo.noOfHostpool
  //     for (let i in this.hostPoolsList) {
  //       if (this.hostPoolsList[i].enableUserProfileDisk === true) {
  //         this.hostPoolsList[i].enableUserProfileDisk = 'Yes';
  //       }
  //       else {
  //         this.hostPoolsList[i].enableUserProfileDisk = 'No';
  //       }
  //     }
  //     if (this.hostPoolsList[0]) {
  //       if (this.hostPoolsList[0].code == "Invalid Token") {
  //         sessionStorage.clear();
  //         this.router.navigate(['/invalidtokenmessage']);
  //       }
  //     }
  //     this.searchHostPools = JSON.parse(response['_body']);
  //     for (let i in this.searchHostPools) {
  //       if (this.searchHostPools[i].enableUserProfileDisk === true) {
  //         this.searchHostPools[i].enableUserProfileDisk = 'Yes';
  //       }
  //       else {
  //         this.searchHostPools[i].enableUserProfileDisk = 'No';
  //       }
  //     }
  //     if (this.searchHostPools.length == 0) {
  //       this.editedBody = true;
  //       this.showCreateHostpool = true;
  //     }
  //     else {
  //       if (this.searchHostPools[0].Message == null) {
  //         this.editedBody = false;
  //       }

  //       this.showCreateHostpool = false;
  //     }
  //     this.refreshHostpoolLoading = false;
  //   },
  //     /*
  //      * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
  //      */
  //     error => {
  //       this.refreshHostpoolLoading = false;
  //       this.hostpoollistErrorFound = true;
  //     }
  //   );
  //   this.isEditDisabled = true;
  //   this.isDeleteDisabled = true;
  //   for (let i = 0; i < this.searchHostPools.length; i++) {
  //     this.checked[i] = false;
  //   }
  //   this.checkedMain = false;
  // }

  // public NextPage() {
  //   this.refreshHostpoolLoading = true;
  //   this.hostpoollistErrorFound = false;
  //   this.lastEntry = this.searchHostPools[this.searchHostPools.length - 1].hostPoolName;
  //   this.curentIndex = this.curentIndex + 1;
  //   /*
  //    * Access level of Tenant block End
  //    */
  //   this.getHostpoolsUrl = this._AppService.ApiUrl + '/api/HostPool/GetHostPoolList?tenantGroupName=' + this.tenantGroupName + '&tenantName=' + this.tenantName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token") + '&pageSize=' + this.pageSize + '&sortField=HostPoolName&isDescending=false&initialSkip=' + this.initialSkip + '&lastEntry=' + this.lastEntry;
  //   this._AppService.GetTenantDetails(this.getHostpoolsUrl).subscribe(response => {
  //     this.hostPoolsList = JSON.parse(response['_body']);
  //     this.previousPageNo = this.currentPageNo;
  //     this.currentPageNo = this.currentPageNo + 1;
  //     for (let i in this.hostPoolsList) {
  //       if (this.hostPoolsList[i].enableUserProfileDisk === true) {
  //         this.hostPoolsList[i].enableUserProfileDisk = 'Yes';
  //       }
  //       else {
  //         this.hostPoolsList[i].enableUserProfileDisk = 'No';
  //       }
  //     }
  //     if (this.hostPoolsList[0]) {
  //       if (this.hostPoolsList[0].code == "Invalid Token") {
  //         sessionStorage.clear();
  //         this.router.navigate(['/invalidtokenmessage']);
  //       }
  //     }
  //     this.searchHostPools = JSON.parse(response['_body']);
  //     for (let i in this.searchHostPools) {
  //       if (this.searchHostPools[i].enableUserProfileDisk === true) {
  //         this.searchHostPools[i].enableUserProfileDisk = 'Yes';
  //       }
  //       else {
  //         this.searchHostPools[i].enableUserProfileDisk = 'No';
  //       }
  //     }
  //     if (this.searchHostPools.length == 0) {
  //       this.editedBody = true;
  //       this.showCreateHostpool = true;
  //     }
  //     else {
  //       if (this.searchHostPools[0].Message == null) {
  //         this.editedBody = false;
  //       }

  //       this.showCreateHostpool = false;
  //     }
  //     this.refreshHostpoolLoading = false;
  //   },
  //     /*
  //      * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
  //      */
  //     error => {
  //       this.refreshHostpoolLoading = false;
  //       this.hostpoollistErrorFound = true;
  //     }
  //   );
  //   this.isEditDisabled = true;
  //   this.isDeleteDisabled = true;
  //   for (let i = 0; i < this.searchHostPools.length; i++) {
  //     this.checked[i] = false;
  //   }
  //   this.checkedMain = false;
  // }

  // public CurrentPage(index) {
  //   this.previousPageNo = this.currentPageNo;
  //   this.currentPageNo = index + 1;
  //   this.curentIndex = index;
  //   this.refreshHostpoolLoading = true;
  //   this.hostpoollistErrorFound = false;
  //   let diff = this.currentPageNo - this.previousPageNo;
  //   // to get intialskip
  //   if (this.currentPageNo >= this.previousPageNo) {
  //     this.isDescending = false;
  //     this.pageSize = diff * this.pageSize;
  //     this.lastEntry = this.searchHostPools[this.searchHostPools.length - 1].hostPoolName;
  //   } else {
  //     this.isDescending = true;
  //     this.lastEntry = this.searchHostPools[0].hostPoolName;
  //   }
  //   /*
  //    * Access level of Tenant block End
  //    */
  //   this.getHostpoolsUrl = this._AppService.ApiUrl + '/api/HostPool/GetHostPoolList?tenantGroupName=' + this.tenantGroupName + '&tenantName=' + this.tenantName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token") + '&pageSize=' + this.pageSize + ' &sortField=HostPoolName&isDescending=' + this.isDescending + '&initialSkip=' + this.initialSkip + '&lastEntry=' + this.lastEntry;
  //   this._AppService.GetTenantDetails(this.getHostpoolsUrl).subscribe(response => {
  //     this.hostPoolsList = JSON.parse(response['_body']);
  //     this.hostpoolsCount = this.tenantInfo.length;
  //     for (let i in this.hostPoolsList) {
  //       if (this.hostPoolsList[i].enableUserProfileDisk === true) {
  //         this.hostPoolsList[i].enableUserProfileDisk = 'Yes';
  //       }
  //       else {
  //         this.hostPoolsList[i].enableUserProfileDisk = 'No';
  //       }
  //     }
  //     if (this.hostPoolsList[0]) {
  //       if (this.hostPoolsList[0].code == "Invalid Token") {
  //         sessionStorage.clear();
  //         this.router.navigate(['/invalidtokenmessage']);
  //       }
  //     }
  //     this.searchHostPools = JSON.parse(response['_body']);
  //     for (let i in this.searchHostPools) {
  //       if (this.searchHostPools[i].enableUserProfileDisk === true) {
  //         this.searchHostPools[i].enableUserProfileDisk = 'Yes';
  //       }
  //       else {
  //         this.searchHostPools[i].enableUserProfileDisk = 'No';
  //       }
  //     }
  //     if (this.searchHostPools.length == 0) {
  //       this.editedBody = true;
  //       this.showCreateHostpool = true;
  //     }
  //     else {
  //       if (this.searchHostPools[0].Message == null) {
  //         this.editedBody = false;
  //       }
  //       this.showCreateHostpool = false;
  //     }
  //     this.refreshHostpoolLoading = false;
  //   },
  //     /*
  //      * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
  //      */
  //     error => {
  //       this.refreshHostpoolLoading = false;
  //       this.hostpoollistErrorFound = true;
  //     }
  //   );
  //   this.isEditDisabled = true;
  //   this.isDeleteDisabled = true;
  //   for (let i = 0; i < this.searchHostPools.length; i++) {
  //     this.checked[i] = false;
  //   }
  //   this.checkedMain = false;
  // }

  public GetHostpoolsList(tenantName: any) {
    this.adminMenuComponent.GetHostpools(tenantName);
    let headers = new Headers({ 'Accept': 'application/json', 'Access-Control-Allow-Origin': '*' });
    /*
     * This block of code is used to check the Access level of Tenant
     * Access level of Tenant block Start
     */
    if (this.scopeArray.length <= 2 || this.scopeArray.length > 3) {
      this.GetTenantDetails(tenantName);
    }
    else {
      this.tenantInfo = {
        'tenantName': this.scopeArray[1]
      };
    }
    let sideMenuhostpools = JSON.parse(sessionStorage.getItem('sideMenuHostpools'));
    let selectedTenant = sessionStorage.getItem('SelectedTenantName');
    if (sessionStorage.getItem('sideMenuHostpools') && sideMenuhostpools.length != 0 && sideMenuhostpools != null && selectedTenant == tenantName) {
      this.adminMenuComponent.GetAllTenants();
      this.adminMenuComponent.GetHostpools(tenantName);
      this.hostpoolsCount = sideMenuhostpools.length;
    } else {
      /*
       * Access level of Tenant block End
       */
      // this.getHostpoolsUrl = this._AppService.ApiUrl + '/api/HostPool/GetHostPoolList?tenantGroupName=' + this.tenantGroupName + '&tenantName=' + tenantName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token") + '&pageSize=100&sortField=HostPoolName&isDescending=false&initialSkip=0&lastEntry=""';
      this.getHostpoolsUrl = this._AppService.ApiUrl + '/api/HostPool/GetHostPoolList?tenantGroupName=' + this.tenantGroupName + '&tenantName=' + tenantName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token");
      this._AppService.GetTenantDetails(this.getHostpoolsUrl).subscribe(response => {
        if (response.status == 429) {
          this.error = true;
          this.errorMessage = response.statusText;
        }
        else {
          this.error = false;
          var list = JSON.parse(response['_body']);
          sessionStorage.setItem('sideMenuHostpools', JSON.stringify(list));
          sessionStorage.setItem('SelectedTenantName', tenantName);
          this.hostpoolsCount = list.length;
          this.adminMenuComponent.GetHostpools(tenantName);
        }
      },
        error => {
          this.error = true;
          let errorBody = JSON.parse(error['_body']);
          this.errorMessage = errorBody.error.target;
        }
      );
    }
    this.GetHostpools(tenantName);
  }

  public GetHostpools(tenantName: any) {
    this.refreshHostpoolLoading = true;
    this.hostpoollistErrorFound = false;
    let headers = new Headers({ 'Accept': 'application/json', 'Access-Control-Allow-Origin': '*' });
    /*
     * This block of code is used to check the Access level of Tenant
     * Access level of Tenant block Start
     */
    if (this.scopeArray.length <= 2 || this.scopeArray.length > 3) {
      this.GetTenantDetails(tenantName);
    }
    else {
      this.tenantInfo = {
        'tenantName': this.scopeArray[1]
      };
    }

    let hostpools = JSON.parse(sessionStorage.getItem('Hostpools'));
    let selectedTenant = sessionStorage.getItem('SelectedTenantName');
    if (sessionStorage.getItem('Hostpools') && hostpools.length != 0 && hostpools != null && selectedTenant == tenantName) {
      this.gettingHostpools();
    }
    else {
      /*
       * Access level of Tenant block End
       */
      // this.getHostpoolsUrl = this._AppService.ApiUrl + '/api/HostPool/GetHostPoolList?tenantGroupName=' + this.tenantGroupName + '&tenantName=' + tenantName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token") + '&pageSize=' + this.pageSize + '&sortField=HostPoolName&isDescending=false&initialSkip=' + this.initialSkip + ' &lastEntry=' + this.lastEntry;
      this.getHostpoolsUrl = this._AppService.ApiUrl + '/api/HostPool/GetHostPoolList?tenantGroupName=' + this.tenantGroupName + '&tenantName=' + tenantName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token");
      this._AppService.GetTenantDetails(this.getHostpoolsUrl).subscribe(response => {
        if (response.status == 429) {
          this.error = true;
          this.errorMessage = response.statusText;
        }
        else {
          this.error = false;
          this.hostPoolsList = JSON.parse(response['_body']);
          sessionStorage.setItem('Hostpools', JSON.stringify(this.hostPoolsList));
          sessionStorage.setItem('SelectedTenantName', tenantName);
          this.gettingHostpools();
        }
      },
        /*
         * If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte
         */
        error => {
          this.error = true;
          let errorBody = JSON.parse(error['_body']);
          this.errorMessage = errorBody.error.target;
          this.refreshHostpoolLoading = false;
          this.hostpoollistErrorFound = true;
        }
      );
    }
  }

  /* This function is used to check Hostpool Access and refresh the hostpools list */
  public RefreshHostpools() {
    this.hostPoolsList = [];
    this.searchHostPools = [];
    sessionStorage.removeItem('Hostpools');
    sessionStorage.removeItem('sideMenuHostpools');
    this.checked = [];
    this.checkedMain = false;
    this.CheckHostpoolAccess(this.tenantName);
  }

  gettingHostpools() {
    this.hostPoolsList = JSON.parse(sessionStorage.getItem('Hostpools'));
    for (let i in this.hostPoolsList) {
      if (this.hostPoolsList[i].enableUserProfileDisk === true) {
        this.hostPoolsList[i].enableUserProfileDisk = 'Yes';
      }
      else {
        this.hostPoolsList[i].enableUserProfileDisk = 'No';
      }
    }
    if (this.hostPoolsList[0]) {
      if (this.hostPoolsList[0].code == "Invalid Token") {
        sessionStorage.clear();
        this.router.navigate(['/invalidtokenmessage']);
      }
    }
    this.searchHostPools = JSON.parse(sessionStorage.getItem('Hostpools'));

    for (let i in this.searchHostPools) {
      if (this.searchHostPools[i].enableUserProfileDisk === true) {
        this.searchHostPools[i].enableUserProfileDisk = 'Yes';
      }
      else {
        this.searchHostPools[i].enableUserProfileDisk = 'No';
      }
    }
    if (this.searchHostPools.length == 0) {
      this.editedBody = true;
      this.showCreateHostpool = true;
    }
    else {
      if (this.searchHostPools[0].Message == null) {
        this.editedBody = false;
      }

      this.showCreateHostpool = false;
    }
    this.refreshHostpoolLoading = false;
    this.isEditDisabled = true;
    this.isDeleteDisabled = true;
    for (let i = 0; i < this.searchHostPools.length; i++) {
      this.checked[i] = false;
    }
    this.checkedMain = false;
  }

  /* This function is used to  Create the New Hostpool
   * --------------
   * Parameters
   * hostpoolData -  Accepts hostpool Form Form Values
   * --------------
   */
  public CreateNewHostpool(hostpoolData) {
    let createHostpoolData = {
      tenantGroupName: this.tenantGroupName,
      tenantName: sessionStorage.getItem("TenantName"),
      hostPoolName: hostpoolData.hostPoolName.trim(),
      friendlyName: hostpoolData.friendlyName.trim(),
      description: hostpoolData.description.trim(),
      persistent: !this.nonPersistant,
      refresh_token: sessionStorage.getItem("Refresh_Token"),
    }
    this.refreshHostpoolLoading = true;
    this.hostUrl = this._AppService.ApiUrl + '/api/HostPool/Post';
    this._AppService.CreateHostpool(this.hostUrl, createHostpoolData).subscribe(response => {
      this.refreshHostpoolLoading = false;
      this.ShowPreviousTab();
      var responseData = JSON.parse(response['_body']);
      if (responseData.message == "Invalid Token") {
        sessionStorage.clear();
        this.router.navigate(['/invalidtokenmessage']);
      }
      /* If response data is success then it enters into if and this block of code will execute to show the 'Hostpool Created Successfully' notification */
      if (responseData.isSuccess === true) {
        this._notificationsService.html(
          '<i class="icon icon-check angular-Notify col-xs-1 no-pad"></i>' +
          '<label class="notify-label col-xs-10 no-pad">Host pool Created Successfully</label>' +
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
        AppComponent.GetNotification('icon icon-check angular-Notify', 'Host pool Created Successfully', responseData.message, new Date());
        this.RefreshHostpools();
        this.BtnCancel(event);
      }
      /* If response data is success then it enters into else and this block of code will execute to show the 'Failed To Create Hostpool' notification */
      else {
        this._notificationsService.html(
          '<i class="icon icon-fail angular-NotifyFail col-xs-1 no-pad"></i>' +
          '<label class="notify-label col-xs-10 no-pad">Failed To Create Host pool</label>' +
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
        AppComponent.GetNotification('icon icon-fail angular-NotifyFail', 'Failed To Create Host pool', responseData.message, new Date());
        //this.RefreshHostpools();
        this.BtnCancel(event);
      }
    },
      /* If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte */
      error => {
        this.refreshHostpoolLoading = false;
        this._notificationsService.html(
          '<i class="icon icon-close angular-NotifyFail"></i>' +
          '<label class="notify-label padleftright">Failed To Create Host pool</label>' +
          '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
          '<p class="notify-text">Problem with the service. Please try later</p>',
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
        AppComponent.GetNotification('fa fa-times-circle checkstyle', 'Failed To Create Host pool', 'Problem with the service. Please try later', new Date());
      }
    );
    this.hostpoolForm = new FormGroup({
      tenantName: new FormControl(this.tenantName),
      hostPoolName: new FormControl(""),
      friendlyName: new FormControl(""),
      description: new FormControl(""),
      IsPersistent: new FormControl("false")
    });
  }

  /* This function is used to  Update/Edit the selected Hostpool
    * --------------
    * Parameters
    * hostpoolData - Accepts  hostpool Edit Form values
    * --------------
   */
  public UpdateHostPool(hostpoolData: any) {
    var updateArray = {};
    if (hostpoolData.enableUserProfileDisk === 'Yes') {
      this.selectedHostpoolradio = true;
    }
    else {
      this.selectedHostpoolradio = false;
    }
    if (this.selectedHostpoolradio == true) {
      updateArray = {
        "refresh_token": sessionStorage.getItem("Refresh_Token"),
        "tenantGroupName": this.tenantGroupName,
        "tenantName": this.selectedTenantName,
        "hostPoolName": hostpoolData.hostPoolName,
        "diskPath": hostpoolData.diskPath,
        "enableUserProfileDisk": this.selectedHostpoolradio
      };
    }
    else {
      updateArray = {
        "refresh_token": sessionStorage.getItem("Refresh_Token"),
        "tenantGroupName": this.tenantGroupName,
        "tenantName": this.selectedTenantName.trim(),
        "hostPoolName": hostpoolData.hostPoolName.trim(),
        "friendlyName": hostpoolData.friendlyName.trim(),
        "description": hostpoolData.description.trim(),
        "enableUserProfileDisk": this.selectedHostpoolradio
      };
    }
    this.refreshHostpoolLoading = true;
    this.updateHostpoolUrl = this._AppService.ApiUrl + '/api/HostPool/Put';
    this._AppService.UpdateTenant(this.updateHostpoolUrl, updateArray).subscribe(response => {
      this.refreshHostpoolLoading = false;
      var responseData = JSON.parse(response['_body']);
      if (responseData.message == "Invalid Token") {
        sessionStorage.clear();
        this.router.navigate(['/invalidtokenmessage']);
      }
      /* If response data is success then it enters into if and this block of code will execute to show the 'Hostpool Updated Successfully' notification */
      if (responseData.isSuccess === true) {
        this._notificationsService.html(
          '<i class="icon icon-check angular-Notify col-xs-1 no-pad"></i>' +
          '<label class="notify-label col-xs-10 no-pad">Host pool Updated Successfully</label>' +
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
        AppComponent.GetNotification('icon icon-check angular-Notify', 'Host pool Updated Successfully', responseData.message, new Date());
        this.hostpoolUpdateClose();
        this.RefreshHostpools();
      }
      /* If response data is success then it enters into else and this block of code will execute to show the 'Failed To Update Hostpool' notification */
      else {
        this._notificationsService.html(
          '<i class="icon icon-fail angular-NotifyFail col-xs-1 no-pad"></i>' +
          '<label class="notify-label col-xs-10 no-pad">Failed To Update Host pool</label>' +
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
        AppComponent.GetNotification('icon icon-fail angular-NotifyFail', 'Failed To Update Host pool', responseData.message, new Date());
        this.hostpoolUpdateClose();
        //this.RefreshHostpools();
      }
    },
      /* If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte */
      error => {
        this.refreshHostpoolLoading = false;
        this._notificationsService.html(
          '<i class="icon icon-close angular-NotifyFail"></i>' +
          '<label class="notify-label padleftright">Failed To Update Host pool</label>' +
          '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
          '<p class="notify-text">Problem with the service. Please try later</p>',
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
        AppComponent.GetNotification('fa fa-times-circle checkstyle', 'Failed To Update Host pool', 'Problem with the service. Please try later', new Date());
      }
    );
  }

  /* This function is used to  delete the selected Hostpool */
  public DeleteHostpool() {
    this.refreshHostpoolLoading = true;
    for (let i = 0; i < this.selectedRows.length; i++) {
      let index = this.selectedRows[i];
      this.hostpoolDeleteUrl = this._AppService.ApiUrl + '/api/HostPool/Delete?tenantGroupName=' + this.tenantGroupName + '&tenantName=' + this.searchHostPools[index].tenantName + '&hostPoolName=' + this.searchHostPools[index].hostPoolName + '&refresh_token=' + sessionStorage.getItem("Refresh_Token");
      this._AppService.DeleteTenantService(this.hostpoolDeleteUrl).subscribe(response => {
        this.refreshHostpoolLoading = false;
        var responseData = JSON.parse(response['_body']);
        if (responseData.message == "Invalid Token") {
          sessionStorage.clear();
          this.router.navigate(['/invalidtokenmessage']);
        }
        /* If response data is success then it enters into if and this block of code will execute to show the 'Hostpool Deleted Successfully' notification */
        if (responseData.isSuccess === true) {
          this._notificationsService.html(
            '<i class="icon icon-check angular-Notify col-xs-1 no-pad"></i>' +
            '<label class="notify-label col-xs-10 no-pad">Host pool Deleted Successfully</label>' +
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
          AppComponent.GetNotification('icon icon-check angular-Notify', 'Host pool Deleted Successfully', responseData.message, new Date());
          this.RefreshHostpools();
        }
        /* If response data is success then it enters into else and this block of code will execute to show the 'Failed To Delete Hostpool' notification */
        else {
          this._notificationsService.html(
            '<i class="icon icon-fail angular-NotifyFail col-xs-1 no-pad"></i>' +
            '<label class="notify-label col-xs-10 no-pad">Failed To Delete Host pool</label>' +
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
          AppComponent.GetNotification('icon icon-fail angular-NotifyFail', 'Failed To Delete Host pool', responseData.message, new Date());
          //this.RefreshHostpools();
        }
      },
        /* If Any Error (or) Problem With Services (or) Problem in internet this Error Block Will Exequte */
        error => {
          this.refreshHostpoolLoading = false;
          this._notificationsService.html(
            '<i class="icon icon-close angular-NotifyFail"></i>' +
            '<label class="notify-label padleftright">Failed To Delete Host pool</label>' +
            '<a class="close"><i class="icon icon-close notify-close" aria-hidden="true"></i></a>' +
            '<p class="notify-text">Problem with the service. Please try later</p>',
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
          AppComponent.GetNotification('fa fa-times-circle checkstyle', 'Failed To Delete Host pool', 'Problem with the service. Please try later', new Date());
        }
      );
    }
  }
}
