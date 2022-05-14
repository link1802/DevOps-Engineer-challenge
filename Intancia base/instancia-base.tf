resource "google_compute_instance" "default" {
  name         = "instancia-base"
  machine_type = "e2-micro"
  zone         = "us-central1-a"

  tags = ["allow-ssh", "load-balanced-backend", "http-server", "https-server"]

  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  data "google_compute_image" "debian_image" {
    provider = google-beta
    family   = "debian-11"
    project  = "debian-cloud"
  }
  disk {
    source_image = data.google_compute_image.debian_image.self_link
    auto_delete  = true
    boot         = true
  }
  
  network_interface {
    network = "default"

    access_config {
      // Ephemeral public IP
    }
  }
}