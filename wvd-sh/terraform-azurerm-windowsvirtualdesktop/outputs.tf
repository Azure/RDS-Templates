output "vm_ids" {
  value = "${azurerm_virtual_machine.main.*.id}"
}

output "vm_names" {
  value = "${azurerm_virtual_machine.main.*.name}"
}

output "vm-password" {
  value = "${random_string.wvd-local-password.*.result}"
}

output "vm_ip_addresses" {
  value = "${azurerm_network_interface.rdsh.*.private_ip_address}"
}

output "vm_count" {
  description = "The number of VMs created"
  value       = "${var.rdsh_count}"
}

output "nic_ids" {
  description = "List of NIC ids that are created"
  value       = "${azurerm_network_interface.rdsh.*.id}"
}

output "nic_names" {
  description = "List of NIC names that are created"
  value       = "${azurerm_network_interface.rdsh.*.name}"
}

output "nic_ip_config_names" {
  description = "List of NIC IP configuration names (1 per NIC)"
  value       = "${azurerm_network_interface.rdsh.*.ip_configuration.0.name}"
}
