output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "public_ip_address" {
  value = azurerm_linux_virtual_machine.vm.public_ip_address
}

output "azure_nameservers" {
  value = azurerm_dns_zone.zone.name_servers
}

output "kv_name" {
  value = azurerm_key_vault.hw_kv.name
}

output "ssh_public_key" {
  value = azapi_resource_action.ssh_public_key_gen.output.publicKey
}

output "ssh_private_key" {
  value     = azapi_resource_action.ssh_public_key_gen.output.privateKey
  sensitive = true
}