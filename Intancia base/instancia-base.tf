resource "google_compute_instance" "default" {
  name         = "instancia-base"
  machine_type = "e2-micro"
  zone         = "us-central1-a"
  allow_stopping_for_update = true
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

resource "time_sleep" "60s" {
  depends_on = [google_compute_instance.default]

  create_duration = "60s"
}

resource "google_compute_image" "default" {
  depends_on = [time_sleep.60s]
  name = "imagen-base"
  source_disk = google_compute_instance.default.boot_disk[0].source
}