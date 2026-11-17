locals {
  # Debian 13 genericcloud, the build that the full deployment uses, for each processor type.
  image_url = {
    amd64 = "https://cloud.debian.org/images/cloud/trixie/20261103-2651/debian-13-genericcloud-amd64-20261103-2651.qcow2"
    arm64 = "https://cloud.debian.org/images/cloud/trixie/20261103-2651/debian-13-genericcloud-arm64-20261103-2651.qcow2"
  }[var.architecture]

  # SHA-256 that GitHub records for each build of SeaweedFS 4.53.
  seaweedfs_sha256 = {
    amd64 = "d1a7dec9f48d8b33895a0ea8951971defc2dc5312906dcc76fa5a5f74a6ee90d"
    arm64 = "2eee359ed0ce8a70b711b30162fadda0cd4ea818e13c73d2f156a76f9359717d"
  }

  # The setup file of the weight storage, read as the full deployment reads it.
  weight_storage_setup = templatefile("${path.module}/../weight-storage/cloud-init.yaml.tftpl", {
    hostname       = "weight-enclave"
    ssh_public_key = var.ssh_public_key
  })

  # The setup file names SeaweedFS's build for amd64, so the name of the build and its SHA-256 follow the processor in use.
  weight_storage_cloud_init = replace(
    replace(local.weight_storage_setup, "linux_amd64.tar.gz", "linux_${var.architecture}.tar.gz"),
    local.seaweedfs_sha256.amd64,
    local.seaweedfs_sha256[var.architecture],
  )
}
