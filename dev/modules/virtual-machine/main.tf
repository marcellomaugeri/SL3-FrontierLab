resource "kubernetes_secret_v1" "cloud_init" {
  metadata {
    name      = "${var.name}-cloud-init"
    namespace = var.namespace
  }

  data = {
    userdata = var.cloud_init
  }
}

# A KubeVirt virtual machine: a system disk from the image, a blank data disk, and the Cloud-Init data.
resource "kubernetes_manifest" "main" {
  manifest = {
    apiVersion = "kubevirt.io/v1"
    kind       = "VirtualMachine"

    metadata = {
      name      = var.name
      namespace = var.namespace
    }

    spec = {
      runStrategy = "Always"

      dataVolumeTemplates = [
        {
          metadata = { name = "${var.name}-system" }
          spec = {
            source  = { http = { url = var.image_url } }
            storage = { resources = { requests = { storage = "${var.system_disk_size}Gi" } } }
          }
        },
        {
          metadata = { name = "${var.name}-data" }
          spec = {
            source  = { blank = {} }
            storage = { resources = { requests = { storage = "${var.data_disk_size}Gi" } } }
          }
        },
      ]

      template = {
        spec = {
          domain = {
            cpu    = { cores = var.cores }
            memory = { guest = "${var.memory}Mi" }

            devices = {
              # The data disk carries the serial of its slot on Proxmox, so the machine finds it under the name that the setup files expect.
              disks = [
                { name = "system", bootOrder = 1, disk = { bus = "scsi" } },
                { name = "data", serial = "drive-scsi1", disk = { bus = "scsi" } },
                { name = "cloud-init", disk = { bus = "virtio" } },
              ]

              interfaces = [
                { name = "default", masquerade = {} },
              ]
            }
          }

          networks = [
            { name = "default", pod = {} },
          ]

          volumes = [
            { name = "system", dataVolume = { name = "${var.name}-system" } },
            { name = "data", dataVolume = { name = "${var.name}-data" } },
            { name = "cloud-init", cloudInitNoCloud = { secretRef = { name = kubernetes_secret_v1.cloud_init.metadata[0].name } } },
          ]
        }
      }
    }
  }
}
