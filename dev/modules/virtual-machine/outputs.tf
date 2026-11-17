output "address" {
  description = "The machine's address for virtctl, in the form vm/<name>/<namespace>."
  value       = "vm/${var.name}/${var.namespace}"
}
