resource "azurerm_virtual_machine_extension" "domainJoin" {
  count                      = "${var.domain_joined ? var.rdsh_count : 0}"
  name                       = "${var.vm_prefix}-${count.index +1}-domainJoin"
  virtual_machine_id         = "${azurerm_virtual_machine.main.*.id[count.index]}"
  publisher                  = "Microsoft.Compute"
  type                       = "JsonADDomainExtension"
  type_handler_version       = "1.3"
  auto_upgrade_minor_version = true

  lifecycle {
    ignore_changes = [
      "settings",
      "protected_settings",
    ]
  }

  settings = <<SETTINGS
    {
        "Name": "${var.domain_name}",
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

  tags = {
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
  virtual_machine_id         = "${azurerm_virtual_machine.main.*.id[count.index]}"
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.73"
  auto_upgrade_minor_version = true
  depends_on                 = ["azurerm_virtual_machine_extension.domainJoin"]

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

  tags = {
    BUC             = "${var.tagBUC}"
    SupportGroup    = "${var.tagSupportGroup}"
    AppGroupEmail   = "${var.tagAppGroupEmail}"
    EnvironmentType = "${var.tagEnvironmentType}"
    CustomerCRMID   = "${var.tagCustomerCRMID}"
  }
}
