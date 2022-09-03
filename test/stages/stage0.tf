terraform {
  required_providers {
    ibm = {
      source = "ibm-cloud/ibm"
      version = ">= 1.22.0"
    }
    gitops = {
      source = "cloud-native-toolkit/gitops"
    }
  }
}

module setup_test_clis {
  source = "github.com/cloud-native-toolkit/terraform-util-clis.git"

  bin_dir = "${path.cwd}/test_bin_dir"
  clis = ["kubectl", "oc"]
}

resource local_file bin_dir {
  filename = "${path.cwd}/.bin_dir"

  content = module.setup_test_clis.bin_dir
}
