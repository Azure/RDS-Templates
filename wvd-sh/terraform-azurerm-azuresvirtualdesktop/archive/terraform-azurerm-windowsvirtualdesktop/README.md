# AzureRM Windows Virtual Desktop

## Features

Deploys a new hostpool or modifies an existing hostpool of Azure Virtual Desktop Windows 10 machines

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
|resource_group_name|Name of the Resource Group in which to deploy these resources|String|-|Yes|
|region|Region in which to deploy these resources|String|-|Yes|
|rdsh_count|Number of WVD machines to deploy|Int|1|Only if deploying more than 1|
|host_pool_name|Name of the RDS host pool|String|-|Yes|
|vm_prefix|Prefix of the name of the WVD machine(s)|String|-|Yes|
|tenant_name|Name of the RDS tenant associated with the machines|String|-|Yes|
|local_admin_username|Name of the local admin account|String|rdshadm|No|
|registration_expiration_hours|The expiration time for registration in hours|String|48|No|
|domain_joined|Should the machine join a domain|String (Bool)|true|No|
|domain_name|Name of the domain to join|String|-|If `domain_joined` is set to `true`|
|domain_user_upn|UPN of the user to authenticate with the domain|String|-|If `domain_joined` is set to `true`|
|domain_password|Password of the user to authenticate with the domain|String|-|If `domain_joined` is set to `true`|
|tenantLocation|Region in which the RDS tenant exists|String|eastus|No|
|base_url|The URL in which the RDS components exist|String|<https://raw.githubusercontent.com/Azure/RDS-Templates/master/wvd-templates>|No|
|existing_tenant_group_name|Name of the existing tenant group|String|Default Tenant Group|No|
|host_pool_description|Description of the RDS host pool|String|Created through Terraform template|No|
|vm_size|Size of the machine to deploy|String|Standard_F2s|No|
|nsg_id|ID of the NSG to associate the network interface|String|-|No|
|subnet_id|ID of the Subnet in which the machines will exist|String|-|Yes|
|RDBrokerURL|URL of the RD Broker|String|<https://rdbroker.wvd.microsoft.com>|No|
|tenant_app_id|ID of the tenant app|String|-|Yes|
|tenant_app_password|Password of the tenant app|String|-|Yes|
|is_service_principal|Is a service principal used for RDS connection|String|true|No|
|aad_tenant_id|ID of the AD tenant|String|-|Yes|
|ou_path|OU path to us during domain join|String|-|Yes|
|vm_image_id|ID of the custom image to use|String|-|If no vm image attributes are set|
|vm_publisher|Publisher of the vm image|String|-|If `vm_image_id` is not set|
|vm_offer|Offer of the vm image|String|-|If `vm_image_id` is not set|
|vm_sku|Sku of the vm image|String|-|If `vm_image_id` is not set|
|vm_version|Version of the vm image|String|-|If `vm_image_id` is not set|
|vm_timezone|The timezone of the vms|String|-|Yes|
|as_platform_update_domain_count|<https://github.com/MicrosoftDocs/azure-docs/blob/master/includes/managed-disks-common-fault-domain-region-list.md>|Int|5|No|
|as_platform_fault_domain_count|<https://github.com/MicrosoftDocs/azure-docs/blob/master/includes/managed-disks-common-fault-domain-region-list.md>|Int|3|No|
|log_analytics_workspace_id|Workspace ID of the Log Analytics Workspace to associate the VMs with|String|-|Yes|
|log_analytics_workspace_primary_shared_key|Primary Shared Key of the Log Analytics Workspace to associate the VMs with|String|-|Yes|
|extension_bginfo|Should BGInfo be attached to all servers|String|true|No|
|extension_loganalytics|Should Log Analytics agent be attached to all servers|String|true|No|
|extension_custom_script|Should a custom script extension be run on all servers|String|false|No|
|extensions_custom_script_fileuris|File URIs to be consumed by the custom script extension|List (String)|-|If `extension_custom_script` is set to `true`|
|extensions_custom_command|Command for the custom script extension to run|String|-|If `extension_custom_script` is set to `true`|
|vm_storage_os_disk_size|The size of the OS disk|String|128|No|
|managed_disk_sizes|The sizes of the optional manged data disks|List (String)|-|No|
|managed_disk_type|The type of managed disk(s) to attach|String|Standard_LRS|No|

## Outputs

| Name | Description | Type |
|------|-------------|:----:|
|vm_ids|List of VM resource IDs that are created|List (String)|
|vm_names|List of VM names that are created|List (String)|
|vm-password|The password for the VM(s) created in the module (if multiple, one password is used for all)|String|
|vm_ip_addresses|List of VM's private IP addresses|List (String)|
