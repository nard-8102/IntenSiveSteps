terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "Globant" {
  name     = "Globant-RG"
  location = "EastUS"
  tags = {
    enviroment = "DEV"
  }
}

resource "azurerm_virtual_network" "VN-Globant" {
  name                = "VN-01"
  resource_group_name = azurerm_resource_group.Globant.name
  location            = azurerm_resource_group.Globant.location
  address_space       = ["10.0.0.0/16"]
  tags = {
    "enviroment" = "DEV"
  }
}

resource "azurerm_subnet" "Globant_subnet" {
  name                 = "VN-Subnet-01"
  resource_group_name  = azurerm_resource_group.Globant.name
  virtual_network_name = azurerm_virtual_network.VN-Globant.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "Globant-NSG" {
  name                = "NSG-Globant"
  resource_group_name = azurerm_resource_group.Globant.name
  location            = azurerm_resource_group.Globant.location
  tags = {
    "enviroment" = "DEV"
  }
}

resource "azurerm_network_security_rule" "Globnat_NSG_Rule" {
  name                        = "NSG-Rule-01"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "22"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.Globant.name
  network_security_group_name = azurerm_network_security_group.Globant-NSG.name
}

resource "azurerm_subnet_network_security_group_association" "Globnant_NSG_Associate" {
  subnet_id                 = azurerm_subnet.Globant_subnet.id
  network_security_group_id = azurerm_network_security_group.Globant-NSG.id
}

resource "azurerm_public_ip" "Globant_PublicIP" {
  name                = "vm-ip-01"
  resource_group_name = azurerm_resource_group.Globant.name
  location            = azurerm_resource_group.Globant.location
  allocation_method   = "Dynamic"

  tags = {
    environment = "DEV"
  }
}

resource "azurerm_network_interface" "Interface_vm" {
  name                = "VM-NIC"
  location            = azurerm_resource_group.Globant.location
  resource_group_name = azurerm_resource_group.Globant.name

  ip_configuration {
    name                          = "Internal"
    subnet_id                     = azurerm_subnet.Globant_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.Globant_PublicIP.id
  }

  tags = {
    "envoriment" = "DEV"
  }
}

#SSH key nELSON81.-
#terraform.azurekeySSH - terraform.azurekeySSH.pub

resource "azurerm_linux_virtual_machine" "LinuxVM" {
  name                = "vm-linux-01"
  resource_group_name = azurerm_resource_group.Globant.name
  location            = azurerm_resource_group.Globant.location
  size                = "Standard_F2s_v2"
  admin_username      = "nard8102"
  network_interface_ids = [
    azurerm_network_interface.Interface_vm.id
  ]

   #custom_data = filebase64("customdata.tpl")

  admin_ssh_key {
    username   = "nard8102"
    public_key = file("TFlinuxSSH.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

data "azurerm_public_ip" "Globant-IP-Data" {
  name = azurerm_public_ip.Globant_PublicIP.name
  resource_group_name = azurerm_resource_group.Globant.name

}

output "public_ip_address" {
  value = "${azurerm_linux_virtual_machine.LinuxVM.name}: ${data.azurerm_public_ip.Globant-IP-Data.ip_address}"
}