provider "kubernetes" {
  host                   = "${google_container_cluster.default.endpoint}"
  token                  = "${data.google_client_config.current.access_token}"
  client_certificate     = "${base64decode(google_container_cluster.default.master_auth.0.client_certificate)}"
  client_key             = "${base64decode(google_container_cluster.default.master_auth.0.client_key)}"
  cluster_ca_certificate = "${base64decode(google_container_cluster.default.master_auth.0.cluster_ca_certificate)}"
}

resource "kubernetes_namespace" "staging" {
  metadata {
    name = "staging"
  }
}

resource "google_compute_address" "default" {
  name   = "${var.network_name}"
  region = "${var.region}"
}

resource "kubernetes_service" "nginx" {
  metadata {
    namespace = "${kubernetes_namespace.staging.metadata.0.name}"
    name      = "nginx"
  }

  spec {
    selector = {
      run = "nginx"
    }

    session_affinity = "ClientIP"

    port {
      protocol    = "TCP"
      port        = 80
      target_port = 80
    }

    type             = "LoadBalancer"
    load_balancer_ip = "${google_compute_address.default.address}"
  }
}

resource "kubernetes_replication_controller" "nginx" {
    metadata {
    name = "nginx"
    namespace = "${kubernetes_namespace.staging.metadata.0.name}"
    labels = {
      run = "nginx"
    }
  }

  spec {
    selector = {
      run = "nginx"
    }
    template {
      metadata {
        labels = {
          
        }
        annotations = {
          
        }
      }

      spec {
        container {
          image = "nginx:1.21.6"
          name  = "example"

          liveness_probe {
            http_get {
              path = "/"
              port = 80

              http_header {
                name  = "X-Custom-Header"
                value = "Awesome"
              }
            }

            initial_delay_seconds = 3
            period_seconds        = 3
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
}
