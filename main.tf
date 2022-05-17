resource "google_compute_instance" "default" {
  name         = "instancia-base"
  machine_type = var.machine_type
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

resource "time_sleep" "w60s" {
  depends_on = [google_compute_instance.default]
  create_duration = "60s"
}

resource "google_compute_image" "default" {
  depends_on = [time_sleep.w60s]
  name = "imagen-base"
  source_disk = google_compute_instance.default.boot_disk[0].source
}
///////////////////////////////////////////////////////////////////////////////////////
// Forwarding rule for Regional External Load Balancing
resource "google_compute_forwarding_rule" "default" {
  depends_on = [google_compute_subnetwork.proxy]
  name   = "website-forwarding-rule"

  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "80"
  target                = google_compute_region_target_http_proxy.default.id
  network               = google_compute_network.default.id
  ip_address            = google_compute_address.default.id
  network_tier          = "STANDARD"
}

resource "google_compute_region_target_http_proxy" "default" {
  name    = "website-proxy"
  url_map = google_compute_region_url_map.default.id
}

resource "google_compute_region_url_map" "default" {
  name            = "website-map"
  default_service = google_compute_region_backend_service.default.id
}

resource "google_compute_region_backend_service" "default" {

  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_instance_group_manager.rigm.instance_group
    balancing_mode = "UTILIZATION"
    capacity_scaler = 1.0
  }

  name        = "website-backend"
  protocol    = "HTTP"
  timeout_sec = 10
  health_checks = [google_compute_region_health_check.default.id]
}



resource "google_compute_instance_group_manager" "rigm" {

  name     = "website-rigm"
  version {
    instance_template = google_compute_instance_template.instance_template.id
    name              = "primary"
  }
  named_port {
    name = "http"
    port = 80
  }
  base_instance_name = "internal-glb"
  target_size        = 2
}

resource "google_compute_instance_template" "instance_template" {
  name         = "template-website-backend"
  machine_type = "e2-micro"

  network_interface {
    network = google_compute_network.default.id
    subnetwork = google_compute_subnetwork.default.id
  }

  disk {
    source_image = google_compute_image.default.self_link
    auto_delete  = true
    boot         = true
  }
  metadata_startup_script = file("${path.module}/config_ip_resp.sh")

  tags = ["allow-ssh", "load-balanced-backend", "http-server", "https-server"]
}

resource "google_compute_region_health_check" "default" {
  depends_on = [google_compute_firewall.fw4]
  name   = "website-hc"
  tcp_health_check {
    port = "80"
  }
}

resource "google_compute_address" "default" {
  name = "website-ip-1"
  network_tier = "STANDARD"
}

resource "google_compute_firewall" "fw1" {
  name = "website-fw-1"
  network = google_compute_network.default.id
  source_ranges = ["10.1.2.0/24"]
  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }
  direction = "INGRESS"
}

resource "google_compute_firewall" "fw2" {
  depends_on = [google_compute_firewall.fw1]
  name = "website-fw-2"
  network = google_compute_network.default.id
  source_ranges = ["0.0.0.0/0"]
  allow {
    protocol = "tcp"
    ports = ["22"]
  }
  target_tags = ["allow-ssh"]
  direction = "INGRESS"
}

resource "google_compute_firewall" "fw3" {
  depends_on = [google_compute_firewall.fw2]
  name = "website-fw-3"
  network = google_compute_network.default.id
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  allow {
    protocol = "tcp"
  }
  target_tags = ["load-balanced-backend"]
  direction = "INGRESS"
}

resource "google_compute_firewall" "fw4" {
  depends_on = [google_compute_firewall.fw3]
  name = "website-fw-4"
  network = google_compute_network.default.id
  source_ranges = ["10.129.0.0/26"]
  target_tags = ["load-balanced-backend"]
  allow {
    protocol = "tcp"
    ports = ["80"]
  }
  allow {
    protocol = "tcp"
    ports = ["443"]
  }
  allow {
    protocol = "tcp"
    ports = ["8000"]
  }
  direction = "INGRESS"
}

resource "google_compute_network" "default" {
  name                    = "website-net"
  auto_create_subnetworks = false
  routing_mode = "REGIONAL"
}

resource "google_compute_subnetwork" "default" {
  name          = "website-net-default"
  ip_cidr_range = "10.1.2.0/24"
  region        = "us-central1"
  network       = google_compute_network.default.id
}

resource "google_compute_subnetwork" "proxy" {
  name          = "website-net-proxy"
  ip_cidr_range = "10.129.0.0/26"
  #region        = "us-central1"
  network       = google_compute_network.default.id
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

resource "google_compute_autoscaler" "default" {
  name   = "autoscaler"
  #zone   = "us-central1-a"
  target = google_compute_instance_group_manager.rigm.id
  autoscaling_policy {
    max_replicas    = 2
    min_replicas    = 1
    cooldown_period = 60

    cpu_utilization {
      target = 0.4
    }
  }
}