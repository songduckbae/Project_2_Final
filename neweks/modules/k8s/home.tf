resource "kubernetes_deployment_v1" "home_deploy" {
  provider = kubernetes
  metadata {
    name = "home-deploy"
    labels = {
      app = "home"
    }
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "home"
      }
    }
    template {
      metadata {
        labels = {
          app = "home"
        }
      }
      spec {
        container {
          name  = "home-ctn"
          image = "jinsse/univ-nginx:1.0"
          port {
            container_port = 80
          }
          resources {
            limits = {
              memory = "32Mi"
              cpu    = "250m"
            }
            requests = {
              memory = "32Mi"
              cpu    = "250m"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "home_service" {
  provider = kubernetes
  metadata {
    name = "home-service"
  }
  spec {
    selector = {
      app = "home"
    }
    port {
      protocol    = "TCP"
      port        = 80
      target_port = 80
    }
  }
}