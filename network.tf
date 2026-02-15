resource "google_compute_network" "dev" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "dev" {
  name                     = "${var.network_name}-subnet"
  ip_cidr_range            = var.subnet_cidr
  region                   = var.region
  network                  = google_compute_network.dev.id
  private_ip_google_access = true
}

# Allow Tailscale direct connections (UDP 41641) for NAT traversal
resource "google_compute_firewall" "allow_tailscale_udp" {
  name    = "${var.network_name}-allow-tailscale-udp"
  network = google_compute_network.dev.id

  allow {
    protocol = "udp"
    ports    = ["41641"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["tailscale"]
}

# Allow SSH via IAP (Identity-Aware Proxy) as fallback
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "${var.network_name}-allow-iap-ssh"
  network = google_compute_network.dev.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # IAP's IP range
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["iap-ssh"]
}

# Block direct SSH from the internet
resource "google_compute_firewall" "deny_direct_ssh" {
  name     = "${var.network_name}-deny-direct-ssh"
  network  = google_compute_network.dev.id
  priority = 65534

  deny {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["tailscale"]
}

# Allow internal communication within the VPC
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.network_name}-allow-internal"
  network = google_compute_network.dev.id

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.subnet_cidr]
}

# Cloud Router and NAT for outbound internet access without external IP
resource "google_compute_router" "dev" {
  name    = "${var.network_name}-router"
  region  = var.region
  network = google_compute_network.dev.id
}

resource "google_compute_router_nat" "dev" {
  name                               = "${var.network_name}-nat"
  router                             = google_compute_router.dev.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
