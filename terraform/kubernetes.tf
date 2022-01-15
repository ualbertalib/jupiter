data "local_file" "masterkey" {
  filename = "../config/master.key"
}

resource "kubernetes_namespace" "namespace" {
  metadata {
    name = "${var.app-name}"
  }
}

# TODO: Add Helm Chart for Solr and configure accordingly

resource "helm_release" "ingress-nginx" {
  depends_on = [local_file.kubeconfig, kubernetes_namespace.namespace]
  name       = "${var.app-name}-ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace =  "${var.app-name}"
}

resource "kubernetes_config_map" "config" {
  depends_on = [azurerm_redis_cache.redis, azurerm_postgresql_database.postgresql-db, azurerm_storage_container.storage_container]

  metadata {
    name = "${var.app-name}-config"
    namespace = "${var.app-name}"
  }

  # TODO: Replace with Jupiter ENV VARs here
  data = {
    RAILS_MASTER_KEY = data.local_file.masterkey.content
    PORT = "3000"
    RAILS_LOG_TO_STDOUT = "true"
    RAILS_ENV = "production"
    DB_HOST = azurerm_postgresql_server.db.fqdn
    DB_USER = "${var.postgresql-admin-login}@${azurerm_postgresql_server.db.name}"
    DB_PASSWORD = var.postgresql-admin-password
    REDIS_URL = "redis://:${urlencode(azurerm_redis_cache.redis.primary_access_key)}@${azurerm_redis_cache.redis.hostname}:${azurerm_redis_cache.redis.port}/0"
    AZURE_STORAGE_ACCOUNT_NAME = azurerm_storage_account.blob_account.name
    AZURE_STORAGE_ACCESS_KEY = azurerm_storage_account.blob_account.primary_access_key
    AZURE_STORAGE_CONTAINER = azurerm_storage_container.storage_container.name
  }
}

resource "kubernetes_deployment" "app" {
  depends_on = [kubernetes_config_map.config]

  metadata {
    name = "${var.app-name}-app"
    labels = {
      app = "${var.app-name}"
    }
    namespace = "${var.app-name}"
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "${var.app-name}"
      }
    }

    template {
      metadata {
        name = "${var.app-name}"
        labels = {
          app = "${var.app-name}"
        }
      }

      spec {
        init_container {
          image = "ualberta/jupiter:latest"
          image_pull_policy = "Always"
          name = "${var.app-name}-init"
          command = ["rake", "db:migrate"]
          env_from {
            config_map_ref {
              name = "${var.app-name}-config"
            }
          }
        }
        container {
          image = "ualberta/jupiter:latest"
          image_pull_policy = "Always"
          name = "${var.app-name}"
          port {
            container_port = 3000
          }
          env_from {
            config_map_ref {
              name = "${var.app-name}-config"
            }
          }
          readiness_probe {
            http_get {
              path = "/healthcheck"
              port = 3000
            }
            initial_delay_seconds = 10
            period_seconds = 10
            timeout_seconds = 2
          }
          resources {
            limits = {
              cpu    = "250m"
              memory = "256Mi"
            }
            requests = {
              cpu    = "150m"
              memory = "128Mi"
            }
          }
        }
        restart_policy = "Always"
      }
    }
  }
}

resource "kubernetes_deployment" "worker" {
  depends_on = [kubernetes_config_map.config]

  metadata {
    name = "${var.app-name}-workers"
    namespace = "${var.app-name}"

  }
  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "${var.app-name}-workers"
      }
    }

    template {
      metadata {
        name = "${var.app-name}-workers"
        labels = {
          app = "${var.app-name}-workers"
        }
      }

      spec {
        container {
          name = "${var.app-name}-workers"
          image = "ualberta/jupiter:latest"
          image_pull_policy = "Always"
          command = ["bundle",  "exec", "sidekiq"]

          env_from {
            config_map_ref {
              name = "${var.app-name}-config"
            }
          }
          resources {
            limits = {
              cpu    = "250m"
              memory = "256Mi"
            }
            requests = {
              cpu    = "150m"
              memory = "128Mi"
            }
          }

          readiness_probe {
            exec {
              command = [ "cat", "/app/tmp/sidekiq_process_has_started_and_will_begin_processing_jobs"]
            }

            failure_threshold = 10
            initial_delay_seconds = 10
            period_seconds = 2
            success_threshold = 2
            timeout_seconds = 1
          }
        }
        restart_policy = "Always"
        termination_grace_period_seconds = 60
      }
    }
  }
}

resource "kubernetes_service" "service" {
  metadata {
    name = "${var.app-name}-service"
    namespace = "${var.app-name}"
  }

  spec {
    port {
      port = 80
      target_port = 3000
    }

    type = "NodePort"

    selector = {
      app = "${var.app-name}"
    }
  }
}

resource "kubernetes_ingress" "ingress" {
  wait_for_load_balancer = true
  metadata {
    name = "${var.app-name}-ingress"
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
    }
    namespace = "${var.app-name}"
  }
  spec {
    rule {
      # TODO: Figure out how we will use DNS/etc
      # host = "uat.era.library.ualberta.ca"
      http {
        path {
          path = "/"
          backend {
            service_name = "${var.app-name}-service"
            service_port = 80
          }
        }
      }
    }
  }
}
