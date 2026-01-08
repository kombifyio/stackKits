# Modern Homelab - Simple OpenTofu Template
# This template deploys a multi-node k3s cluster with GitOps
#
# Status: ALPHA - Core k3s deployment implemented
#
# Deployment order:
# 1. k3s server (init node)
# 2. k3s servers (join nodes, if HA)
# 3. k3s agents (worker nodes)
# 4. Kubernetes addons via Helm

terraform {
  required_version = ">= 1.6.0"
  
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

# -----------------------------------------------------------------------------
# VARIABLES
# -----------------------------------------------------------------------------

variable "cluster_name" {
  description = "Name of the k3s cluster"
  type        = string
  default     = "homelab"
}

variable "k3s_version" {
  description = "k3s version to install"
  type        = string
  default     = "v1.30.2+k3s1"
}

variable "cluster_token" {
  description = "Cluster join token (auto-generated if empty)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "nodes" {
  description = "Node definitions"
  type = list(object({
    name     = string
    role     = string # server or agent
    ip       = string
    ssh_user = string
    ssh_key  = string
  }))
}

variable "network" {
  description = "Network configuration"
  type = object({
    service_cidr = string
    cluster_cidr = string
    cluster_dns  = string
  })
  default = {
    service_cidr = "10.43.0.0/16"
    cluster_cidr = "10.42.0.0/16"
    cluster_dns  = "10.43.0.10"
  }
}

variable "cni" {
  description = "CNI configuration"
  type = object({
    plugin          = string
    flannel_backend = string
  })
  default = {
    plugin          = "flannel"
    flannel_backend = "vxlan"
  }
}

variable "disable_components" {
  description = "Components to disable in k3s"
  type        = list(string)
  default     = ["traefik", "local-storage"]
}

# -----------------------------------------------------------------------------
# LOCALS
# -----------------------------------------------------------------------------

locals {
  # Generate token if not provided
  cluster_token = var.cluster_token != "" ? var.cluster_token : random_password.cluster_token[0].result

  # Separate server and agent nodes
  server_nodes = [for n in var.nodes : n if n.role == "server"]
  agent_nodes  = [for n in var.nodes : n if n.role == "agent"]

  # First server is the init server
  init_server = local.server_nodes[0]

  # Additional servers join the first
  join_servers = length(local.server_nodes) > 1 ? slice(local.server_nodes, 1, length(local.server_nodes)) : []

  # Disable components as CLI args
  disable_args = join(" ", [for c in var.disable_components : "--disable=${c}"])
}

# Random token generation
resource "random_password" "cluster_token" {
  count   = var.cluster_token == "" ? 1 : 0
  length  = 64
  special = false
}

# -----------------------------------------------------------------------------
# K3S SERVER INSTALLATION (INIT NODE)
# -----------------------------------------------------------------------------

resource "null_resource" "k3s_server_init" {
  triggers = {
    cluster_token = local.cluster_token
    k3s_version   = var.k3s_version
    node_ip       = local.init_server.ip
  }

  connection {
    type        = "ssh"
    host        = local.init_server.ip
    user        = local.init_server.ssh_user
    private_key = file(local.init_server.ssh_key)
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "#!/bin/bash",
      "set -euo pipefail",
      "",
      "echo 'Installing k3s server (init node)...'",
      "",
      "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='${var.k3s_version}' sh -s - server \\",
      "  --cluster-init \\",
      "  --token='${local.cluster_token}' \\",
      "  --flannel-backend=${var.cni.flannel_backend} \\",
      "  --service-cidr=${var.network.service_cidr} \\",
      "  --cluster-cidr=${var.network.cluster_cidr} \\",
      "  --cluster-dns=${var.network.cluster_dns} \\",
      "  ${local.disable_args}",
      "",
      "echo 'Waiting for k3s to be ready...'",
      "until sudo kubectl get nodes 2>/dev/null; do sleep 5; done",
      "echo 'k3s server init complete!'",
    ]
  }
}

# -----------------------------------------------------------------------------
# K3S SERVER INSTALLATION (JOIN NODES)
# -----------------------------------------------------------------------------

resource "null_resource" "k3s_server_join" {
  for_each = { for idx, node in local.join_servers : node.name => node }

  depends_on = [null_resource.k3s_server_init]

  triggers = {
    cluster_token = local.cluster_token
    k3s_version   = var.k3s_version
    node_ip       = each.value.ip
  }

  connection {
    type        = "ssh"
    host        = each.value.ip
    user        = each.value.ssh_user
    private_key = file(each.value.ssh_key)
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "#!/bin/bash",
      "set -euo pipefail",
      "",
      "echo 'Joining k3s server cluster...'",
      "",
      "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='${var.k3s_version}' sh -s - server \\",
      "  --server=https://${local.init_server.ip}:6443 \\",
      "  --token='${local.cluster_token}'",
      "",
      "echo 'k3s server join complete!'",
    ]
  }
}

# -----------------------------------------------------------------------------
# K3S AGENT INSTALLATION
# -----------------------------------------------------------------------------

resource "null_resource" "k3s_agent" {
  for_each = { for idx, node in local.agent_nodes : node.name => node }

  depends_on = [null_resource.k3s_server_init]

  triggers = {
    cluster_token = local.cluster_token
    k3s_version   = var.k3s_version
    node_ip       = each.value.ip
  }

  connection {
    type        = "ssh"
    host        = each.value.ip
    user        = each.value.ssh_user
    private_key = file(each.value.ssh_key)
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "#!/bin/bash",
      "set -euo pipefail",
      "",
      "echo 'Installing k3s agent...'",
      "",
      "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='${var.k3s_version}' sh -s - agent \\",
      "  --server=https://${local.init_server.ip}:6443 \\",
      "  --token='${local.cluster_token}'",
      "",
      "echo 'k3s agent installation complete!'",
    ]
  }
}

# -----------------------------------------------------------------------------
# KUBECONFIG RETRIEVAL
# -----------------------------------------------------------------------------

resource "null_resource" "kubeconfig" {
  depends_on = [null_resource.k3s_server_init]

  triggers = {
    server_ip = local.init_server.ip
  }

  connection {
    type        = "ssh"
    host        = local.init_server.ip
    user        = local.init_server.ssh_user
    private_key = file(local.init_server.ssh_key)
    timeout     = "2m"
  }

  provisioner "local-exec" {
    command = <<-EOT
      ssh -o StrictHostKeyChecking=no -i ${local.init_server.ssh_key} ${local.init_server.ssh_user}@${local.init_server.ip} \
        'sudo cat /etc/rancher/k3s/k3s.yaml' | \
        sed 's/127.0.0.1/${local.init_server.ip}/' > kubeconfig.yaml
      chmod 600 kubeconfig.yaml
    EOT
  }
}

# Store kubeconfig content
data "local_file" "kubeconfig" {
  depends_on = [null_resource.kubeconfig]
  filename   = "${path.module}/kubeconfig.yaml"
}

# -----------------------------------------------------------------------------
# OUTPUTS
# -----------------------------------------------------------------------------

output "cluster_name" {
  description = "k3s cluster name"
  value       = var.cluster_name
}

output "cluster_endpoint" {
  description = "k3s API endpoint"
  value       = "https://${local.init_server.ip}:6443"
}

output "cluster_token" {
  description = "k3s cluster token"
  value       = local.cluster_token
  sensitive   = true
}

output "kubeconfig_path" {
  description = "Path to generated kubeconfig"
  value       = "${path.module}/kubeconfig.yaml"
}

output "kubeconfig_content" {
  description = "Kubeconfig file content"
  value       = data.local_file.kubeconfig.content
  sensitive   = true
}

output "server_nodes" {
  description = "Server node details"
  value = [for n in local.server_nodes : {
    name = n.name
    ip   = n.ip
    role = n.role
  }]
}

output "agent_nodes" {
  description = "Agent node details"
  value = [for n in local.agent_nodes : {
    name = n.name
    ip   = n.ip
    role = n.role
  }]
}

output "status" {
  description = "Deployment status"
  value       = "deployed"
}
