resource "google_compute_autoscaler" "exam" {
  name   = "autocaler"
  zone   = "us-central1-a"
  target = google_compute_instance_group_manager.exam.id

  autoscaling_policy {
    max_replicas    = 2
    min_replicas    = 1
    cooldown_period = 60

    cpu_utilization {
      target = 0.4
    }
  }
}

resource "google_compute_address" "static" {
  name = "ipv4-address"
  region = "us-central1"
}

# VPC network
resource "google_compute_network" "exam-network" {
  name                    = "exam-network"
  provider                = google-beta
  auto_create_subnetworks = false
}

# proxy-only subnet
resource "google_compute_subnetwork" "exam-proxy-subnet" {
  name          = "exam-proxy-subnet"
  provider      = google-beta
  ip_cidr_range = "10.0.0.0/24"
  region        = "us-central1"
  purpose       = "INTERNAL_HTTPS_LOAD_BALANCER"
  role          = "ACTIVE"
  network       = google_compute_network.exam-network.id
}

# backend subnet
resource "google_compute_subnetwork" "exam-subnet" {
  name          = "exam-subnet"
  provider      = google-beta
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-central1"
  network       = google_compute_network.exam-network.id
}

resource "google_compute_instance_template" "exam" {
  name           = "instance-template-1"
  machine_type   = "n2-standard-2"
  can_ip_forward = false

  network_interface {
    subnetwork = google_compute_subnetwork.exam-proxy-subnet.id
  }

  disk {
    source_image = data.google_compute_image.debian_11.id
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }

metadata_startup_script = file("${path.module}/template/install_nginx.sh")
}

resource "google_compute_http_health_check" "default" {
  name               = "default"
  request_path       = "/"
  check_interval_sec = 1
  timeout_sec        = 1
}

resource "google_compute_target_pool" "exam" {
  name = "exam-pool"
  region = "us-central1"
  health_checks = [google_compute_http_health_check.default.name,]
}
resource "google_compute_instance_group_manager" "exam" {
  name = "group-skydrop"
  zone = "us-central1-a"

  version {
    instance_template  = google_compute_instance_template.exam.id
    name               = "primary"
  }

  target_pools       = [google_compute_target_pool.exam.id]
  base_instance_name = "exam"
}


data "google_compute_image" "debian_11" {
  family  = "debian-11"
  project = "debian-cloud"
}
