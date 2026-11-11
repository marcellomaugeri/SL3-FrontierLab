# Debian 13 genericcloud, the base image of every machine, checked against the SHA-512 in its build folder's SHA512SUMS.
resource "proxmox_download_file" "os_image" {
  checksum           = "d25999de0770d4cde1be72c299ba3ad94eac7ea8fd4d18f8cc86c69df69337e2e8a91d64465a9bfd8f2a78c566fcbcb0842eacc91c09efdef72d719d9f13b535"
  checksum_algorithm = "sha512"
  content_type       = "import"
  datastore_id       = "local"
  file_name          = "debian-13-genericcloud-amd64-20261103-2651.qcow2"
  node_name          = var.node_name
  url                = "https://cloud.debian.org/images/cloud/trixie/20261103-2651/debian-13-genericcloud-amd64-20261103-2651.qcow2"
}

# The lab network follows the Source NAT example of Proxmox's SDN documentation.
resource "proxmox_sdn_zone_simple" "lab" {
  id    = "lab"
  nodes = [var.node_name]

  depends_on = [proxmox_sdn_applier.finalizer]
}

resource "proxmox_sdn_vnet" "weights" {
  id   = "weights"
  zone = proxmox_sdn_zone_simple.lab.id

  depends_on = [proxmox_sdn_applier.finalizer]
}

resource "proxmox_sdn_subnet" "weights" {
  cidr    = var.lab_subnet
  gateway = local.lab_gateway
  snat    = true
  vnet    = proxmox_sdn_vnet.weights.id

  depends_on = [proxmox_sdn_applier.finalizer]
}

resource "proxmox_sdn_applier" "main" {
  lifecycle {
    replace_triggered_by = [
      proxmox_sdn_zone_simple.lab,
      proxmox_sdn_vnet.weights,
      proxmox_sdn_subnet.weights,
    ]
  }

  depends_on = [
    proxmox_sdn_zone_simple.lab,
    proxmox_sdn_vnet.weights,
    proxmox_sdn_subnet.weights,
  ]
}

resource "proxmox_sdn_applier" "finalizer" {}

module "weight_storage" {
  source = "./modules/virtual-machine"
  count  = contains(var.assets, "weight-storage") ? 1 : 0

  address          = "${local.weight_enclave_address}/${local.lab_prefix_length}"
  cloud_init       = templatefile("${path.module}/weight-storage/cloud-init.yaml.tftpl", { hostname = "weight-enclave", ssh_public_key = var.ssh_public_key })
  cores            = 2
  data_disk_size   = 64
  gateway          = local.lab_gateway
  image_file_id    = proxmox_download_file.os_image.id
  memory           = 4096
  name             = "weight-enclave"
  network_bridge   = proxmox_sdn_vnet.weights.id
  node_name        = var.node_name
  system_disk_size = 20

  depends_on = [proxmox_sdn_applier.main]
}
