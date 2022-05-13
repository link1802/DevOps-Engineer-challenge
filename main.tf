resource "google_compute_autoscaler" "exam" {
  name   = "autocaler"
  zone   = "us-central1-a"
  target = google_compute_instance_group_manager.mig.id

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
################################################################################################
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
  purpose       = "REGIONAL_MANAGED_PROXY"
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

# forwarding rule
resource "google_compute_forwarding_rule" "google_compute_forwarding_rule" {
  name                  = "exam-forwarding-rule"
  provider              = google-beta
  region                = "us-central1"
  depends_on            = [google_compute_subnetwork.exam-proxy-subnet]
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "80"
  target                = google_compute_region_target_http_proxy.default.id
  network               = google_compute_network.exam-network.id
  subnetwork            = google_compute_subnetwork.exam-subnet.id
  network_tier          = "STANDARD"
}

# HTTP target proxy
resource "google_compute_region_target_http_proxy" "default" {
  name     = "exam-target-http-proxy"
  provider = google-beta
  region   = "us-central1"
  url_map  = google_compute_region_url_map.default.id
}

# URL map
resource "google_compute_region_url_map" "default" {
  name            = "exam-regional-url-map"
  provider        = google-beta
  region          = "us-central1"
  default_service = google_compute_region_backend_service.default.id
}

resource "google_compute_region_health_check" "default" {
  name     = "exam-hc"
  provider = google-beta
  region   = "us-central1"
  http_health_check {
    port_specification = "USE_SERVING_PORT"
  }
}

# backend service
resource "google_compute_region_backend_service" "default" {
  name                  = "exam-backend-subnet"
  provider              = google-beta
  region                = "us-central1"
  protocol              = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  timeout_sec           = 10
  health_checks         = [google_compute_region_health_check.default.id]
  backend {
    group           = google_compute_instance_group_manager.mig.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}

# MIG
resource "google_compute_instance_group_manager" "mig" {
  name = "group-skydrop"
  provider = google-beta
  zone = "us-central1-a"

  version {
    instance_template  = google_compute_instance_template.exam.id
    name               = "primary"
  }

  target_pools       = [google_compute_target_pool.exam.id]
  base_instance_name = "exam"

}
resource "google_compute_target_pool" "exam" {
  name = "exam-pool"
  region = "us-central1"
  health_checks = [google_compute_http_health_check.default.name,]
}
##############################################################################################
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

data "google_compute_image" "debian_11" {
  family  = "debian-11"
  project = "debian-cloud"
}
