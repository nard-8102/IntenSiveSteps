resource "kubernetes_deployment" "hello-node" {
  metadata {
    name = "tf-hellonode"
    labels = {
      test = "frontnode"
    }
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        test = "frontnode"
      }
    }

    template {
      metadata {
        labels = {
          test = "frontnode"
        }
      }

      spec {
        container {
          image = "yeasy/simple-web"
          name  = "webapp"

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
        }
      }
    }
  }
}

resource "kubernetes_service" "hellonode-service" {
 metadata {
   name = "tf-hellonode"
 }
 spec {
   selector = kubernetes_deployment.hello-node.metadata.0.labels
   port {
     port        = 80
     target_port = 80
     node_port = 32000
   }
   type = "NodePort"
 }
}