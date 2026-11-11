variable "assets" {
  description = "Component folders to deploy, for example [\"weight-storage\"]."
  type        = list(string)
}

variable "lab_subnet" {
  description = "Address range of the lab network; the gateway takes its first address and the machines the following ones."
  type        = string
  default     = "172.16.0.0/24"
}

variable "node_name" {
  description = "Name of the Proxmox node, as the Proxmox web interface shows it."
  type        = string
}

variable "proxmox_ip" {
  description = "Public IP address of the Proxmox server, which the provider reaches over SSH."
  type        = string
}

variable "ssh_public_key" {
  description = "OpenSSH public key that opens the lab's machines."
  type        = string
}
