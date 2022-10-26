module "ibmcloud_operator" {
  source = "github.com/cloud-native-toolkit/terraform-gitops-ibmcloud-operator"

  gitops_config = module.gitops.gitops_config
  git_credentials = module.gitops.git_credentials
  server_name = module.gitops.server_name
  kubeseal_cert = module.cert.cert
}
