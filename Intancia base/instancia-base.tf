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
  // Local SSD disk
  scratch_disk {}

  network_interface {
    network = "default"

    access_config {
      // Ephemeral public IP
    }
  }
}