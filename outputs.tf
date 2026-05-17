output "hostname" {
  description = "Hostname of the created Proxmox container"
  value       = proxmox_virtual_environment_container.this.initialization[0].hostname
}

output "id" {
  description = "ID of the created Proxmox container"
  value       = proxmox_virtual_environment_container.this.vm_id
}

output "ipv4_address" {
  description = "IP address of the created Proxmox container"
  value       = proxmox_virtual_environment_container.this.initialization[0].ip_config[0].ipv4[0].address
}
