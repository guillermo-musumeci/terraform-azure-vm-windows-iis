#####################################
## Azure VM with IIS Module - Main ##
#####################################

# Generate random password
resource "random_password" "iis-vm-password" {
  length           = 16
  min_upper        = 2
  min_lower        = 2
  min_special      = 2
  number           = true
  special          = true
  override_special = "!@#$%&"
}

# Generate a random vm name
resource "random_string" "iis-vm-name" {
  length  = 8
  upper   = false
  number  = false
  lower   = true
  special = false
}

# Create Security Group to access IIS Server
resource "azurerm_network_security_group" "iis-vm-nsg" {
  depends_on=[azurerm_resource_group.network-rg]

  name                = "iis-${random_string.iis-vm-name.result}-nsg"
  location            = azurerm_resource_group.network-rg.location
  resource_group_name = azurerm_resource_group.network-rg.name

  security_rule {
    name                       = "AllowHTTP"
    description                = "Allow HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTPS"
    description                = "Allow HTTPS"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowRDP"
    description                = "Allow RDP"
    priority                   = 150
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
  tags = {
    environment = var.environment
  }
}

# Associate the Web NSG with the subnet
resource "azurerm_subnet_network_security_group_association" "iis-vm-nsg-association" {
  depends_on=[azurerm_resource_group.network-rg]

  subnet_id                 = azurerm_subnet.network-subnet.id
  network_security_group_id = azurerm_network_security_group.iis-vm-nsg.id
}

# Get a Static Public IP
resource "azurerm_public_ip" "iis-vm-ip" {
  depends_on=[azurerm_resource_group.network-rg]

  name                = "iis-${random_string.iis-vm-name.result}-ip"
  location            = azurerm_resource_group.network-rg.location
  resource_group_name = azurerm_resource_group.network-rg.name
  allocation_method   = "Static"
  
  tags = { 
    environment = var.environment
  }
}

# Create Network Card for IIS VM
resource "azurerm_network_interface" "iis-private-nic" {
  depends_on=[azurerm_resource_group.network-rg]

  name                = "iis-${random_string.iis-vm-name.result}-nic"
  location            = azurerm_resource_group.network-rg.location
  resource_group_name = azurerm_resource_group.network-rg.name
  
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.network-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.iis-vm-ip.id
  }

  tags = {
    environment = var.environment
  }
}

# Create a Windows VM with IIS
resource "azurerm_virtual_machine" "iis-vm" {
  depends_on=[azurerm_network_interface.iis-private-nic]

  location              = azurerm_resource_group.network-rg.location
  resource_group_name   = azurerm_resource_group.network-rg.name
  name                  = "iis-${random_string.iis-vm-name.result}-vm"
  network_interface_ids = [azurerm_network_interface.iis-private-nic.id]
  vm_size               = var.iis_vm_size
  license_type          = var.iis_license_type

  delete_os_disk_on_termination    = var.iis_delete_os_disk_on_termination
  delete_data_disks_on_termination = var.iis_delete_data_disks_on_termination

  storage_image_reference {
    id        = lookup(var.iis_vm_image, "id", null)
    offer     = lookup(var.iis_vm_image, "offer", null)
    publisher = lookup(var.iis_vm_image, "publisher", null)
    sku       = lookup(var.iis_vm_image, "sku", null)
    version   = lookup(var.iis_vm_image, "version", null)
  }

  storage_os_disk {
    name              = "iis-${random_string.iis-vm-name.result}-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "iis-${random_string.iis-vm-name.result}-vm"
    admin_username = var.iis_admin_username
    admin_password = random_password.iis-vm-password.result
  }

  # os_profile_secrets {
  #   source_vault_id = var.key_vault_id
  # }

  # boot_diagnostics {
  #   enabled     = true
  #   storage_uri = "https://${var.diagnostics_storage_account_name}.blob.core.windows.net"
  # }

  os_profile_windows_config {
    provision_vm_agent        = true
    enable_automatic_upgrades = true
  }

  tags = {
    environment = var.environment
  }
}

# Virtual Machine Extension
resource "azurerm_virtual_machine_extension" "iis-vm-extension" {
  name                 = "iis-${random_string.iis-vm-name.result}-vm"
  virtual_machine_id   = azurerm_virtual_machine.iis-vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  settings = <<SETTINGS
    { 
      "commandToExecute": "powershell Install-WindowsFeature -name Web-Server -IncludeManagementTools;"
    } 
  SETTINGS

  tags = {
    environment = var.environment
  }
}

