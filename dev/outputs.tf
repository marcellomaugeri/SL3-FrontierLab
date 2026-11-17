output "weight_enclave_address" {
  description = "Address of the Weight enclave for virtctl, or null when the assets list leaves it out."
  value       = one(module.weight_storage[*].address)
}
