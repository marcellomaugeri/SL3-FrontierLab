locals {
  lab_gateway            = cidrhost(var.lab_subnet, 1)
  lab_prefix_length      = split("/", var.lab_subnet)[1]
  weight_enclave_address = cidrhost(var.lab_subnet, 2)
}
