resource "azurerm_virtual_machine_extension" "LogAnalytics" {
  count                      = "${var.extension_loganalytics ? var.rdsh_count : 0}"
  name                       = "${var.vm_prefix}${count.index +1}-LogAnalytics"
  location                   = "${var.region}"
  resource_group_name        = "${var.resource_group_name}"
  virtual_machine_name       = "${azurerm_virtual_machine.main.*.name[count.index]}"
  publisher                  = "Microsoft.EnterpriseCloud.Monitoring"
  type                       = "MicrosoftMonitoringAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
	{
	    "workspaceId": "${var.log_analytics_workspace_id}"
	}
SETTINGS

  protected_settings = <<protectedsettings
  {
      "workspaceKey": "${var.log_analytics_workspace_primary_shared_key}"
  }
protectedsettings

  tags {
    BUC             = "${var.tagBUC}"
    SupportGroup    = "${var.tagSupportGroup}"
    AppGroupEmail   = "${var.tagAppGroupEmail}"
    EnvironmentType = "${var.tagEnvironmentType}"
    CustomerCRMID   = "${var.tagCustomerCRMID}"
  }
}

resource "azurerm_virtual_machine_extension" "domainJoin" {
  count                      = "${var.domain_joined ? var.rdsh_count : 0}"
  name                       = "${var.vm_prefix}-${count.index +1}-domainJoin"
  location                   = "${var.region}"
  resource_group_name        = "${var.resource_group_name}"
  virtual_machine_name       = "${azurerm_virtual_machine.main.*.name[count.index]}"
  publisher                  = "Microsoft.Compute"
  type                       = "JsonADDomainExtension"
  type_handler_version       = "1.3"
  auto_upgrade_minor_version = true
  depends_on                 = ["azurerm_virtual_machine_extension.LogAnalytics"]

  lifecycle {
    ignore_changes = [
      "settings",
      "protected_settings",
    ]
  }

  settings = <<SETTINGS
    {
        "Name": "${var.domain_name}",
        "OUPath": "${var.ou_path}",
        "User": "${var.domain_user_upn}@${var.domain_name}",
        "Restart": "true",
        "Options": "3"
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
  {
         "Password": "${var.domain_password}"
  }
PROTECTED_SETTINGS

  tags {
    BUC             = "${var.tagBUC}"
    SupportGroup    = "${var.tagSupportGroup}"
    AppGroupEmail   = "${var.tagAppGroupEmail}"
    EnvironmentType = "${var.tagEnvironmentType}"
    CustomerCRMID   = "${var.tagCustomerCRMID}"
  }
}

resource "azurerm_virtual_machine_extension" "custom_script_extensions" {
  count                = "${var.extension_custom_script ? var.rdsh_count : 0}"
  name                 = "${var.vm_prefix}${count.index +1}-custom_script_extensions"
  location             = "${var.region}"
  resource_group_name  = "${var.resource_group_name}"
  virtual_machine_name = "${azurerm_virtual_machine.main.*.name[count.index]}"
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  depends_on           = ["azurerm_virtual_machine_extension.domainJoin"]
  type_handler_version = "1.9"

  lifecycle {
    ignore_changes = [
      "settings",
    ]
  }

  settings = <<SETTINGS
    {
      "fileUris": ["${join("\",\"", var.extensions_custom_script_fileuris)}"],
      "commandToExecute": "${var.extensions_custom_command}"
    }
SETTINGS

  tags {
    BUC             = "${var.tagBUC}"
    SupportGroup    = "${var.tagSupportGroup}"
    AppGroupEmail   = "${var.tagAppGroupEmail}"
    EnvironmentType = "${var.tagEnvironmentType}"
    CustomerCRMID   = "${var.tagCustomerCRMID}"
  }
}

resource "azurerm_virtual_machine_extension" "additional_session_host_dscextension" {
  count                      = "${var.rdsh_count}"
  name                       = "${var.vm_prefix}${count.index +1}-wvd_dsc"
  location                   = "${var.region}"
  resource_group_name        = "${var.resource_group_name}"
  virtual_machine_name       = "${azurerm_virtual_machine.main.*.name[count.index]}"
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.73"
  auto_upgrade_minor_version = true
  depends_on                 = ["azurerm_virtual_machine_extension.domainJoin", "azurerm_virtual_machine_extension.custom_script_extensions"]

  settings = <<SETTINGS
{
    "modulesURL": "${var.base_url}/DSC/Configuration.zip",
    "configurationFunction": "Configuration.ps1\\RegisterSessionHost",
     "properties": {
        "TenantAdminCredentials":{
            "userName":"${var.tenant_app_id}",
            "password":"PrivateSettingsRef:tenantAdminPassword"
        },
        "RDBrokerURL":"${var.RDBrokerURL}",
        "DefinedTenantGroupName":"${var.existing_tenant_group_name}",
        "TenantName":"${var.tenant_name}",
        "HostPoolName":"${var.host_pool_name}",
        "Hours":"${var.registration_expiration_hours}",
        "isServicePrincipal":"${var.is_service_principal}",
        "AadTenantId":"${var.aad_tenant_id}"
  }
}

SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
{
  "items":{
    "tenantAdminPassword":"${var.tenant_app_password}"
  }
}
PROTECTED_SETTINGS

  tags {
    BUC             = "${var.tagBUC}"
    SupportGroup    = "${var.tagSupportGroup}"
    AppGroupEmail   = "${var.tagAppGroupEmail}"
    EnvironmentType = "${var.tagEnvironmentType}"
    CustomerCRMID   = "${var.tagCustomerCRMID}"
  }
}
