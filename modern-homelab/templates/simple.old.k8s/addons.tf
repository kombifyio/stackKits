# Modern Homelab - Helm Addons Module
# This module deploys Kubernetes addons via Helm
#
# Dependencies: Requires k3s cluster to be running

terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
  }
}

# -----------------------------------------------------------------------------
# VARIABLES
# -----------------------------------------------------------------------------

variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
}

variable "traefik" {
  description = "Traefik configuration"
  type = object({
    enabled      = bool
    version      = string
    namespace    = string
    replicas     = number
    tls_enabled  = bool
    tls_email    = string
  })
  default = {
    enabled      = true
    version      = "26.0.0"
    namespace    = "traefik-system"
    replicas     = 1
    tls_enabled  = true
    tls_email    = ""
  }
}

variable "longhorn" {
  description = "Longhorn configuration"
  type = object({
    enabled       = bool
    version       = string
    namespace     = string
    replicas      = number
    default_class = bool
  })
  default = {
    enabled       = true
    version       = "1.6.1"
    namespace     = "longhorn-system"
    replicas      = 2
    default_class = true
  }
}

variable "monitoring" {
  description = "Monitoring stack configuration"
  type = object({
    enabled           = bool
    version           = string
    namespace         = string
    prometheus_retention = string
    grafana_enabled   = bool
    alertmanager_enabled = bool
  })
  default = {
    enabled              = true
    version              = "57.2.0"
    namespace            = "monitoring"
    prometheus_retention = "15d"
    grafana_enabled      = true
    alertmanager_enabled = true
  }
}

variable "cert_manager" {
  description = "cert-manager configuration"
  type = object({
    enabled   = bool
    version   = string
    namespace = string
  })
  default = {
    enabled   = true
    version   = "1.14.4"
    namespace = "cert-manager"
  }
}

variable "loki" {
  description = "Loki logging configuration"
  type = object({
    enabled   = bool
    version   = string
    namespace = string
    retention = string
  })
  default = {
    enabled   = true
    version   = "2.10.2"
    namespace = "monitoring"
    retention = "168h"
  }
}

# -----------------------------------------------------------------------------
# PROVIDER CONFIGURATION
# -----------------------------------------------------------------------------

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}

# -----------------------------------------------------------------------------
# CERT-MANAGER
# -----------------------------------------------------------------------------

resource "helm_release" "cert_manager" {
  count = var.cert_manager.enabled ? 1 : 0

  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = var.cert_manager.version
  namespace        = var.cert_manager.namespace
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "resources.requests.cpu"
    value = "50m"
  }

  set {
    name  = "resources.requests.memory"
    value = "64Mi"
  }
}

# -----------------------------------------------------------------------------
# TRAEFIK INGRESS
# -----------------------------------------------------------------------------

resource "helm_release" "traefik" {
  count = var.traefik.enabled ? 1 : 0

  depends_on = [helm_release.cert_manager]

  name             = "traefik"
  repository       = "https://traefik.github.io/charts"
  chart            = "traefik"
  version          = var.traefik.version
  namespace        = var.traefik.namespace
  create_namespace = true

  set {
    name  = "deployment.replicas"
    value = var.traefik.replicas
  }

  set {
    name  = "ports.web.expose"
    value = "true"
  }

  set {
    name  = "ports.websecure.expose"
    value = "true"
  }

  set {
    name  = "ports.websecure.tls.enabled"
    value = var.traefik.tls_enabled
  }

  set {
    name  = "metrics.prometheus.enabled"
    value = "true"
  }

  set {
    name  = "resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "resources.requests.memory"
    value = "128Mi"
  }
}

# -----------------------------------------------------------------------------
# LONGHORN STORAGE
# -----------------------------------------------------------------------------

resource "helm_release" "longhorn" {
  count = var.longhorn.enabled ? 1 : 0

  name             = "longhorn"
  repository       = "https://charts.longhorn.io"
  chart            = "longhorn"
  version          = var.longhorn.version
  namespace        = var.longhorn.namespace
  create_namespace = true

  set {
    name  = "defaultSettings.defaultReplicaCount"
    value = var.longhorn.replicas
  }

  set {
    name  = "defaultSettings.defaultDataLocality"
    value = "best-effort"
  }

  set {
    name  = "persistence.defaultClass"
    value = var.longhorn.default_class
  }
}

# -----------------------------------------------------------------------------
# KUBE-PROMETHEUS-STACK (Prometheus + Grafana + Alertmanager)
# -----------------------------------------------------------------------------

resource "helm_release" "monitoring" {
  count = var.monitoring.enabled ? 1 : 0

  depends_on = [helm_release.longhorn]

  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = var.monitoring.version
  namespace        = var.monitoring.namespace
  create_namespace = true

  # Prometheus configuration
  set {
    name  = "prometheus.prometheusSpec.retention"
    value = var.monitoring.prometheus_retention
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.accessModes[0]"
    value = "ReadWriteOnce"
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
    value = "20Gi"
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName"
    value = "longhorn"
  }

  # Grafana configuration
  set {
    name  = "grafana.enabled"
    value = var.monitoring.grafana_enabled
  }

  set {
    name  = "grafana.persistence.enabled"
    value = "true"
  }

  set {
    name  = "grafana.persistence.size"
    value = "5Gi"
  }

  set {
    name  = "grafana.persistence.storageClassName"
    value = "longhorn"
  }

  # Alertmanager configuration
  set {
    name  = "alertmanager.enabled"
    value = var.monitoring.alertmanager_enabled
  }

  set {
    name  = "alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.accessModes[0]"
    value = "ReadWriteOnce"
  }

  set {
    name  = "alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.resources.requests.storage"
    value = "5Gi"
  }

  set {
    name  = "alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.storageClassName"
    value = "longhorn"
  }
}

# -----------------------------------------------------------------------------
# LOKI LOGGING STACK
# -----------------------------------------------------------------------------

resource "helm_release" "loki" {
  count = var.loki.enabled ? 1 : 0

  depends_on = [helm_release.longhorn]

  name             = "loki-stack"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "loki-stack"
  version          = var.loki.version
  namespace        = var.loki.namespace
  create_namespace = true

  set {
    name  = "loki.enabled"
    value = "true"
  }

  set {
    name  = "loki.persistence.enabled"
    value = "true"
  }

  set {
    name  = "loki.persistence.size"
    value = "20Gi"
  }

  set {
    name  = "loki.persistence.storageClassName"
    value = "longhorn"
  }

  set {
    name  = "loki.config.table_manager.retention_deletes_enabled"
    value = "true"
  }

  set {
    name  = "loki.config.table_manager.retention_period"
    value = var.loki.retention
  }

  set {
    name  = "promtail.enabled"
    value = "true"
  }
}

# -----------------------------------------------------------------------------
# OUTPUTS
# -----------------------------------------------------------------------------

output "addons_installed" {
  description = "List of installed addons"
  value = compact([
    var.cert_manager.enabled ? "cert-manager" : "",
    var.traefik.enabled ? "traefik" : "",
    var.longhorn.enabled ? "longhorn" : "",
    var.monitoring.enabled ? "kube-prometheus-stack" : "",
    var.loki.enabled ? "loki-stack" : "",
  ])
}

output "traefik_namespace" {
  description = "Traefik namespace"
  value       = var.traefik.enabled ? var.traefik.namespace : ""
}

output "monitoring_namespace" {
  description = "Monitoring namespace"
  value       = var.monitoring.enabled ? var.monitoring.namespace : ""
}

output "longhorn_namespace" {
  description = "Longhorn namespace"
  value       = var.longhorn.enabled ? var.longhorn.namespace : ""
}
