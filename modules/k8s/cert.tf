resource "kubernetes_deployment_v1" "cert_deploy" {
  provider = kubernetes
  metadata {
    name = "cert-deploy"
    labels = {
      app = "cert"
    }
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "cert"
      }
    }
    template {
      metadata {
        labels = {
          app = "cert"
        }
      }
      spec {
        container {
          name  = "cert-ctn"
          image = "jinsse/univ-nginx:1.0"
          port {
            container_port = 80
          }
          resources {
            limits = {
              memory = "3600Mi"
              cpu    = "900m"
            }
            requests = {
              memory = "3600Mi"
              cpu    = "900m"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "cert_service" {
  provider = kubernetes
  metadata {
    name = "cert-service"
  }
  spec {
    selector = {
      app = "cert"
    }
    port {
      protocol    = "TCP"
      port        = 80
      target_port = 80
    }
  }
}