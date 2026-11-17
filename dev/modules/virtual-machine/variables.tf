variable "cloud_init" {
  description = "Cloud-Init user data that sets up the machine at its first start."
  type        = string
}

variable "cores" {
  description = "Number of processor cores."
  type        = number
}

variable "data_disk_size" {
  description = "Size of the dedicated data disk, in GiB."
  type        = number
}

variable "image_url" {
  description = "Address of the operating system image that the system disk starts from."
  type        = string
}

variable "memory" {
  description = "Memory, in MiB."
  type        = number
}

variable "name" {
  description = "Name of the machine in the cluster, a valid DNS name."
  type        = string
}

variable "namespace" {
  description = "Namespace of the cluster that holds the machine."
  type        = string
}

variable "system_disk_size" {
  description = "Size of the system disk, in GiB."
  type        = number
}
