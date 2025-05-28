resource "kubernetes_deployment_v1" "class_deploy" {
  provider = kubernetes
  metadata {
    name = "class-deploy"
    labels = {
      app = "class"
    }
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "class"
      }
    }
    template {
      metadata {
        labels = {
          app = "class"
        }
      }
      spec {
        container {
          name  = "class-ctn"
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

resource "kubernetes_service_v1" "class_service" {
  provider = kubernetes
  metadata {
    name = "class-service"
  }
  spec {
    selector = {
      app = "class"
    }
    port {
      protocol    = "TCP"
      port        = 80
      target_port = 80
    }
  }
}