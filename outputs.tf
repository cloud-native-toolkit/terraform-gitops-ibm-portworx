
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
  value       = var.default_rwx_storage_class
  depends_on  = [gitops_module.module]
}

output "rwo_storage_class" {
  value       = var.default_rwo_storage_class
  depends_on  = [gitops_module.module]
}

output "file_storage_class" {
  value       = var.default_file_storage_class
  depends_on  = [gitops_module.module]
}

output "block_storage_class" {
  value       = var.default_block_storage_class
  depends_on  = [gitops_module.module]
}

output "storage_classes_provided" {
  value      = [
    "portworx-cassandra-sc",
    "portworx-couchdb-sc",
    "portworx-db-gp",
    "portworx-db-gp2-sc",
    "portworx-db-gp3-sc",
    "portworx-db2-fci-sc",
    "portworx-db2-rwo-sc",
    "portworx-db2-rwx-sc",
    "portworx-dv-shared-gp",
    "portworx-dv-shared-gp3",
    "portworx-elastic-sc",
    "portworx-gp3-sc",
    "portworx-kafka-sc",
    "portworx-metastoredb-sc",
    "portworx-nonshared-gp2",
    "portworx-rwx-gp-sc",
    "portworx-rwx-gp2-sc",
    "portworx-rwx-gp3-sc",
    "portworx-shared-gp",
    "portworx-shared-gp-allow",
    "portworx-shared-gp1",
    "portworx-shared-gp3",
    "portworx-solr-sc",
    "portworx-watson-assistant-sc",
    "px-db",
    "px-db-cloud-snapshot",
    "px-db-cloud-snapshot-encrypted",
    "px-db-encrypted",
    "px-db-local-snapshot",
    "px-db-local-snapshot-encrypted",
    "px-replicated",
    "px-replicated-encrypted"
  ]
  depends_on  = [gitops_module.module]
}

