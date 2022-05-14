resource "google_compute_instance" "default" {
  name         = "instancia-base"
  machine_type = "e2-micro"
  zone         = "us-central1-a"

  tags = ["allow-ssh", "load-balanced-backend", "http-server", "https-server"]

  disk {
    source_image = data.google_compute_image.debian_image.self_link
    auto_delete  = true
    boot         = true
  }

  // Local SSD disk
  scratch_disk {
    interface = "SCSI"
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral public IP
    }
  }

  data "google_compute_image" "debian_image" {
    provider = google-beta
    family   = "debian-11"
    project  = "debian-cloud"
  }
}