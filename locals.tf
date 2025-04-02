locals {
  commandToExecute = (
    var.is_domain_join ?
    "./ud_linux_join_ad.sh -d \"${var.domain_join.domain_name}\" -dis \"${var.domain_join.disname}\" -a \"${var.domain_join.linux_admins_ad_group}\" -u \"${var.domain_join.user_name}\" -v \"${local.dj_kv_name}\" --host \"${azurerm_linux_virtual_machine.vm.name}\" -c \"${var.domain_join.azure_cloud}\";${chomp(var.custom_scripts)} exit 0" :
    "${chomp(var.custom_scripts)} exit 0"
  )
  fileUris = (
    var.is_domain_join ?
    concat([var.domain_join.linux_domainjoin_url, var.linux_monitor_agent_url], var.custom_scripts_fileUris) :
    var.custom_scripts_fileUris
  )
}
