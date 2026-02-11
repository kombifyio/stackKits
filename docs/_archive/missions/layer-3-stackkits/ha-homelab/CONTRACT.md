# HA Homelab Contract

High availability homelab with multi-node clustering and failover.

## Layers
Foundation is extended.
Platform is docker-swarm.

## Network
Traefik runs in HA mode across manager nodes.
Overlay networks for cross-node communication.
Keepalived or DNS for VIP failover.

## Platform Services
Coolify manages deployments across the cluster.
GlusterFS or Longhorn for distributed storage.

## Monitoring
Uptime Kuma monitors all nodes and services.
Prometheus collects cluster-wide metrics.
Grafana visualizes cluster health.
Alertmanager sends notifications on failures.

## Clustering
Minimum 3 nodes for quorum.
Manager nodes run control plane services.
Worker nodes run application workloads.
Automatic failover when node goes down.

## Backup
Velero or Restic for scheduled backups.
Cross-node replication for critical data.

## Variant Selection
Standard HA uses 3 nodes.
Extended HA uses 5+ nodes with dedicated managers.

## Success
Cluster forms and all nodes are healthy.
Services failover when a node is stopped.
Data persists across node failures.
Recovery completes within 5 minutes.
Destroy removes all containers, volumes, and networks.
