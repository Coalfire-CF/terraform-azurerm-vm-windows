variable "vm_name" {
  type        = string
  description = "Azure Virtual Machine Name"
  validation {
    condition     = var.vm_hostname != null || length(var.vm_name) <= 15
    error_message = "vm_name is used as the Windows computer name when vm_hostname is null, so it must be 15 characters or less. Set vm_hostname or shorten vm_name."
  }
}

variable "vm_hostname" {
  type        = string
  description = "(Optional) Hostname for the virtual machine. Must be 15 characters or less."
  validation {
    condition     = var.vm_hostname == null || length(var.vm_hostname) <= 15
    error_message = "VM hostname must be 15 characters or less in length"
  }
  default = null
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
  description = "Local administrator user name."
}

variable "size" {
  type        = string
  description = "Azure Virtual Machine size"
  default     = "Standard_D2s_v5"
}

variable "source_image_reference" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  description = "Marketplace image reference. Set this or source_image_id, not both."
  default     = null
}

variable "plan" {
  type = object({
    publisher = string
    name      = string
    product   = string
  })
  description = "Marketplace plan info. Only required if using a Marketplace image that includes a plan."
  default     = null
}

variable "source_image_id" {
  type        = string
  description = "Image ID, for example a shared image gallery version. Set this or source_image_reference, not both."
  default     = null
  validation {
    condition     = (var.source_image_id == null) != (var.source_image_reference == null)
    error_message = "Set exactly one of source_image_id or source_image_reference."
  }
}

variable "availability_set_id" {
  type        = string
  description = "Azure Availability VM should be attached to"
  default     = null
}

variable "availability_zone" {
  type        = string
  description = "Availability zone (\"1\", \"2\" or \"3\"). Default null: no zone pinning. Cannot be combined with availability_set_id."
  default     = null
  validation {
    condition     = var.availability_zone == null || contains(["1", "2", "3"], var.availability_zone)
    error_message = "availability_zone must be \"1\", \"2\" or \"3\"."
  }
  validation {
    condition     = var.availability_zone == null || var.availability_set_id == null
    error_message = "Set availability_zone or availability_set_id, not both."
  }
}

variable "enable_public_ip" {
  type        = bool
  description = "Attach a public IP to the VM. Default false. Setting true exposes the VM to the internet; use only with an NSG that restricts management ports (R9, R10)."
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Tags for every taggable resource. Merged with regional_tags and global_tags; tags wins on key collisions."
  default     = {}
}

variable "regional_tags" {
  type        = map(string)
  description = "Regional level tags"
  default     = {}
}

variable "global_tags" {
  type        = map(string)
  description = "Global level tags"
  default     = {}
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
  validation {
    condition     = contains(["Dynamic", "Static"], var.private_ip_address_allocation)
    error_message = "private_ip_address_allocation must be Dynamic or Static."
  }
}

variable "private_ip" {
  type        = string
  description = "Static private IP. Required when private_ip_address_allocation is Static."
  default     = null
  validation {
    condition     = var.private_ip_address_allocation != "Static" || var.private_ip != null
    error_message = "private_ip is required when private_ip_address_allocation is Static."
  }
}

variable "public_ip_sku" {
  type        = string
  description = "Sku for the public IP attached to the VM. Can be `null` if no public IP needed."
  default     = "Standard"
}

variable "kv_id" {
  type        = string
  description = "Key Vault ID that stores the generated local admin password. Required."
}

variable "admin_password_expiration_days" {
  type        = number
  description = "Days until the local admin password secret is marked expired in Key Vault. The expiry is informational: the secret can still be read after it, for recovery. The module does not rotate the password."
  default     = 365
  validation {
    condition     = var.admin_password_expiration_days > 0
    error_message = "admin_password_expiration_days must be greater than 0."
  }
}

variable "vm_diag_sa" {
  type        = string
  description = "Storage Account VM diagnostics are stored in"
}

variable "diag_log_analytics_id" {
  type        = string
  description = "Log Analytics workspace ID for the data collection rule and diagnostic settings."
}

variable "disk_caching" {
  type        = string
  description = "Type of caching used for Internal OS Disk - Must be one of [None, ReadOnly, ReadWrite]"
  default     = "ReadWrite"
  validation {
    condition     = contains(["None", "ReadOnly", "ReadWrite"], var.disk_caching)
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

variable "encryption_at_host_enabled" {
  type        = bool
  description = "Encrypt temp disk and caches at the host. Set false only for a size that does not support encryption at host; disabling it leaves those caches encrypted by platform keys only."
  default     = true
}

variable "trusted_launch" {
  type        = bool
  description = "Enable Trusted Launch: sets secure boot and vTPM. Needs a Gen2 image."
  default     = true
}

variable "is_domain_join" {
  type        = bool
  description = "Join the VM to Active Directory through the custom script extension. Requires domain_join and dj_kv_name. The script at domain_join.windows_domainjoin_url must be a PowerShell .ps1 that accepts the parameters listed in the README."
  default     = false
  validation {
    condition     = !var.is_domain_join || (var.domain_join != null && var.dj_kv_name != null)
    error_message = "is_domain_join = true needs domain_join and dj_kv_name."
  }
  validation {
    condition     = !var.is_domain_join || var.domain_join == null || endswith(lower(var.domain_join.windows_domainjoin_url), ".ps1")
    error_message = "domain_join.windows_domainjoin_url must point to a .ps1 script."
  }
}

variable "domain_join" {
  type = object({
    domain_name             = string
    disname                 = string
    windows_admins_ad_group = string
    user_name               = string
    azure_cloud             = string
    windows_domainjoin_url  = string
    dj_kv_id                = string
  })
  description = "Map with information required to join the vm to the domain. windows_domainjoin_url is a PowerShell .ps1 script. disname is passed as -OUPath."
  default     = null
}

variable "custom_scripts_fileUris" {
  type        = list(string)
  description = "List with storage URLs to download custom scripts"
  default     = []
  nullable    = false
}

variable "custom_scripts" {
  type        = string
  description = "PowerShell statements run by the custom script extension after domain join. Each statement ends with a semicolon."
  default     = ""
  sensitive   = true
  validation {
    condition     = var.custom_scripts != "" ? substr(var.custom_scripts, -1, -1) == ";" : var.custom_scripts == ""
    error_message = "The custom scripts must include a semicolon (;) at the end of the string."
  }
}

variable "dj_kv_name" {
  type        = string
  description = "Key Vault name containing the domain join user password"
  default     = null
}

variable "sa_install_id" {
  type        = string
  description = "Storage account id containing the install scripts"
}

variable "custom_role_assignments" {
  type = list(object({
    scope = string
    role  = string
  }))
  description = "Extra role assignments for the VM's system-assigned identity. Each item gives a scope and a role name."
  default     = []
}

variable "ama_settings" {
  description = "Optional settings to pass to the Azure Monitor Agent extension"
  type        = map(any)
  default     = {}
}

variable "windows_event_logs" {
  description = "Windows Event Logs to collect"
  type = list(object({
    name           = string
    streams        = list(string)
    x_path_queries = list(string)
  }))
  default = [
    {
      name    = "windows-events"
      streams = ["Microsoft-Event"]
      x_path_queries = [
        "Application!*[System[(Level=1 or Level=2 or Level=3 or Level=4 or Level=0 or Level=5)]]",
        "Security!*[System[(band(Keywords,13510798882111488))]]",
        "System!*[System[(Level=1 or Level=2 or Level=3 or Level=4 or Level=0 or Level=5)]]"
      ]
    }
  ]
}

variable "performance_counters" {
  description = "Performance counters to collect"
  type = list(object({
    name                          = string
    streams                       = list(string)
    sampling_frequency_in_seconds = number
    counter_specifiers            = list(string)
  }))
  validation {
    condition     = length(var.performance_counters) + length(var.windows_event_logs) > 0
    error_message = "At least one data source is required for the data collection rule."
  }
  default = [
    {
      name                          = "windows-performance"
      streams                       = ["Microsoft-Perf"]
      sampling_frequency_in_seconds = 60
      counter_specifiers = [
        "\\Processor Information(_Total)\\% Processor Time",
        "\\Processor Information(_Total)\\% Privileged Time",
        "\\Processor Information(_Total)\\% User Time",
        "\\Processor Information(_Total)\\Processor Frequency",
        "\\System\\Processes",
        "\\Process(_Total)\\Thread Count",
        "\\Process(_Total)\\Handle Count",
        "\\System\\System Up Time",
        "\\System\\Context Switches/sec",
        "\\System\\Processor Queue Length",
        "\\Memory\\% Committed Bytes In Use",
        "\\Memory\\Available Bytes",
        "\\Memory\\Committed Bytes",
        "\\Memory\\Cache Bytes",
        "\\Memory\\Pool Paged Bytes",
        "\\Memory\\Pool Nonpaged Bytes",
        "\\Memory\\Pages/sec",
        "\\Memory\\Page Faults/sec",
        "\\Process(_Total)\\Working Set",
        "\\Process(_Total)\\Working Set - Private",
        "\\LogicalDisk(_Total)\\% Disk Time",
        "\\LogicalDisk(_Total)\\% Disk Read Time",
        "\\LogicalDisk(_Total)\\% Disk Write Time",
        "\\LogicalDisk(_Total)\\% Idle Time",
        "\\LogicalDisk(_Total)\\Disk Bytes/sec",
        "\\LogicalDisk(_Total)\\Disk Read Bytes/sec",
        "\\LogicalDisk(_Total)\\Disk Write Bytes/sec",
        "\\LogicalDisk(_Total)\\Disk Transfers/sec",
        "\\LogicalDisk(_Total)\\Disk Reads/sec",
        "\\LogicalDisk(_Total)\\Disk Writes/sec",
        "\\LogicalDisk(_Total)\\Avg. Disk sec/Transfer",
        "\\LogicalDisk(_Total)\\Avg. Disk sec/Read",
        "\\LogicalDisk(_Total)\\Avg. Disk sec/Write",
        "\\LogicalDisk(_Total)\\Avg. Disk Queue Length",
        "\\LogicalDisk(_Total)\\Avg. Disk Read Queue Length",
        "\\LogicalDisk(_Total)\\Avg. Disk Write Queue Length",
        "\\LogicalDisk(_Total)\\% Free Space",
        "\\LogicalDisk(_Total)\\Free Megabytes",
        "\\Network Interface(*)\\Bytes Total/sec",
        "\\Network Interface(*)\\Bytes Sent/sec",
        "\\Network Interface(*)\\Bytes Received/sec",
        "\\Network Interface(*)\\Packets/sec",
        "\\Network Interface(*)\\Packets Sent/sec",
        "\\Network Interface(*)\\Packets Received/sec",
        "\\Network Interface(*)\\Packets Outbound Errors",
        "\\Network Interface(*)\\Packets Received Errors"
      ]
    }
  ]
}
