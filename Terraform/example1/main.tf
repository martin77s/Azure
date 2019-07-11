provider "azurerm" {}

data "azurerm_resource_group" "rg" {
  name = "TF-RG"
}

data "azurerm_virtual_network" "vnet" {
  name                = "TF-VNET"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"
}

data "azurerm_subnet" "subnet" {
  name                 = "TF-SUBNET"
  resource_group_name  = "${data.azurerm_resource_group.rg.name}"
  virtual_network_name = "${data.azurerm_virtual_network.vnet.name}"
}


resource "azurerm_resource_group" "rg" {
  name     = "${data.azurerm_resource_group.rg.name}"
  location = "${var.location}"

  tags = {
    environment = "Terraform Bootcamp"
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${data.azurerm_virtual_network.vnet.name}"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"
  address_space       = ["10.0.0.0/16"]

  tags = {
    Environment = "Terraform Bootcamp"
  }
}

resource "azurerm_subnet" "subnet" {
  name                 = "${data.azurerm_subnet.subnet.name}"
  resource_group_name  = "${data.azurerm_resource_group.rg.name}"
  virtual_network_name = "${data.azurerm_virtual_network.vnet.name}"
  address_prefix       = "10.0.1.0/24"
}

resource "azurerm_network_interface" "nic1" {
  name                = "${var.name}-NIC01"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"

  ip_configuration {
    name                          = "${var.name}-ipconfig"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "10.0.1.7"
  }
}

resource "azurerm_network_interface" "nic2" {
  name                = "${var.name}-NIC02"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"

  ip_configuration {
    name                          = "${var.name}-ipconfig"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "10.0.1.5"
    public_ip_address_id          = "${azurerm_public_ip.publicip.id}"
  }
}

resource "azurerm_virtual_machine" "vm1" {
  name                          = "${var.name}-VM01"
  location                      = "${azurerm_resource_group.rg.location}"
  resource_group_name           = "${data.azurerm_resource_group.rg.name}"
  network_interface_ids         = ["${azurerm_network_interface.nic1.id}"]
  vm_size                       = "${var.vmsize}"
  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.name}-01-OSDISK"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.name}-VM01"
    admin_username = "${var.rootuser}"
    admin_password = "${var.rootpassword}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    Environment = "Terraform Bootcamp"
  }
}

resource "azurerm_virtual_machine" "vm2" {
  name                          = "${var.name}-VM02"
  location                      = "${azurerm_resource_group.rg.location}"
  resource_group_name           = "${data.azurerm_resource_group.rg.name}"
  network_interface_ids         = ["${azurerm_network_interface.nic2.id}"]
  vm_size                       = "${var.vmsize}"
  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.name}-02-OSDISK"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.name}-VM02"
    admin_username = "${var.rootuser}"
    admin_password = "${var.rootpassword}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    Environment = "Terraform Bootcamp"
  }
}

resource "random_id" "storage_account" {
  byte_length = 8
}

resource "azurerm_storage_account" "strg" {
  name                    = "tfstrg${lower(random_id.storage_account.hex)}"
  location                 = "${azurerm_resource_group.rg.location}"
  resource_group_name      = "${data.azurerm_resource_group.rg.name}"

  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "Terraform Bootcamp"
  }
}

resource "azurerm_storage_container" "strg" {
  name                  = "vhds"
  resource_group_name   = "${data.azurerm_resource_group.rg.name}"
  storage_account_name  = "${azurerm_storage_account.strg.name}"
  container_access_type = "private"
}

resource "azurerm_public_ip" "publicip" {
  name                         = "${var.name}-PIP"
  location                     = "${var.location}"
  resource_group_name          = "${data.azurerm_resource_group.rg.name}"
  allocation_method            = "Dynamic"

  tags = {
    Environment = "Terraform Bootcamp"
  }
}
