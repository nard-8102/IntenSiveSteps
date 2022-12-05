locals {
 wordpress_labels = {
   App = "wordpress"
   Tier = "frontend"
 }
 mysql_labels = {
   App = "wordpress"
   Tier = "mysql"
 }
}

resource "kubernetes_secret" "mysql-pass" {
 metadata {
   name = "mysql-pass"
 }
 data = {
   password = "root"
 }
}

resource "kubernetes_deployment" "wordpress" {
 metadata {
   name = "wordpress"
   labels = local.wordpress_labels
 }
 spec {
   replicas = 1
   selector {
     match_labels = local.wordpress_labels
   }
   template {
     metadata {
       labels = local.wordpress_labels
     }
     spec {
       container {
         image = "wordpress:6.1-apache"
         name  = "wordpress"
         port {
           container_port = 80
         }
         env {
           name = "WORDPRESS_DB_HOST"
           value = "mysql-service"
         }
         env {
           name = "WORDPRESS_DB_PASSWORD"
           value_from {
             secret_key_ref {
               name = "mysql-pass"
               key = "password"
             }
           }
         }
       }
     }
   }
 }
}

resource "kubernetes_service" "wordpress-service" {
 metadata {
   name = "wordpress-service"
 }
 spec {
   selector = local.wordpress_labels
   port {
     port        = 80
     target_port = 80
     node_port = 32000
   }
   type = "NodePort"
 }
}

resource "kubernetes_deployment" "mysql" {
 metadata {
   name = "mysql"
   labels = local.mysql_labels
 }
 spec {
   replicas = 1
   selector {
     match_labels = local.mysql_labels
   }
   template {
     metadata {
       labels = local.mysql_labels
     }
     spec {
       container {
         image = "mysql:5.6"
         name  = "mysql"
         port {
           container_port = 3306
         }
         env {
           name = "MYSQL_ROOT_PASSWORD"
           value_from {
             secret_key_ref {
               name = "mysql-pass"
               key = "password"
             }
           }
         }
       }
     }
   }
 }
}

resource "kubernetes_service" "mysql-service" {
 metadata {
   name = "mysql-service"
 }
 spec {
   selector = local.mysql_labels
   port {
     port        = 3306
     target_port = 3306
   }
   type = "NodePort"
 }
}