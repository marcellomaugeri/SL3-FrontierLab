resource "proxmox_virtual_environment_file" "cloud_init" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.node_name

  source_raw {
    data      = var.cloud_init
    file_name = "${var.name}.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "main" {
  boot_order    = ["scsi0"]
  name          = var.name
  node_name     = var.node_name
  scsi_hardware = "virtio-scsi-single"

  cpu {
    cores = var.cores
    type  = "x86-64-v2-AES"
  }

  disk {
    datastore_id = "local"
    import_from  = var.image_file_id
    interface    = "scsi0"
    iothread     = true
    size         = var.system_disk_size
  }

  disk {
    datastore_id = "local"
    interface    = "scsi1"
    iothread     = true
    size         = var.data_disk_size
  }

  initialization {
    datastore_id      = "local"
    user_data_file_id = proxmox_virtual_environment_file.cloud_init.id

    ip_config {
      ipv4 {
        address = var.address
        gateway = var.gateway
      }
    }
  }

  memory {
    dedicated = var.memory
  }

  network_device {
    bridge   = var.network_bridge
    firewall = true
  }

  operating_system {
    type = "l26"
  }

  serial_device {}

  vga {
    type = "serial0"
  }
}

resource "proxmox_virtual_environment_firewall_options" "main" {
  enabled       = true
  input_policy  = "DROP"
  node_name     = var.node_name
  output_policy = "ACCEPT"
  vm_id         = proxmox_virtual_environment_vm.main.vm_id
}

resource "proxmox_virtual_environment_firewall_rules" "main" {
  node_name = var.node_name
  vm_id     = proxmox_virtual_environment_vm.main.vm_id

  rule {
    action  = "ACCEPT"
    comment = "SSH from the Proxmox server"
    dport   = "22"
    proto   = "tcp"
    source  = var.gateway
    type    = "in"
  }
}
