
data "azurerm_resource_group" "rg" {
# location = var.resource_location
  name     = var.resource_group_name
}


data "azurerm_virtual_network" "vnet" {
    name = var.vnet_name
    resource_group_name = data.azurerm_resource_group.rg.name
}

#####################################
# Fetching Subnet ID data 
#####################################

data "azurerm_subnet" "management_subnet" {
    name = var.management
    virtual_network_name = data.azurerm_virtual_network.vnet.name
    resource_group_name  = data.azurerm_resource_group.rg.name
    depends_on = [data.azurerm_resource_group.rg]
}

data "azurerm_subnet" "snet-hub-sapm-palo-external" {
    name = var.gateway
    virtual_network_name = data.azurerm_virtual_network.vnet.name
    resource_group_name  = data.azurerm_resource_group.rg.name
    depends_on = [data.azurerm_resource_group.rg]
}

data "azurerm_subnet" "internal_subnet" {
    name = var.internal
    virtual_network_name = data.azurerm_virtual_network.vnet.name
    resource_group_name  = data.azurerm_resource_group.rg.name
    depends_on = [data.azurerm_resource_group.rg]
}

data "azurerm_subnet" "ha_subnet" {
    name = var.ha
    virtual_network_name = data.azurerm_virtual_network.vnet.name
    resource_group_name  = data.azurerm_resource_group.rg.name
    depends_on = [data.azurerm_resource_group.rg]
}


# Creation of the following resources:
#   - Azure Public IPs (Management)

# Public IP Address:

resource "azurerm_public_ip" "management" {
  for_each            = var.vmseries
  name                = "${each.key}-nic-management-pip"
  location            = var.resource_location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"
  depends_on          = [data.azurerm_resource_group.rg]
  sku                 = "Standard"
}


# Network Interface:
resource "azurerm_network_interface" "management" {
  for_each             = var.vmseries
  name                 = "${each.key}-nic-management"
  location             = var.resource_location
  resource_group_name  = data.azurerm_resource_group.rg.name
  enable_ip_forwarding = false

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = data.azurerm_subnet.management_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = each.value.management_ip
    public_ip_address_id          = azurerm_public_ip.management[each.key].id
  }
  depends_on = [data.azurerm_resource_group.rg]
}

resource "azurerm_network_security_group" "management" {
  for_each            = var.vmseries
  name                = "${each.key}-nsg-management"
  location            = var.resource_location
  resource_group_name = data.azurerm_resource_group.rg.name

  security_rule {
    name                       = "management-inbound"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["443", "22"]
    source_address_prefix      = "0.0.0.0/0"
    destination_address_prefix = "*"
  }

/*
  security_rule {
    name                       = "management-ICMP-inbound"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  */
  depends_on = [data.azurerm_resource_group.rg, azurerm_public_ip.management]
}


# Network Security Group (Management)
resource "azurerm_network_interface_security_group_association" "management" {
  for_each                  = var.vmseries
  network_interface_id      = azurerm_network_interface.management[each.key].id
  network_security_group_id = azurerm_network_security_group.management[each.key].id
}

#----------------------------------------------------------------------------------------------------------------------
# VM-Series - Ethernet0/1 Interface (gateway(Untrust))
#----------------------------------------------------------------------------------------------------------------------
# Network Interface
resource "azurerm_network_interface" "ethernet0_1" {
  for_each             = var.vmseries
  name                 = "${each.key}-nic-ethernet01"
  location             = var.resource_location
  resource_group_name  = data.azurerm_resource_group.rg.name
  enable_ip_forwarding = true
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = data.azurerm_subnet.snet-hub-sapm-palo-external.id
    private_ip_address_allocation = "Static"
    private_ip_address            = each.value.gateway_ip
  }
  depends_on = [data.azurerm_resource_group.rg]
}

resource "azurerm_network_security_group" "data" {
  for_each            = var.vmseries
  name                = "${each.key}-nsg-allow-all"
  location            = var.resource_location
  resource_group_name = data.azurerm_resource_group.rg.name

  security_rule {
    name                       = "data-inbound"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "data-outbound"
    priority                   = 1000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  depends_on = [data.azurerm_resource_group.rg]
}

# Network Security Group (Data)
resource "azurerm_network_interface_security_group_association" "ethernet0_1" {
  for_each                  = var.vmseries
  network_interface_id      = azurerm_network_interface.ethernet0_1[each.key].id
  network_security_group_id = azurerm_network_security_group.data[each.key].id
}


#----------------------------------------------------------------------------------------------------------------------
# VM-Series - Ethernet0/2 Interface (Internal/Trust)
#----------------------------------------------------------------------------------------------------------------------

# Network Interface
resource "azurerm_network_interface" "ethernet0_2" {
  for_each             = var.vmseries
  name                 = "${each.key}-nic-ethernet02"
  location             = var.resource_location
  resource_group_name  = data.azurerm_resource_group.rg.name
  enable_ip_forwarding = true
  enable_accelerated_networking = true


  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = data.azurerm_subnet.internal_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = each.value.internal_ip
  }
  depends_on = [data.azurerm_resource_group.rg]
}

# Network Security Group (Data)
resource "azurerm_network_interface_security_group_association" "ethernet0_2" {
  for_each                  = var.vmseries
  network_interface_id      = azurerm_network_interface.ethernet0_2[each.key].id
  network_security_group_id = azurerm_network_security_group.data[each.key].id
}


#----------------------------------------------------------------------------------------------------------------------
# VM-Series - Ethernet0/3 Interface (HA)
#----------------------------------------------------------------------------------------------------------------------

# Network Interface
resource "azurerm_network_interface" "ethernet0_3" {
  for_each             = var.vmseries
  name                 = "${each.key}-nic-ethernet03"
  location             = var.resource_location
  resource_group_name  = data.azurerm_resource_group.rg.name
  enable_ip_forwarding = true
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = data.azurerm_subnet.ha_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = each.value.ha2_ip
  }
  depends_on = [data.azurerm_resource_group.rg]
}

# Network Security Group (Data)
resource "azurerm_network_interface_security_group_association" "ethernet0_3" {
  for_each                  = var.vmseries
  network_interface_id      = azurerm_network_interface.ethernet0_3[each.key].id
  network_security_group_id = azurerm_network_security_group.data[each.key].id
}


#----------------------------------------------------------------------------------------------------------------------
# VM-Series - Virtual Machine
#----------------------------------------------------------------------------------------------------------------------
#Below cpmmand is required to accept aggreement.
#terraform import azurerm_marketplace_agreement.Accept_agreement /subscriptions/50e7cbbe-0c28-48ce-92c1-6e9d72f746c5/providers/Microsoft.MarketplaceOrdering/agreements/paloaltonetworks/offers/vmseries-flex/plans/bundle2
resource "azurerm_marketplace_agreement" "Accept_agreement" {
  for_each = var.vmseries
  publisher = "paloaltonetworks"
  offer     = "vmseries1"
  plan      = "bundle2"
}

resource "azurerm_linux_virtual_machine" "vmseries" {
  for_each = var.vmseries

  # Resource Group & Location:
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.resource_location

  name = "${each.key}"

  # Availabilty Zone:
  #zone = each.value.availability_zone

  # Instance
  size = each.value.instance_size

  # Username and Password Authentication:
  disable_password_authentication = false
  admin_username                  = each.value.admin_username
  admin_password                  = each.value.admin_password

  # Network Interfaces:
  network_interface_ids = [
    azurerm_network_interface.management[each.key].id,
    azurerm_network_interface.ethernet0_1[each.key].id,
    azurerm_network_interface.ethernet0_2[each.key].id,
    azurerm_network_interface.ethernet0_3[each.key].id,
  ]

  plan {
    name      = each.value.license
    publisher = "paloaltonetworks"
    # Need to check product types as per requirement.
    product   = "vmseries1"
  }

  source_image_reference {
    publisher = "paloaltonetworks"
    offer     = "vmseries1"
    sku       = each.value.license
    version   = each.value.version
  }

  os_disk {
    name                 = "${each.key}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  depends_on = [azurerm_marketplace_agreement.Accept_agreement]

}

output "vmseries0_management_ip" {
  value = azurerm_public_ip.management["fw01-hub-sapm-scus"].ip_address
}

output "vmseries1_management_ip" {
  value = azurerm_public_ip.management["fw02-hub-sapm-scus"].ip_address
}
