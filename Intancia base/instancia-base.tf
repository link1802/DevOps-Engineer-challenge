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

resource "google_compute_snapshot" "snapshot" {
  name        = "snapshot-base"
  source_disk = google_compute_instance.default.boot_disk[0].source

  zone        = "us-central1-a"
  storage_locations = ["us"]
}

resource "google_compute_image" "default" {
  name = "imagen-base"
  source_snapshot = google_compute_snapshot.snapshot.self_link

}

resource "google_compute_instance_template" "instance_template" {
  provider     = google-beta
  name         = "template-website-backend"
  machine_type = "e2-micro"

  network_interface {
    network = "default"
  }

  disk {
    source_image = data.google_compute_image.default.self_link
    auto_delete  = true
    boot         = true
  }

  tags = ["allow-ssh", "load-balanced-backend", "http-server", "https-server"]
}