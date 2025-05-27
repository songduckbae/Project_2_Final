resource "kubernetes_ingress_v1" "univ_ingress_new" {
  provider = kubernetes

  metadata {
    name      = "univ-ingress"
    namespace = "default"
    annotations = {
      # "kubernetes.io/ingress.class"              = "alb"    
      "alb.ingress.kubernetes.io/scheme"         = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"    = "ip"
      "alb.ingress.kubernetes.io/listen-ports"   = jsonencode([{ HTTP = 80 }])
    }
  }

  spec {
    ingress_class_name = "alb"
    rule {
      http {
        path {
          path      = "/cert"
          path_type = "Prefix"

          backend {
            service {
              name = "cert-service"
              port {
                number = 80
              }
            }
          }
        }

        path {
          path      = "/class"
          path_type = "Prefix"

          backend {
            service {
              name = "class-service"
              port {
                number = 80
              }
            }
          }
        }

        path {
          path      = "/home"
          path_type = "Prefix"

          backend {
            service {
              name = "home-service"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
