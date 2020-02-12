##########################################
## Azure VM with IIS Module - Variables ##
##########################################

# Azure virtual machine settings #

variable "iis_vm_size" {
  type        = string
  description = "Size (SKU) of the virtual machine to create"
}

variable "iis_license_type" {
  type        = string
  description = "Specifies the BYOL type for the virtual machine. Possible values are 'Windows_Client' and 'Windows_Server' if set"
  default     = null
}

# Azure virtual machine storage settings #

variable "iis_delete_os_disk_on_termination" {
  type        = string
  description = "Should the OS Disk (either the Managed Disk / VHD Blob) be deleted when the Virtual Machine is destroyed?"
  default     = "true"  # Update for your environment
}

variable "iis_delete_data_disks_on_termination" {
  description = "Should the Data Disks (either the Managed Disks / VHD Blobs) be deleted when the Virtual Machine is destroyed?"
  type        = string
  default     = "true" # Update for your environment
}

variable "iis_vm_image" {
  type        = map(string)
  description = "Virtual machine source image information"
  default     = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

# Azure virtual machine OS profile #

variable "iis_admin_username" {
  description = "Username for Virtual Machine administrator account"
  type        = string
  default     = ""
}

variable "iis_admin_password" {
  description = "Password for Virtual Machine administrator account"
  type        = string
  default     = ""
}

