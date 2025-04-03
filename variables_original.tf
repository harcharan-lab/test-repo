# ---------------------------------------------------------------------------------------------------------------------
#   Resource Group
# ---------------------------------------------------------------------------------------------------------------------

variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  default     = "xxxxxxx"
}

# ---------------------------------------------------------------------------------------------------------------------
#   Resource Location
# ---------------------------------------------------------------------------------------------------------------------

variable "resource_location" {
  description = "Location of all resources to be created"
  default     = "xxxxxxx"
}


variable "vnet_name" {
  description = "vnet"
  default     = "xxxxxxx"
}

# ----------------------------------------------------------------------------------------------------------------------
#NIC Card Details
# ----------------------------------------------------------------------------------------------------------------------

variable "management" {
  description = "Management subnet name"
  default = "xxxxxxx"
}

variable "gateway" {
  description = "Untrust subnet"
  default = "xxxxxxx"
}
variable "internal" {
  description = "Internal interface to sap environment"
  default = "xxxxxxx"
}
variable "ha" {
  description = "vnet naming"
  default = "xxxxxxx"
}


# Ensure you keep them names vmseries0 and vmseries1 or you will have to change reference in the TF files.
variable "vmseries" {
  description = "Definition of the VM-Series deployments"
  default = {
    fw01-hub-sapm-scus = {
      admin_username    = "xxxxxxx"
      admin_password    = "xxxxxxxxxx"
      instance_size     = "xxxxxxx"
      # License options "byol", "bundle1", "bundle2"
      license           = "bundle2"
      version           = "latest"
      management_ip     = "xxxxxxx"
      ha2_ip            = "xxxxxxx"
      internal_ip        = "xxxxxxx"
      gateway_ip         = "xxxxxxx"
      availability_zone = 1
      # If not licensing authcode is needed leave this set to a value of a space (ie " ")
      authcodes = " "
    }
    fw02-hub-sapm-scus = {
      admin_username    = "xxxxxxx"
      admin_password    = "xxxxxxxxx"
      instance_size     = "xxxxxxx"
      # License options "byol", "bundle1", "bundle2"
      license           = "bundle2"
      version           = "latest"
      management_ip     = "xxxxxxx"
      ha2_ip            = "xxxxxxx"
      internal_ip        = "xxxxxxx"
      gateway_ip         = "xxxxxxx"
      availability_zone = 2
      # If not licensing authcode is needed leave this set to a value of a space (ie " ")
      authcodes = " "
    }
  }   
}


variable "inbound_tcp_ports" {
  default = [22, 80]
}

variable "inbound_udp_ports" {
  default = [500, 4500]
}

#############################################################################################
# Provider Variables
#############################################################################################

 variable "subscription_id" {}
 variable "client_id" {}
 variable "client_secret" {}
 variable "tenant_id" {}
