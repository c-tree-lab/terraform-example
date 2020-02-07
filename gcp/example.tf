variable "gcp_credentials" {}
variable "project_id" {}

variable "local_ip" {}
variable "username" {}
variable "ssh_public_key" {}

provider "google" {
 credentials = var.gcp_credentials
 project     = var.project_id
 region      = "asia-northeast1"
}

resource "google_compute_firewall" "allow-ssh" {
  name    = "allow-ssh"
  network = "default"
  priority = 99
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = [var.local_ip]
}

resource "google_compute_firewall" "deny-ssh" {
  name    = "deny-ssh"
  network = "default"
  priority = 100
  deny {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_address" "default" {
  name = "external-network"
}

resource "google_compute_instance" "default" {
  name         = "test"
  machine_type = "f1-micro"
  zone         = "asia-northeast1-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = "${google_compute_address.default.address}"
    }
  }

  metadata = {
    "block-project-ssh-keys" = "true"
    "ssh-keys" = "${var.username}:${var.ssh_public_key}"
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
}

output "public_ip" {
  value = "${google_compute_address.default.address}"
}
