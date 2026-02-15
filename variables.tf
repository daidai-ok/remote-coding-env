variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "asia-northeast1"
}

variable "zone" {
  description = "GCP zone for the VM"
  type        = string
  default     = "asia-northeast1-a"
}

variable "vm_name" {
  description = "Name of the development VM"
  type        = string
  default     = "dev-vm"
}

variable "machine_type" {
  description = "GCE machine type"
  type        = string
  default     = "e2-medium"
}

variable "boot_disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 50
}

variable "network_name" {
  description = "VPC network name"
  type        = string
  default     = "dev-network"
}

variable "subnet_cidr" {
  description = "CIDR range for the subnet"
  type        = string
  default     = "10.10.0.0/24"
}

variable "tailscale_auth_key" {
  description = "Tailscale auth key for automatic device registration"
  type        = string
  sensitive   = true
}
