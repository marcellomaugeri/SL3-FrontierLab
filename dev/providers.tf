# The cluster comes from the operator's kubeconfig file, in the context that the kube_context setting names.
provider "kubernetes" {
  config_context = var.kube_context
  config_path    = "~/.kube/config"
}
