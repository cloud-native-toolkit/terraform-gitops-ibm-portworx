module "etcd" {
  source = "github.com/cloud-native-toolkit/terraform-ibm-etcd"

  resource_group_name = module.resource_group.name
  region = var.region
}
