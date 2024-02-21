data "azurerm_resource_group" "resourcegroup" {
  name     = "${var.username}-k8s101-workshop"
}

resource "azurerm_virtual_network" "linuxvmnetwork" {
  name                = "linuxvm_network"
  address_space       = ["10.0.0.0/24"]
  location            = data.azurerm_resource_group.resourcegroup.location
  resource_group_name = data.azurerm_resource_group.resourcegroup.name
}

resource "azurerm_subnet" "protectedsubnet" {
  name                 = "protected_subnet"
  resource_group_name  = data.azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.linuxvmnetwork.name
  address_prefixes     = ["10.0.0.0/26"]
}

resource "azurerm_public_ip" "linuxpip" {
  count               = 2
  name                = "linuxvm-${count.index}"
  location            = data.azurerm_resource_group.resourcegroup.location
  resource_group_name = data.azurerm_resource_group.resourcegroup.name
  allocation_method   = "Static"
  domain_name_label   = "linuxvm-${count.index}"
}

resource "azurerm_network_interface" "nic" {
  count               = 2
  name                = "linuxvmnic-${count.index}"
  location            = data.azurerm_resource_group.resourcegroup.location
  resource_group_name = data.azurerm_resource_group.resourcegroup.name

  ip_configuration {
    name                          = "linuxvm-nic-ipconfig-${count.index}"
    subnet_id                     = azurerm_subnet.protectedsubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.linuxpip[count.index].id
  }
}

resource "azurerm_linux_virtual_machine" "linuxvm" {
  count                 = 2
  name                  = "linuxvm-${count.index}"
  resource_group_name   = data.azurerm_resource_group.resourcegroup.name
  location              = data.azurerm_resource_group.resourcegroup.location
  size                  = "Standard_B2s"
  admin_username        = "adminuser"
  admin_password        = "AdminPassword1234!"
  disable_password_authentication = false

  network_interface_ids = [azurerm_network_interface.nic[count.index].id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
}
