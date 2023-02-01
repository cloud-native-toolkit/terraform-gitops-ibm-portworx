
output "name" {
  description = "The name of the module"
  value       = local.name
  depends_on  = [gitops_module.module]
}

output "branch" {
  description = "The branch where the module config has been placed"
  value       = local.application_branch
  depends_on  = [gitops_module.module]
}

output "namespace" {
  description = "The namespace where the module will be deployed"
  value       = local.namespace
  depends_on  = [gitops_module.module]
}

output "server_name" {
  description = "The server where the module will be deployed"
  value       = var.server_name
  depends_on  = [gitops_module.module]
}

output "layer" {
  description = "The layer where the module is deployed"
  value       = local.layer
  depends_on  = [gitops_module.module]
}

output "type" {
  description = "The type of module where the module is deployed"
  value       = local.type
  depends_on  = [gitops_module.module]
}

output "region" {
  description = "The region where the portworx resource has been delivered"
  value       = var.region
  depends_on  = [gitops_module.module]
}

output "resource_group_id" {
  description = "The id of the resource group where the portworx resource has been delivered"
  value       = var.resource_group_id
  depends_on  = [gitops_module.module]
}

output "rwx_storage_class" {
  value       = ""
  depends_on  = [gitops_module.module]
}

output "rwo_storage_class" {
  value = "ibmc-vpc-block-10iops-tier"
  depends_on  = [gitops_module.module]
}

output "file_storage_class" {
  value       = ""
  depends_on  = [gitops_module.module]
}

output "block_storage_class" {
  value       = "ibmc-vpc-block-10iops-tier"
  depends_on  = [gitops_module.module]
}
