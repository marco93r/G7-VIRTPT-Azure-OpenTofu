resource "azurerm_resource_group" "rg_main" {
  name     = "rg-main"
  location = var.location
}

resource "azurerm_virtual_network" "vnet_main" {
  name                = "vnet-main"
  resource_group_name = azurerm_resource_group.rg_main.name
  location            = var.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "snet_main" {
  name                 = "snet-main"
  resource_group_name  = azurerm_resource_group.rg_main.name
  virtual_network_name = azurerm_virtual_network.vnet_main.name
  address_prefixes     = ["10.0.1.0/24"]

  depends_on = [ azurerm_virtual_network.vnet_main ]
}

resource "azurerm_public_ip" "pip_vm_01" {
  name                = "pip-vm-ubuntu-01"
  resource_group_name = azurerm_resource_group.rg_main.name
  location            = var.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "nic_vm_01" {
  name                = "nic-vm-ubuntu-01"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_main.name
  

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.snet_main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.pip_vm_01.id
  }
}

resource "azurerm_linux_virtual_machine" "vm_01" {
  name                            = "vm-ubuntu-01"
  location                        = var.location
  resource_group_name             = azurerm_resource_group.rg_main.name
  size                            = var.size
  admin_username                  = "adminuser"
  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.nic_vm_01.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("./id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-snet-main"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_main.name

  security_rule {
    name                       = "ssh-allow"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id                 = azurerm_subnet.snet_main.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

output "pip_ip" {
  value = azurerm_public_ip.pip_vm_01
}