locals {
  domain_join_command = (
    "./ud_join_ad.sh -d \"${var.domain_join.domain_name}\" -dis \"${var.domain_join.disname}\" -a \"${var.domain_join.windows_admins_ad_group}\" -u \"${var.domain_join.user_name}\" -v \"${var.dj_kv_name}\" --host \"${azurerm_linux_virtual_machine.vm.name}\" -c \"${var.domain_join.azure_cloud}\";"
  )

  commandToExecute = (
    var.is_domain_join ?
    "${local.domain_join_command}${chomp(var.custom_scripts)} exit 0" :
    "${chomp(var.custom_scripts)} exit 0"
  )

  fileUris = (
    var.is_domain_join ?
    concat([var.domain_join.windows_domainjoin_url], var.custom_scripts_fileUris) :
    var.custom_scripts_fileUris
  )
}
