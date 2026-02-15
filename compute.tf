data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2204-lts"
  project = "ubuntu-os-cloud"
}

resource "google_service_account" "dev_vm" {
  account_id   = "${var.vm_name}-sa"
  display_name = "Service account for ${var.vm_name}"
}

resource "google_compute_instance" "dev" {
  name         = var.vm_name
  machine_type = var.machine_type
  zone         = var.zone

  # Required for Tailscale subnet routing
  can_ip_forward = true

  tags = ["tailscale", "iap-ssh"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = var.boot_disk_size
      type  = "pd-ssd"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.dev.id
    # No external IP — outbound traffic goes through Cloud NAT
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = templatefile("${path.module}/scripts/startup.sh", {
    tailscale_auth_key = var.tailscale_auth_key
    subnet_cidr        = var.subnet_cidr
  })

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  service_account {
    email = google_service_account.dev_vm.email
    scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
    ]
  }

  scheduling {
    # Not preemptible — development VM should be stable
    preemptible       = false
    automatic_restart = true
  }

  lifecycle {
    ignore_changes = [
      # Ignore changes to startup script after initial creation
      # to avoid unnecessary VM recreation
      metadata_startup_script,
    ]
  }
}
