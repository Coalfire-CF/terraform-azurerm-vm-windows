variable "subscription_id" {
  type        = string
  description = "Subscription to deploy into."
}

variable "location" {
  type        = string
  description = "Azure Government region."
  default     = "usgovvirginia"
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group for the VM."
}

variable "vm_name" {
  type        = string
  description = "VM name. Also the computer name, so 15 characters or less."
  default     = "ex-win-vm"
}

variable "vm_admin_username" {
  type        = string
  description = "Local administrator user name."
  default     = "xadm"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID for the VM NIC."
}

variable "kv_id" {
  type        = string
  description = "Key Vault ID that stores the generated local admin password."
}

variable "vm_diag_sa" {
  type        = string
  description = "Blob endpoint of the boot diagnostics storage account."
}

variable "sa_install_id" {
  type        = string
  description = "Storage account ID that holds install scripts."
}

variable "diag_log_analytics_id" {
  type        = string
  description = "Log Analytics workspace ID for diagnostics and the data collection rule."
}

variable "tags" {
  type        = map(string)
  description = "Tags for every resource the module creates."
  default     = {}
}
