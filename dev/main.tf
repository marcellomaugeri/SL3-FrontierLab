resource "kubernetes_namespace_v1" "dev" {
  metadata {
    name = "sl3-frontierlab"
  }
}

# Terraform warns when the setup file names another build of SeaweedFS than locals.tf expects.
check "weight_storage_setup" {
  assert {
    condition     = strcontains(local.weight_storage_setup, "linux_amd64.tar.gz") && strcontains(local.weight_storage_setup, local.seaweedfs_sha256.amd64)
    error_message = "The setup file of the weight storage names another build of SeaweedFS, so the values in locals.tf have to follow it."
  }
}

module "weight_storage" {
  source = "./modules/virtual-machine"
  count  = contains(var.assets, "weight-storage") ? 1 : 0

  cloud_init       = local.weight_storage_cloud_init
  cores            = 2
  data_disk_size   = 16
  image_url        = local.image_url
  memory           = 2048
  name             = "weight-enclave"
  namespace        = kubernetes_namespace_v1.dev.metadata[0].name
  system_disk_size = 10
}
