locals {
  name          = "portworx"
  bin_dir       = module.setup_clis.bin_dir
  yaml_dir      = "${path.cwd}/.tmp/${local.name}/chart/${local.name}"
  template_dir  = "${local.yaml_dir}/templates"
  secret_dir    = "${path.cwd}/.tmp/${local.name}/secrets"
  apikey_secret_name = "ibmcloud-operator-secret"
  etcd_secret_name = "etcd-credentials"
  etcd_external = var.etcd_connection_url != "" && var.etcd_username != "" && var.etcd_password != ""
  values_content = {
    ibm-portworx = {
      region = var.region
      resourceGroupId = var.resource_group_id

      volume = {
        capacity = var.capacity
        profile = var.profile
        encryption_key = var.encryption_key
      }

      volumeSuffix = random_string.volume_suffix.result

      etcdSecretName = local.etcd_external ? local.etcd_secret_name : ""
    }
  }
  layer = "infrastructure"
  type  = "instances"
  application_branch = "main"
  namespace = "kube-system"
  layer_config = var.gitops_config[local.layer]
}

resource random_string volume_suffix {
  upper = false
  special = false
  length = 8
}

module setup_clis {
  source = "cloud-native-toolkit/clis/util"
  version = "1.9.5"

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
    command = "${path.module}/scripts/create-secret.sh '${local.namespace}' '${local.apikey_secret_name}' '${local.etcd_secret_name}' '${local.secret_dir}'"

    environment = {
      IBMCLOUD_API_KEY = nonsensitive(var.ibmcloud_api_key)
      BIN_DIR = module.setup_clis.bin_dir
      ETCD_USERNAME = var.etcd_username
      ETCD_PASSWORD = var.etcd_password
      ETCD_CONNECTION_URL = var.etcd_connection_url
      ETCD_CERTIFICATE_BASE64 = var.etcd_certificate_base64
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

resource null_resource setup_gitops {
  depends_on = [null_resource.create_yaml, module.seal_secrets]

  triggers = {
    name = local.name
    namespace = local.namespace
    yaml_dir = local.yaml_dir
    server_name = var.server_name
    layer = local.layer
    type = local.type
    git_credentials = yamlencode(var.git_credentials)
    gitops_config   = yamlencode(var.gitops_config)
    bin_dir = local.bin_dir
  }

  provisioner "local-exec" {
    command = "${self.triggers.bin_dir}/igc gitops-module '${self.triggers.name}' -n '${self.triggers.namespace}' --contentDir '${self.triggers.yaml_dir}' --serverName '${self.triggers.server_name}' -l '${self.triggers.layer}' --type '${self.triggers.type}' --cascadingDelete=true"

    environment = {
      GIT_CREDENTIALS = nonsensitive(self.triggers.git_credentials)
      GITOPS_CONFIG   = self.triggers.gitops_config
    }
  }

  provisioner "local-exec" {
    when = destroy
    command = "${self.triggers.bin_dir}/igc gitops-module '${self.triggers.name}' -n '${self.triggers.namespace}' --delete --contentDir '${self.triggers.yaml_dir}' --serverName '${self.triggers.server_name}' -l '${self.triggers.layer}' --type '${self.triggers.type}'"

    environment = {
      GIT_CREDENTIALS = nonsensitive(self.triggers.git_credentials)
      GITOPS_CONFIG   = self.triggers.gitops_config
    }
  }
}
