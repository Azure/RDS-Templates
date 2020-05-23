
provider "azurerm" {
  version = "~>2.0"
  features {}
}

resource "random_string" "wvd-local-password" {
  count            = "${var.rdsh_count}"
  length           = 16
  special          = true
  min_special      = 2
  override_special = "*!@#?"
}

resource "azurerm_network_interface" "rdsh" {
  count                     = "${var.rdsh_count}"
  name                      = "${var.vm_prefix}-${count.index +1}-nic"
  location                  = "${var.region}"
  resource_group_name       = "${var.resource_group_name}"

  ip_configuration {
    name                          = "${var.vm_prefix}-${count.index +1}-nic-01"
    subnet_id                     = "${var.subnet_id}"
    private_ip_address_allocation = "dynamic"
  }

  tags = {
    BUC             = "${var.tagBUC}"
    SupportGroup    = "${var.tagSupportGroup}"
    AppGroupEmail   = "${var.tagAppGroupEmail}"
    EnvironmentType = "${var.tagEnvironmentType}"
    CustomerCRMID   = "${var.tagCustomerCRMID}"
  }
}

resource "azurerm_virtual_machine" "main" {
  count                 = "${var.rdsh_count}"
  name                  = "${var.vm_prefix}-${count.index + 1}"
  location              = "${var.region}"
  resource_group_name   = "${var.resource_group_name}"
  network_interface_ids = ["${azurerm_network_interface.rdsh.*.id[count.index]}"]
  vm_size               = "${var.vm_size}"
  availability_set_id   = "${azurerm_availability_set.main.id}"

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    id        = "${var.vm_image_id != "" ? var.vm_image_id : ""}"
    publisher = "${var.vm_image_id == "" ? var.vm_publisher : ""}"
    offer     = "${var.vm_image_id == "" ? var.vm_offer : ""}"
    sku       = "${var.vm_image_id == "" ? var.vm_sku : ""}"
    version   = "${var.vm_image_id == "" ? var.vm_version : ""}"
  }

  storage_os_disk {
    name              = "${lower(var.vm_prefix)}-${count.index +1}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
    disk_size_gb      = "${var.vm_storage_os_disk_size}"
  }

  os_profile {
    computer_name  = "${var.vm_prefix}-${count.index +1}"
    admin_username = "${var.local_admin_username}"
    admin_password = "${random_string.wvd-local-password.*.result[count.index]}"
  }

  os_profile_windows_config {
    provision_vm_agent        = true
    enable_automatic_upgrades = true
    timezone                  = "${var.vm_timezone}"
  }

  tags = {
    BUC               = "${var.tagBUC}"
    SupportGroup      = "${var.tagSupportGroup}"
    AppGroupEmail     = "${var.tagAppGroupEmail}"
    EnvironmentType   = "${var.tagEnvironmentType}"
    CustomerCRMID     = "${var.tagCustomerCRMID}"
    ExpirationDate    = "${var.tagExpirationDate}"
    Tier              = "${var.tagTier}"
    SolutionCentralID = "${var.tagSolutionCentralID}"
    SLA               = "${var.tagSLA}"
    Description       = "${var.tagDescription}"
  }
}

resource "azurerm_managed_disk" "managed_disk" {
  count                = "${var.managed_disk_sizes[0] != "" ? (var.rdsh_count * length(var.managed_disk_sizes)) : 0 }"
  name                 = "${var.vm_prefix}-${(count.index / length(var.managed_disk_sizes)) + 1}-disk-${(count.index % length(var.managed_disk_sizes)) + 1}"
  location             = "${var.region}"
  resource_group_name  = "${var.resource_group_name}"
  storage_account_type = "${var.managed_disk_type}"
  create_option        = "Empty"
  disk_size_gb         = "${var.managed_disk_sizes[count.index % length(var.managed_disk_sizes)]}"

  tags = {
    BUC             = "${var.tagBUC}"
    SupportGroup    = "${var.tagSupportGroup}"
    AppGroupEmail   = "${var.tagAppGroupEmail}"
    EnvironmentType = "${var.tagEnvironmentType}"
    CustomerCRMID   = "${var.tagCustomerCRMID}"
    NPI             = "${var.tagNPI}"
    ExpirationDate  = "${var.tagExpirationDate}"
    SLA             = "${var.tagSLA}"
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "managed_disk" {
  count              = "${var.managed_disk_sizes[0] != "" ? (var.rdsh_count * length(var.managed_disk_sizes)) : 0 }"
  managed_disk_id    = "${azurerm_managed_disk.managed_disk.*.id[count.index]}"
  virtual_machine_id = "${azurerm_virtual_machine.main.*.id[count.index / length(var.managed_disk_sizes)]}"
  lun                = "10"
  caching            = "ReadWrite"
}
