variable "vm_name" {
  type        = string
  description = "Azure Virtual Machine Name"
}

variable "location" {
  type        = string
  description = "Azure region for resource deployment"
}

variable "resource_group_name" {
  type        = string
  description = "Azure Resource Group resource will be deployed in"
}

variable "vm_admin_username" {
  type        = string
  description = "Local Administrator Name"
}

variable "size" {
  type        = string
  description = "Azure Virtual Machine size"
  default     = "Standard_DS2_v2"
}

variable "source_image_reference" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  description = "VM image from shared image gallery"
  default     = null
}

variable "plan" {
  type = object({
    publisher = string
    name      = string
    product   = string
  })
  description = "Marketplace plan info — only required if using a Marketplace image that includes a plan."
  default     = null
}

variable "source_image_id" {
  type        = string
  description = "VM image from shared image gallery"
  default     = null
}

variable "availability_set_id" {
  type        = string
  description = "Azure Availability VM should be attached to"
  default     = null
}

variable "availability_zone" {
  type        = list(number)
  description = "Specifies an Availability Zone in which the Windows VM should be located"
  default     = null
}

variable "enable_public_ip" {
  type        = bool
  description = "True/False if a Public IP Address should be attached to the VM"
}

variable "vm_tags" {
  type        = map(string)
  description = "Key/Value tags that should be added to the VM"
  default     = {}
}

variable "regional_tags" {
  type        = map(string)
  description = "Regional level tags"
}

variable "global_tags" {
  type        = map(string)
  description = "Global level tags"
}

variable "custom_dns_label" {
  type        = string
  description = "The DNS label to use for public access. VM name if not set. DNS will be <label>.eastus2.cloudapp.azure.com"
  default     = ""
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet the VM NIC should be attached to"
}

variable "private_ip_address_allocation" {
  type        = string
  description = "Dynamic or Static"
  default     = "Dynamic"
}

variable "private_ip" {
  type        = string
  description = "Static Private IP address"
  default     = ""
}

variable "public_ip_sku" {
  type        = string
  description = "Sku for the public IP attached to the VM. Can be `null` if no public IP needed."
  default     = "Standard"
}

variable "kv_id" {
  type        = string
  description = "Key Vault Resource ID to store local admin password"
  default     = null
}

variable "vm_diag_sa" {
  type        = string
  description = "Storage Account VM diagnostics are stored in"
}

variable "storage_account_vmdiag_name" {
  type        = string
  description = "Storage Account VM diagnostics are stored in"
}

variable "disk_caching" {
  type        = string
  description = "Type of caching used for Internal OS Disk - Must be one of [None, ReadOnly, ReadWrite]"
  default     = "ReadWrite"
  validation {
    condition     = contains(["None, ReadOnly", "ReadWrite"], var.disk_caching)
    error_message = "Error: Must be one of [None, ReadOnly, ReadWrite]."
  }
}

variable "vm_storage_account_type" {
  type        = string
  description = "The Type of Storage Account which should back the OS Disk"
  default     = "StandardSSD_LRS"
}

variable "disk_size" {
  type        = number
  description = "Size of the Disk"
  default     = 127
}

variable "trusted_launch" {
  type        = bool
  description = "Enable Trusted Launch"
  default     = true
}
