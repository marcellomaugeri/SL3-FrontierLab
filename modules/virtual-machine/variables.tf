variable "address" {
  description = "The machine's address on the lab network, with its prefix length, for example 172.16.0.2/24."
  type        = string
}

variable "cloud_init" {
  description = "Cloud-Init user data that sets up the machine at its first boot."
  type        = string
}

variable "cores" {
  description = "Number of processor cores."
  type        = number
}

variable "data_disk_size" {
  description = "Size of the dedicated data disk, in GB."
  type        = number
}

variable "gateway" {
  description = "Gateway of the lab network, which is the Proxmox server's address on it."
  type        = string
}

variable "image_file_id" {
  description = "Proxmox identifier of the operating system image that the system disk starts from."
  type        = string
}

variable "memory" {
  description = "Memory, in MB."
  type        = number
}

variable "name" {
  description = "Name of the machine in Proxmox, a valid DNS name."
  type        = string
}

variable "network_bridge" {
  description = "Proxmox bridge of the lab network that the machine joins."
  type        = string
}

variable "node_name" {
  description = "Name of the Proxmox node that runs the machine."
  type        = string
}

variable "system_disk_size" {
  description = "Size of the system disk, in GB."
  type        = number
}
