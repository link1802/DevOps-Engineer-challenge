//creation of proyect and activation API Service
resource "google_project" "default" {
  name       = var.proyect_id
  project_id = var.proyect_id
  billing_account = var.proyect_billing_id
}
resource "google_project_service" "googleapis" {
  depends_on = [google_project.default]
  project = var.proyect_id
  service = "compute.googleapis.com"
  disable_dependent_services = true
}

//creation of VM before create a template
resource "google_compute_instance" "default" {
  depends_on = [google_project_service.googleapis]
  name         = var.vm_base_name
  machine_type = var.machine_type
  allow_stopping_for_update = true
  tags = ["allow-ssh", "load-balanced-backend", "http-server", "https-server"]
  
  boot_disk {
    initialize_params {
      image = var.vm_base_os
    }
  }
  //default interface for updates
  network_interface {
    network = "default"
    access_config {
      network_tier = "STANDARD"
    }
  }
  //script to install nginx on the VM
  metadata_startup_script = file("${path.module}/scripts/install_nginx.sh")
}
//////////////////////////////////////////////////////////////////////////////////

//delay for the shutdown of instance
resource "time_sleep" "w120s" {
  depends_on = [google_compute_instance.default]
  create_duration = "120s"
}

//create the template on base a VM shutdown
resource "google_compute_image" "default" {
  depends_on = [time_sleep.w120s]
  name = var.vm_image
  source_disk = google_compute_instance.default.boot_disk[0].source
}

///////////rules of firewall and networking//////////////
resource "google_compute_address" "default" {
  depends_on = [google_project_service.googleapis]
  name = "website-ip-1"
  network_tier = "STANDARD"
}

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

resource "google_compute_network" "default" {
  depends_on = [google_project_service.googleapis]
  name                    = "website-net"
  auto_create_subnetworks = false
  routing_mode = "REGIONAL"
}

resource "google_compute_subnetwork" "default" {
  name          = "website-net-default"
  ip_cidr_range = var.ip_range_lan
  region        = var.proyect_region
  network       = google_compute_network.default.id
}

resource "google_compute_subnetwork" "proxy" {
  name          = "website-net-proxy"
  ip_cidr_range = var.ip_range_proxy
  network       = google_compute_network.default.id
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

resource "google_compute_firewall" "rule1" {
  name = "website-fw-1"
  network = google_compute_network.default.id
  source_ranges = [var.ip_range_lan]
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

resource "google_compute_firewall" "rule2" {
  depends_on = [google_compute_firewall.rule1]
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

resource "google_compute_firewall" "rule4" {
  depends_on = [google_compute_firewall.rule3]
  name = "website-fw-3"
  network = google_compute_network.default.id
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  allow {
    protocol = "tcp"
  }
  target_tags = ["load-balanced-backend"]
  direction = "INGRESS"
}

resource "google_compute_firewall" "rule3" {
  depends_on = [google_compute_firewall.rule2]
  name = "website-fw-4"
  network = google_compute_network.default.id
  source_ranges = [var.ip_range_proxy]
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

////Creation of instance template////////////////////////////////////
resource "google_compute_instance_group_manager" "rigm" {
  name     = "website-rigm"
  version {
    instance_template = google_compute_instance_template.default.id
    name              = "primary"
  }
  named_port {
    name = "http"
    port = 80
  }
  base_instance_name = "internal-glb"
  target_size        = var.instance_group_size
}

resource "google_compute_instance_template" "default" {
  name         = "template-website-backend"
  machine_type = var.machine_type

  network_interface {
    network = google_compute_network.default.id
    subnetwork = google_compute_subnetwork.default.id
  }

  disk {
    source_image = google_compute_image.default.self_link
    auto_delete  = true
    boot         = true
  }
  //script to add the ip to nginx
  metadata_startup_script = file("${path.module}/scripts/config_ip_resp.sh")

  tags = ["allow-ssh", "load-balanced-backend", "http-server", "https-server"]
}

//check status of instance
resource "google_compute_region_health_check" "default" {
  depends_on = [google_compute_firewall.rule3]
  name   = "website-hc"
  tcp_health_check {
    port = "80"
  }
}

//automatic scale the number of instance
resource "google_compute_autoscaler" "default" {
  name   = "autoscaler"
  target = google_compute_instance_group_manager.rigm.id
  autoscaling_policy {
    max_replicas    = var.instance_autocaler_max
    min_replicas    = var.instance_autocaler_min
    cooldown_period = 60

    cpu_utilization {
      target = 0.4
    }
  }
}

//print the ip to make a get with curl
output "load-balancer-ip" {
  value = google_compute_address.default.address
}