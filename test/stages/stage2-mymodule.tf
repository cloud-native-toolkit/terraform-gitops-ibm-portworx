module "gitops_module" {
  source = "./module"

  gitops_config = module.gitops.gitops_config
  git_credentials = module.gitops.git_credentials
  server_name = module.gitops.server_name
  kubeseal_cert = module.gitops.sealed_secrets_cert
  resource_group_id = module.resource_group.id
  ibmcloud_api_key = var.ibmcloud_api_key

  etcd_username = module.etcd.username
  etcd_password = module.etcd.password
  etcd_connection_url = module.etcd.grpc_connection_url
  etcd_certificate_base64 = module.etcd.grpc_certificate_base64
}

resource local_file api_key {
  content = nonsensitive(var.ibmcloud_api_key)

  filename = ".api_key"
}
