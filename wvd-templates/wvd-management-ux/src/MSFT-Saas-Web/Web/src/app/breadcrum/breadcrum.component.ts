import { Component, OnInit, OnChanges } from '@angular/core';
import { Router } from "@angular/router";

@Component({
  selector: 'app-breadcrum',
  templateUrl: './breadcrum.component.html',
  styleUrls: ['./breadcrum.component.css']
})

export class BreadcrumComponent {
  static breadCrums: any = [];
  static dummy: any = [];
  constructor(private router: Router) { }

  /* This function is  called directly on page load */
  ngOnInit() {
  }

  /*This  Function  is used to  get navigation path
   * ----------
   * Parameters
   * path - Accepts path name
   * type - Accepts the type of the breadcrumb
   * index - Accepts the index value
   * bd - Accepts object contains details
   *----------
   */
  public Navigate(path: any, type: any, index: any, bc: any) {
    if (type === 'Tenants') {
      BreadcrumComponent.breadCrums['Tenant'].splice(index, 1);
      this.router.navigate(['/admin/Tenants']);
    }
    else if (type === 'Tenant') {
      BreadcrumComponent.breadCrums['Hostpool'].splice(index, 1);
      this.router.navigate(['/admin/tenantDashboard/', bc.name]);
    }
    else if (type === 'Hostpool') {
      this.router.navigate(['/admin/hostpoolDashboard/', bc.name]);
    }
  }

  /*This  Function  is used to  get gets current router path
   * ----------
   * Parameters
   * value - Accepts the details of Breadcrumb
   * ----------
   */
  static GetCurrentPage(value: any) {
    if (value[0].type == '') {
      delete BreadcrumComponent.breadCrums['Tenants']
      delete BreadcrumComponent.breadCrums['Tenant']
      delete BreadcrumComponent.breadCrums['Hostpool']
    }
    if (value[0].type == 'Tenants') {
      delete BreadcrumComponent.breadCrums['Tenant']
      delete BreadcrumComponent.breadCrums['Hostpool']
    }

    if (value[0].type == 'Tenant') {
      delete BreadcrumComponent.breadCrums['Hostpool']
    }
   
    BreadcrumComponent.breadCrums[value[0].type] = value;
    
  }

  /*
   * This  Function  is used to  get breadCrums List
   */
  get breadCrumsList() {
    return BreadcrumComponent.breadCrums;
  }
}
