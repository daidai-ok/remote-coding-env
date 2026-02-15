output "vm_name" {
  description = "Name of the development VM"
  value       = google_compute_instance.dev.name
}

output "vm_internal_ip" {
  description = "Internal IP address of the VM"
  value       = google_compute_instance.dev.network_interface[0].network_ip
}

output "service_account_email" {
  description = "Service account email attached to the VM"
  value       = google_service_account.dev_vm.email
}

output "subnet_cidr" {
  description = "Subnet CIDR advertised via Tailscale"
  value       = google_compute_subnetwork.dev.ip_cidr_range
}

output "dns_resolver_lookup_command" {
  description = "Command to find the DNS resolver IP for Tailscale split DNS configuration"
  value       = "gcloud compute addresses list --project=${var.project_id} --filter='purpose=\"DNS_RESOLVER\"' --format='csv(address, region, subnetwork)'"
}

output "tailscale_status_command" {
  description = "Command to check Tailscale status on the VM"
  value       = "gcloud compute ssh ${google_compute_instance.dev.name} --zone=${var.zone} --tunnel-through-iap -- tailscale status"
}
