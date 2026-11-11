output "weight_enclave_address" {
  description = "Address of the Weight enclave on the lab network, or null when the assets list leaves it out."
  value       = one(module.weight_storage[*].address)
}
