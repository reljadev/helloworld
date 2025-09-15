# Configure the Azure provider
terraform {
  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~>1.5"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.9.0"
    }
  }

  required_version = ">= 1.1.0"

  backend "azurerm" {
    resource_group_name  = "terraform-state"
    storage_account_name = "tfstate31i2o312ad"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "HelloWorld"
  location = var.resource_group_location
}

# Network
resource "azurerm_virtual_network" "network" {
  name                = "hw_net"
  address_space       = ["10.0.0.0/24"] #TODO: smaller range
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "hw_subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes     = ["10.0.0.0/28"] 
}

resource "azurerm_public_ip" "public_ip" {
  name                = "hw_public_ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "nsg" {
  name                = "hw_nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1020
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTPS"
    priority                   = 1030
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}

resource "azurerm_network_interface" "nic" {
  name                = "hw_nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "nic_configuration"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# VM
resource "azurerm_linux_virtual_machine" "vm" {
  name                  = "hw_vm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  size                  = "Standard_B1ms"

  os_disk {
    name                 = "hw_os_disk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name  = "hwvm"
  admin_username = var.username

  admin_ssh_key {
    username   = var.username
    public_key = azapi_resource_action.ssh_public_key_gen.output.publicKey
  }
}

# SSH key storage
resource "random_pet" "kv_name" {
  prefix    = "kv"
  separator = ""
}

data "azurerm_client_config" "current" {}

output "object_id" {
  value = data.azurerm_client_config.current.object_id
}

resource "azurerm_key_vault" "hw_kv" {
  name                = random_pet.kv_name.id
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = ["Get", "Set"]
  }
}

resource "azurerm_key_vault_secret" "ssh_private_key" {
  name         = "ssh-private-key"
  value        = azapi_resource_action.ssh_public_key_gen.output.privateKey
  key_vault_id = azurerm_key_vault.hw_kv.id
}

# DNS
resource "azurerm_dns_zone" "zone" {
  name                = "demo.milanreljin.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_dns_a_record" "auth" {
  name                = "auth"
  zone_name           = azurerm_dns_zone.zone.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 300
  records             = [azurerm_public_ip.public_ip.ip_address]
}

resource "azurerm_dns_a_record" "site" {
  name                = "site"
  zone_name           = azurerm_dns_zone.zone.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 300
  records             = [azurerm_public_ip.public_ip.ip_address]
}