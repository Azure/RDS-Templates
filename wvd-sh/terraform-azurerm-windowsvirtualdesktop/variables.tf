variable "rdsh_count" {
  description = "**OPTIONAL**: Number of WVD machines to deploy"
  default     = 2
}

variable "host_pool_name" {
  description = "Name of the RDS host pool"
  default     = "Fin-APP01-HP02"
}

variable "vm_prefix" {
  description = "Prefix of the name of the WVD machine(s)"
  default = "tfvm"
}

variable "tenant_name" {
  description = "Name of the RDS tenant associated with the machines"
  default = "MTCWVD"
}

variable "local_admin_username" {
  description = "**OPTIONAL**: Name of the local admin account"
  default     = "rdshadm"
}

variable "registration_expiration_hours" {
  description = "**OPTIONAL**: The expiration time for registration in hours"
  default     = "48"
}

variable "domain_joined" {
  description = "**OPTIONAL**: Should the machine join a domain"
  default     = "true"
}

variable "domain_name" {
  description = "**OPTIONAL**: Name of the domain to join"
  default     = "M365x503951.onmicrosoft.com"
}

variable "domain_user_upn" {
  description = "**OPTIONAL**: UPN of the user to authenticate with the domain"
  default     = "demodomainjoin"
}

variable "domain_password" {
  description = "**OPTIONAL**: Password of the user to authenticate with the domain"
  default     = ""
}

variable "tenantLocation" {
  description = "**OPTIONAL**: Region in which the RDS tenant exists"
  default     = "westus"
}

variable "region" {
  description = "Region in which to deploy these resources"
  default     = "westus"
}

variable "resource_group_name" {
  description = "Name of the Resource Group in which to deploy these resources"
  default     = "WVD-Fin-APP01-HP02-TF"
}

variable "base_url" {
  description = "**OPTIONAL**: The URL in which the RDS components exist"
  default     = "https://raw.githubusercontent.com/Azure/RDS-Templates/master/wvd-templates"
}

variable "existing_tenant_group_name" {
  description = "**OPTIONAL**: Name of the existing tenant group"
  default     = "Default Tenant Group"
}

variable "host_pool_description" {
  description = "**OPTIONAL**: Description of the RDS host pool"
  default     = "Created through Terraform template"
}

variable "vm_size" {
  description = "**OPTIONAL**: Size of the machine to deploy"
  default     = "Standard_F2s"
}

variable "subnet_id" {
  description = "ID of the Subnet in which the machines will exist"
  default = "/subscriptions/9d191167-e723-4876-a390-f671aabeba73/resourceGroups/AADDS/providers/Microsoft.Network/virtualNetworks/aadds-vnet/subnets/aadds-subnet"
}

variable "RDBrokerURL" {
  description = "**OPTIONAL**: URL of the RD Broker"
  default     = "https://rdbroker.wvd.microsoft.com"
}

variable "tenant_app_id" {
  description = "ID of the tenant app"
  default     = "23dcffd9-2ae4-4b8f-8689-2149b3c7f345"
}

variable "tenant_app_password" {
  description = "Password of the tenant app"
  default     = "3eIbC6bFnazFG5LyvAiAXxIXx779HU25H856ybkIEDU="
}

variable "is_service_principal" {
  description = "**OPTIONAL**: Is a service principal used for RDS connection"
  default     = "true"
}

variable "aad_tenant_id" {
  description = "ID of the AD tenant"
  default     = "03382dc7-f7cd-4365-8bc8-fa14d253edf9"
}

variable "vm_image_id" {
  description = "**OPTIONAL**: ID of the custom image to use"
  default     = "/subscriptions/9d191167-e723-4876-a390-f671aabeba73/resourceGroups/Packer-Build/providers/Microsoft.Compute/images/Win10-1903-Build-2020-04-25-2206-Build91"
}

variable "vm_publisher" {
  description = "**OPTIONAL**: Publisher of the vm image"
  default     = "MicrosoftWindowsDesktop"
}

variable "vm_offer" {
  description = "**OPTIONAL**: Offer of the vm image"
  default     = "Windows-10"
}

variable "vm_sku" {
  description = "**OPTIONAL**: Sku of the vm image"
  default     = "rs5-evd"
}

variable "vm_version" {
  description = "**OPTIONAL**: Version of the vm image"
  default     = "latest"
}

variable "vm_timezone" {
  description = "The vm_timezone of the vms"
  default     = "pacific standard time"
}

variable "as_platform_update_domain_count" {
  description = "https://github.com/MicrosoftDocs/azure-docs/blob/master/includes/managed-disks-common-fault-domain-region-list.md"
  default     = 5
}

variable "as_platform_fault_domain_count" {
  description = "https://github.com/MicrosoftDocs/azure-docs/blob/master/includes/managed-disks-common-fault-domain-region-list.md"
  default     = 3
}

variable "log_analytics_workspace_id" {
  description = "Workspace ID of the Log Analytics Workspace to associate the VMs with"
  default     = "e70d1c19-b459-4b6e-a74e-488861a5ef6f"
}

variable "log_analytics_workspace_primary_shared_key" {
  description = "Primary Shared Key of the Log Analytics Workspace to associate the VMs with"
  default     = "4AR6J3wnrvATbOX6G8GSG7pDQKGuTI21TZbSyG87BVDXxq894ivDs3YYMEoVZbFgBYe4HovPxOaS44VWbv5O5w=="
}

variable "extension_bginfo" {
  description = "**OPTIONAL**: Should BGInfo be attached to all servers"
  default     = "true"
}

variable "extension_loganalytics" {
  description = "**OPTIONAL**: Should Log Analytics agent be attached to all servers"
  default     = "true"
}

variable "extension_custom_script" {
  description = "**OPTIONAL**: Should a custom script extension be run on all servers"
  default     = "false"
}

variable "extensions_custom_script_fileuris" {
  description = "**OPTIONAL**: File URIs to be consumed by the custom script extension"
  default     = [""]
}

variable "extensions_custom_command" {
  description = "**OPTIONAL**: Command for the custom script extension to run"
  default     = ""
}

variable "vm_storage_os_disk_size" {
  description = "**OPTIONAL**: The size of the OS disk"
  default     = "128"
}

variable "managed_disk_sizes" {
  description = "**OPTIONAL**: The sizes of the optional manged data disks"
  default     = [""]
}

variable "managed_disk_type" {
  description = "**OPTIONAL**: If a manged disks are attached this allows for choosing the type. The dafault value is Standard_LRS"
  default     = "Standard_LRS"
}
