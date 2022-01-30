resource "kubernetes_namespace" "namespace" {
  metadata {
    name = "${var.app-name}"
  }
}

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

# Rails application env variables
  data = {
    RAILS_ENV = "uat"
    RAILS_LOG_TO_STDOUT = "true"
    RAILS_SERVE_STATIC_FILES = "true"
    DATABASE_URL = "postgresql://${urlencode("${var.postgresql-admin-login}@${azurerm_postgresql_server.db.name}")}:${urlencode(var.postgresql-admin-password)}@${azurerm_postgresql_server.db.fqdn}:5432/${azurerm_postgresql_database.postgresql-db.name}"
    SOLR_URL = "http://${var.app-name}-solr:8983/solr/jupiter-uat"
    REDIS_URL = "redis://:${urlencode(azurerm_redis_cache.redis.primary_access_key)}@${azurerm_redis_cache.redis.hostname}:${azurerm_redis_cache.redis.port}/0"
    SECRET_KEY_BASE = "${var.rails-secret-key}"
    SAML_PRIVATE_KEY = ""
    SAML_CERTIFICATE = ""
    ROLLBAR_TOKEN = ""
    GOOGLE_ANALYTICS_TOKEN = ""
    TLD_LENGTH = "3"
    GOOGLE_CLIENT_ID = ""
    GOOGLE_CLIENT_SECRET = ""
    GOOGLE_DEVELOPER_KEY = ""
    ERA_HOST = "era.uat.library.ualberta.ca"
    DIGITIZATION_HOST = "digitalcollections.uat.library.ualberta.ca"
    SKYLIGHT_AUTHENTICATION = "secretauthenticationtoken"
    ACTIVE_STORAGE_SERVICE = "microsoft"
    AZURE_STORAGE_ACCOUNT_NAME = azurerm_storage_account.blob_account.name
    AZURE_STORAGE_ACCESS_KEY = azurerm_storage_account.blob_account.primary_access_key
    AZURE_STORAGE_CONTAINER = azurerm_storage_container.storage_container.name
  }
}


resource "kubernetes_config_map" "solr-config" {
  metadata {
    name = "${var.app-name}-solr-config"
    namespace = "${var.app-name}"
  }

  data = {
    "schema.xml" = "${file("${path.module}/../solr/config/schema.xml")}"
    "solrconfig.xml" = "${file("${path.module}/../solr/config/solrconfig.xml")}"
  }
}

resource "kubernetes_deployment" "solr" {
  metadata {
    name = "${var.app-name}-solr"
    labels = {
      app = "${var.app-name}"
    }
    namespace = "${var.app-name}"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "${var.app-name}-solr"
      }
    }

    template {
      metadata {
        name = "${var.app-name}-solr"
        labels = {
          app = "${var.app-name}-solr"
        }
      }

      spec {
        container {
          image = "solr:6.6"
          image_pull_policy = "Always"
          name = "${var.app-name}-solr"
          command = ["docker-entrypoint.sh",  "solr-precreate", "jupiter-uat", "/config"]
          port {
            container_port = 8983
          }
          volume_mount {
            name = "solr-config"
            mount_path = "/config"
          }
          resources {
            limits = {
              cpu    = "250m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "150m"
              memory = "128Mi"
            }
          }
        }
        volume {
          name = "solr-config"
          config_map {
            name = "${var.app-name}-solr-config"
          }
        }
        restart_policy = "Always"
      }
    }
  }
}

resource "kubernetes_service" "solr-service" {
  metadata {
    name = "${var.app-name}-solr"
    namespace = "${var.app-name}"
  }

  spec {
    port {
      port = 8983
      target_port = 8983
    }

    selector = {
      app = "${var.app-name}-solr"
    }
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
          image = "murny/jupiter:latest"
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
          image = "murny/jupiter:latest"
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
          # TODO: Figure out workaround with config.hosts
          # readiness_probe {
          #   http_get {
          #     path = "/healthcheck"
          #     port = 3000
          #   }
          #   initial_delay_seconds = 10
          #   period_seconds = 10
          #   timeout_seconds = 2
          # }
          resources {
            limits = {
              cpu    = "250m"
              memory = "512Mi"
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
          image = "murny/jupiter:latest"
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
              memory = "512Mi"
            }
            requests = {
              cpu    = "150m"
              memory = "128Mi"
            }
          }

          readiness_probe {
            exec {
              command = [ "cat", "/app/tmp/sidekiq_process_has_started"]
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
      "nginx.ingress.kubernetes.io/proxy-body-size" = "16m"
    }
    namespace = "${var.app-name}"
  }
  spec {
    rule {
      # TODO: Figure out how we will use DNS/etc
      host = "*.uat.library.ualberta.ca"
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
