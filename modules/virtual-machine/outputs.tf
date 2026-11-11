output "address" {
  description = "The machine's address on the lab network, without its prefix length."
  value       = split("/", var.address)[0]
}

output "vm_id" {
  description = "The machine's identifier in Proxmox."
  value       = proxmox_virtual_environment_vm.main.vm_id
}
