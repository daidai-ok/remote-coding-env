# Cloud DNS inbound forwarding policy
# Allows resolving GCE internal hostnames (<vm>.<project>.internal)
# from other devices on the Tailscale network
resource "google_dns_policy" "inbound_dns" {
  name        = "${var.network_name}-inbound-dns"
  description = "Expose DNS endpoints for Tailscale subnet router"

  enable_inbound_forwarding = true

  networks {
    network_url = google_compute_network.dev.id
  }
}
