variable "architecture" {
  description = "Processor type of the computer that runs the cluster: amd64 for Intel and AMD processors, arm64 for Apple and other Arm processors."
  type        = string
}

variable "assets" {
  description = "Component folders to deploy, for example [\"weight-storage\"]."
  type        = list(string)
}

variable "kube_context" {
  description = "Context of the kubeconfig file that names the cluster, for example kind-sl3-frontierlab."
  type        = string
}

variable "ssh_public_key" {
  description = "OpenSSH public key that opens the machines."
  type        = string
}
