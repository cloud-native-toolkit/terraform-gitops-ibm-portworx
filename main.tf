locals {
  name          = "portworx"
  bin_dir       = module.setup_clis.bin_dir
  yaml_dir      = "${path.cwd}/.tmp/${local.name}/chart/${local.name}"
  template_dir  = "${local.yaml_dir}/templates"
  secret_dir    = "${path.cwd}/.tmp/${local.name}/secrets"
  apikey_secret_name = "ibmcloud-operator-secret"
  values_content = {
    ibm-portworx = {
      region = var.region
      resourceGroupId = var.resource_group_id

      volume = {
        capacity = var.capacity
        profile = var.profile
        encryption_key = var.encryption_key
      }
    }
  }
  layer = "infrastructure"
  type  = "instances"
  application_branch = "main"
  namespace = "kube-system"
  layer_config = var.gitops_config[local.layer]
}

module setup_clis {
  source = "cloud-native-toolkit/clis/util"

  clis = ["igc", "jq", "kubectl"]
}

resource null_resource create_yaml {
  provisioner "local-exec" {
    command = "${path.module}/scripts/create-yaml.sh '${local.name}' '${local.yaml_dir}'"

    environment = {
      VALUES_CONTENT = yamlencode(local.values_content)
    }
  }
}

resource null_resource create_secrets {
  depends_on = [null_resource.create_yaml]

  provisioner "local-exec" {
    command = "${path.module}/scripts/create-secret.sh '${local.namespace}' '${local.apikey_secret_name}' '${local.secret_dir}'"

    environment = {
      IBMCLOUD_API_KEY = nonsensitive(var.ibmcloud_api_key)
      BIN_DIR = module.setup_clis.bin_dir
    }
  }
}

module seal_secrets {
  depends_on = [null_resource.create_secrets]

  source = "github.com/cloud-native-toolkit/terraform-util-seal-secrets.git?ref=v1.1.0"

  source_dir    = local.secret_dir
  dest_dir      = local.template_dir
  kubeseal_cert = var.kubeseal_cert
  label         = "ibmcloud-operator-secret"
  annotations   = ["argocd.argoproj.io/sync-wave=-5"]
}

resource gitops_module module {
  depends_on = [null_resource.create_yaml, module.seal_secrets]

  name = local.name
  namespace = local.namespace
  content_dir = local.yaml_dir
  server_name = var.server_name
  layer = local.layer
  type = local.type
  branch = local.application_branch
  config = yamlencode(var.gitops_config)
  credentials = yamlencode(var.git_credentials)
}
