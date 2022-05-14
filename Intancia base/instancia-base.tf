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

resource "google_compute_image" "default" {
  name = "imagen-base"
  source_disk = "instancia-base"
  source-disk-zone = "us-central1-a"
  storage-location= "us"
}