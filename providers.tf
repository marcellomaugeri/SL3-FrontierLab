# The endpoint, the API token, the certificate check and the SSH sign-in come from the PROXMOX_VE_ entries of .env.
provider "proxmox" {
  ssh {
    node {
      address = var.proxmox_ip
      name    = var.node_name
    }
  }
}
