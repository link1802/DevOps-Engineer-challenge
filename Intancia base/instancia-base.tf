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
  
  network_interface {
    network = "default"

    access_config {
      network_tier = "STANDARD"
    }
  }
  metadata_startup_script = file("${path.module}/install_nginx.sh")
}

resource "google_compute_machine_image" "image" {
  provider        = google-beta
  name            = "image-base"
  source_instance = google_compute_instance.default.self_link
}