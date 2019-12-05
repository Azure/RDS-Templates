import { Injectable } from "@angular/core";
import { Http, RequestOptions, Headers } from "@angular/http";
import { Observable } from "rxjs";

@Injectable()
export class AppService {
  public ApiEndpoint: any;
  public ApiUrl: string;

  constructor(private http: Http) {
   //this.ApiUrl = "https://msftrdmisaasapi.azurewebsites.net";
    this.ApiUrl = "http://localhost:34816/";
  }

  /*
   * This Function is used to make Service call to delete tenant
   * ----------
   * Parameters
   * tenantDeleteurl - Accepts the Delete Tenant URL
   * ----------
   */
  public DeleteTenantService(tenantDeleteurl: any) {
    let headers = new Headers({ 'Accept': 'application/json', 'Authorization': sessionStorage.getItem('Code') });
    let options = new RequestOptions({ headers: headers });
    return this.http.delete(tenantDeleteurl, options)
      .catch((error: any) => Observable.throw(error));
  }

  /*
  * This Function is used to make Service call to get tenants list
  * ----------
  * Parameters
  * tenantDetailsList - Accepts the Get Tenant URL
  * ----------
  */
  public GetTenants(tenantDetailsList: any) {
    let headers = new Headers({ 'Accept': 'application/json' });
    let options = new RequestOptions({ headers: headers });
    return this.http.get(tenantDetailsList, options)
      .catch((error: any) => Observable.throw(error));
  }
  /*
* This Function is used to make Service call to get seleceted tenants details
* ----------
* Parameters
* tenantDetails - Accepts the Get Tenant URL
* ----------
*/
  public GetTenantDetails(tenantDetailsUrl: any) {
    let headers = new Headers({ 'Accept': 'application/json' });
    let options = new RequestOptions({ headers: headers });
    return this.http.get(tenantDetailsUrl, options)
      .catch((error: any) => Observable.throw(error));
  }

  /*
* This Function is used to make Service call to get hostpool list
* ----------
* Parameters
* hostpoolsList - Accepts the Get Hostpool URL
* ----------
*/
  public GetHostpools(hostpoolsList: any) {
    let headers = new Headers({ 'Accept': 'application/json', 'Access-Control-Allow-Origin': '*' });
    let options = new RequestOptions({ headers: headers });
    return this.http.get(hostpoolsList, options)
      .catch((error: any) => Observable.throw(error));
  }

  /*
 * This Function is used to make Service calls to get in hostpool dashboard
 * ----------
 * Parameters
 * url - Accepts the Get Hostpool URL
 * ----------
 */
  public GetData(url: any) {
    let headers = new Headers({ 'Accept': 'application/json' });
    let options = new RequestOptions({ headers: headers });
    return this.http.get(url, options)
      .catch((error: any) => Observable.throw(error));
  }

  /*
   * This Function is used to make Service call to delete session Host
   * ----------
   * Parameters
   * hostDeleteurl - Accepts the Delete Session Host URL
   * ----------
   */
  public DeleteHostService(hostDeleteurl: any) {
    let headers = new Headers({ 'Accept': 'application/json', 'Authorization': sessionStorage.getItem('Code') });
    let options = new RequestOptions({ headers: headers });
    return this.http.delete(hostDeleteurl, options)
      .catch((error: any) => Observable.throw(error));
  }

  /*
   * This Function is used to make Service call to create/Add tenant
   * ----------
   * Parameters
   * tenanturl - Accepts the Create Tenant URL
   * ----------
   */
  public CreateTenant(tenanturl: any, data) {
    let result = {
      "message": "success"
    }
    let headers = new Headers({ 'Content-Type': 'application/json;charset=utf8', 'Accept': 'application/json' });
    let options = new RequestOptions({ headers: headers });
    return this.http.post(tenanturl, JSON.stringify(data), options)
      .catch((error: any) => Observable.throw(error));
  }

  /*
   * This Function is used to make Service call to create/Add Session Host
   * ----------
   * Parameters
   * hosturl - Accepts the Create session Host URL
   * ----------
   */
  public CreateHostpool(hosturl: any, data) {
    let headers = new Headers({ 'Content-Type': 'application/json;charset=utf8', 'Accept': 'application/json' });
    let options = new RequestOptions({ headers: headers });
    return this.http.post(hosturl, JSON.stringify(data), options)
      .catch((error: any) => Observable.throw(error));
  }

  UserSessionLogOff(hosturl: any, data) {
    let headers = new Headers({ 'Content-Type': 'application/json;charset=utf8', 'Accept': 'application/json' });
    let options = new RequestOptions({ headers: headers });
    return this.http.post(hosturl, JSON.stringify(data), options)
      .catch((error: any) => Observable.throw(error));
  }

  SendMessage(hosturl: any, data) {
    let headers = new Headers({ 'Content-Type': 'application/json;charset=utf8', 'Accept': 'application/json' });
    let options = new RequestOptions({ headers: headers });
    return this.http.post(hosturl, JSON.stringify(data), options)
      .catch((error: any) => Observable.throw(error));
  }


  RestartHost(hosturl: any) {
    let headers = new Headers({ 'Content-Type': 'application/json;charset=utf8', 'Accept': 'application/json' });
    let options = new RequestOptions({ headers: headers });
    return this.http.post(hosturl, options)
      .catch((error: any) => Observable.throw(error));
  }

  ChangeDrainMode(hosturl: any, data) {
    let headers = new Headers({ 'Content-Type': 'application/json;charset=utf8', 'Accept': 'application/json' });
    let options = new RequestOptions({ headers: headers });
    return this.http.post(hosturl, JSON.stringify(data), options)
      .catch((error: any) => Observable.throw(error));
  }

  /*
   * This Function is used to make Service call to update/Edit Tenant
   * ----------
   * Parameters
   * updatetenanturl - Accepts the Update Tenant URL
   * ----------
   */
  public UpdateTenant(updatetenanturl: any, data) {
    let headers = new Headers({ 'Content-Type': 'application/json;charset=utf8', 'Accept': 'application/json' });
    let options = new RequestOptions({ headers: headers });
    return this.http.put(updatetenanturl, JSON.stringify(data), options)
      .catch((error: any) => Observable.throw(error));
  }

  /*
   * This Function is used to make Service call to update/Edit Appgroup
   * ----------
   * Parameters
   * updateappgroupurl - Accepts the Update App Group URL
   * ----------
   */
  public UpdateAppGroup(updateappgroupurl: any, data) {
    let headers = new Headers({ 'Content-Type': 'application/json;charset=utf8', 'Accept': 'application/json' });
    let options = new RequestOptions({ headers: headers });
    return this.http.put(updateappgroupurl, JSON.stringify(data), options)
      .catch((error: any) => Observable.throw(error));
  }

  /*
   * This Function is used to make Service call to update/Edit Session Host
   * ----------
   * Parameters
   * updateHosturl - Accepts the Update session Host URL
   * ----------
   */
  public UpdateHost(updateHosturl: any, data) {
    let headers = new Headers({ 'Content-Type': 'application/json;charset=utf8', 'Accept': 'application/json' });
    let options = new RequestOptions({ headers: headers });
    return this.http.put(updateHosturl, JSON.stringify(data), options)
      .catch((error: any) => Observable.throw(error));
  }

  /*
   * This Function is used to make Service call to Generate Key for Host
   * ----------
   * Parameters
   * generatekeyURL - Accepts the Generate Key URL
   * ----------
   */
  public GenerateKeyValue(generatekeyURL: any, data) {
    let headers = new Headers({ 'Content-Type': 'application/json;charset=utf8', 'Accept': 'application/json' });
    let options = new RequestOptions({ headers: headers });
    return this.http.post(generatekeyURL, JSON.stringify(data), options)
      .catch((error: any) => Observable.throw(error));
  }

  /*
   * This Function is used to make Service call to delete Appgroup
   * ----------
   * Parameters
   * AppGroupsDeleteurl - Accepts the Delete AppGroup URL
   * ----------
   */
  public DeleteAppGroupsList(AppGroupsDeleteurl: any) {
    let headers = new Headers({ 'Accept': 'application/json', 'Authorization': sessionStorage.getItem('access_token') });
    let options = new RequestOptions({ headers: headers });
    return this.http.delete(AppGroupsDeleteurl, options)
      .catch((error: any) => Observable.throw('Server error'));
  }

  /*
   * This Function is used to make Service call to create/Add Appgroup
   * ----------
   * Parameters
   * appGroupCreateurl - Accepts the Create App Group URL
   * ----------
   */
  public CreateTenantAppGroup(appGroupCreateurl: any, data) {
    let result = {
      "message": "success"
    }
    let headers = new Headers({ 'Content-Type': 'application/json;charset=utf8', 'Accept': 'application/json' });
    let options = new RequestOptions({ headers: headers });
    return this.http.post(appGroupCreateurl, JSON.stringify(data), options)
      .catch((error: any) => Observable.throw(error));
  }

  /*
   * This Function is used to make Service call to delete/Unpublish Appgroup RemoteApp
   * ----------
   * Parameters
   * appGroupDeleteurl - Accepts the Delete AppGroup Apps URL
   * ----------
   */
  public RemoveRemoteApps(appGroupDeleteurl: any) {
    let headers = new Headers({ 'Accept': 'application/json', 'Authorization': sessionStorage.getItem('access_token') });
    let options = new RequestOptions({ headers: headers });
    return this.http.delete(appGroupDeleteurl, options)
      .catch((error: any) => Observable.throw(error));
  }
/*
   * This Function is used to make Service call to update Appgroup RemoteApp
   * ----------
   * Parameters
   * remoteAppUpdateUrl - Accepts the Update AppGroup Remote App URL
   * ----------
   */
  public UpdateRemoteApp(remoteAppUpdateUrl:any,data)
  {
    let headers = new Headers({ 'Content-Type': 'application/json;charset=utf8', 'Accept': 'application/json' });
    let options = new RequestOptions({ headers: headers });
    return this.http.put(remoteAppUpdateUrl, JSON.stringify(data), options)
      .catch((error: any) => Observable.throw(error));
  }

  /*
   * This Function is used to make Service call to delete Appgroup Users
   * ----------
   * Parameters
   * UsersDeleteurl - Accepts the Delete AppGroup Users URL
   * ----------
   */
  public DeleteUsersList(UsersDeleteurl: any) {
    let headers = new Headers({ 'Accept': 'application/json', 'Authorization': sessionStorage.getItem('access_token') });
    let options = new RequestOptions({ headers: headers });
    return this.http.delete(UsersDeleteurl, options)
      .catch((error: any) => Observable.throw('Server error'));
  }

  /*
   * This Function is used to make Service call to create/Add Appgroup RemoteApp
   * ----------
   * Parameters
   * CreateappGroup - Accepts the Create AppGroup Apps URL
   * ----------
   */
  public CreateAppGroup(CreateappGroup: any, data) {
    let result = {
      "message": "success"
    }
    let headers = new Headers({ 'Content-Type': 'application/json;charset=utf8', 'Accept': 'application/json' });
    let options = new RequestOptions({ headers: headers });
    return this.http.post(CreateappGroup, JSON.stringify(data), options)
      .catch((error: any) => Observable.throw(error));
  }

  /*
   * This Function is used to make Service call to create/Add Appgroup Users
   * ----------
   * Parameters
   * CreateappGroup - Accepts the Create AppGroup Users URL
   * ----------
   */
  public AddingUserstoAppGroup(CreateappGroup: any, data) {
    let result = {
      "message": "success"
    }
    let headers = new Headers({ 'Content-Type': 'application/json;charset=utf8', 'Accept': 'application/json' });
    let options = new RequestOptions({ headers: headers });
    return this.http.post(CreateappGroup, JSON.stringify(data), options)
      .catch((error: any) => Observable.throw(error));
  }

  /*
   * This Function is used to make Service call to delete and Re-generate the already Generated Key
   * ----------
   * Parameters
   * regeneratekeyURL - Accepts the delete and Re-generate URL
   * ----------
   */
  public DeleteGeneratedHostKey(regeneratekeyURL: any) {
    let headers = new Headers({ 'Accept': 'application/json', 'Authorization': sessionStorage.getItem('access_token') });
    let options = new RequestOptions({ headers: headers });
    return this.http.delete(regeneratekeyURL, options)
      .catch((error: any) => Observable.throw('Server error'));
  }
}
