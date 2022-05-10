
resource local_file namespace {
  filename = "${path.cwd}/.namespace"

  content = "kube-system"
}
