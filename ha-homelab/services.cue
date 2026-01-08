// Package ha_homelab - Service Definitions (Scaffolding)
// 
// Status: SCAFFOLDING - Services are planned but not yet implemented
//
// Extends: modern_homelab
// Focus: High Availability, Automatic Failover, Distributed Storage

package ha_homelab

import "github.com/kombihq/stackkits/base"
import "github.com/kombihq/stackkits/modern-homelab"

// =============================================================================
// HA KUBERNETES
// =============================================================================

// #K3sHAService - High Availability k3s Cluster (Planned)
#K3sHAService: base.#ServiceDefinition & {
	name:        "k3s-ha"
	displayName: "k3s HA"
	category:    "kubernetes"
	type:        "cluster"
	required:    true
	status:      "planned"
	description: "High Availability k3s with embedded etcd"

	config: {
		masterCount:    3 | 5 | *3
		etcdMode:       "embedded"
		datastore:      "etcd"
		clusterCIDR:    string | *"10.42.0.0/16"
		serviceCIDR:    string | *"10.43.0.0/16"
		disableTraefik: true // We use custom ingress
	}

	// TODO: Implement HA control plane
	// - Multi-master setup
	// - etcd cluster formation
	// - Leader election
	// - API server load balancing
}

// =============================================================================
// LOAD BALANCING
// =============================================================================

// #MetalLBService - Bare-metal Load Balancer (Planned)
#MetalLBService: base.#ServiceDefinition & {
	name:        "metallb"
	displayName: "MetalLB"
	category:    "networking"
	type:        "load-balancer"
	required:    true
	status:      "planned"
	description: "Load balancer for bare-metal Kubernetes"
	needs:       ["k3s-ha"]

	config: {
		mode:        "layer2" | "bgp" | *"layer2"
		addressPool: string
	}

	// TODO: Implement MetalLB
	// - L2 mode for simple setups
	// - BGP mode for advanced networking
	// - IP address pool management
}

// #HAProxyService - External Load Balancer (Planned)
#HAProxyService: base.#ServiceDefinition & {
	name:        "haproxy"
	displayName: "HAProxy"
	category:    "networking"
	type:        "load-balancer"
	required:    false
	status:      "planned"
	description: "External load balancer for API server access"
	needs:       ["k3s-ha"]

	// TODO: Implement HAProxy
	// - Health checks for master nodes
	// - Automatic failover
	// - TLS termination
}

// =============================================================================
// HA MONITORING
// =============================================================================

// #PrometheusHAService - HA Prometheus (Planned)
#PrometheusHAService: base.#ServiceDefinition & {
	name:        "prometheus-ha"
	displayName: "Prometheus HA"
	category:    "monitoring"
	type:        "metrics"
	required:    true
	status:      "planned"
	description: "High Availability Prometheus setup"
	needs:       ["k3s-ha"]

	config: {
		replicas:  2
		retention: "15d"
	}

	// TODO: Implement Prometheus HA
	// - Multiple replicas
	// - Thanos sidecar integration
	// - Alert deduplication
}

// #ThanosService - Long-term Metrics (Planned)
#ThanosService: base.#ServiceDefinition & {
	name:        "thanos"
	displayName: "Thanos"
	category:    "monitoring"
	type:        "metrics-aggregation"
	required:    false
	status:      "planned"
	description: "Global view and long-term storage for Prometheus"
	needs:       ["k3s-ha", "prometheus-ha"]

	config: {
		objectStorage: "s3" | "gcs" | "azure" | "minio" | *"minio"
		retention:     "90d"
	}

	// TODO: Implement Thanos
	// - Query frontend
	// - Store gateway
	// - Compactor
	// - Ruler
}

// =============================================================================
// DISTRIBUTED STORAGE
// =============================================================================

// #LonghornHAService - HA Block Storage (Planned)
#LonghornHAService: base.#ServiceDefinition & {
	name:        "longhorn-ha"
	displayName: "Longhorn HA"
	category:    "storage"
	type:        "block-storage"
	required:    true
	status:      "planned"
	description: "Distributed block storage with HA"
	needs:       ["k3s-ha"]

	config: {
		replicaCount:       3
		dataLocality:       "best-effort" | "strict-local" | *"best-effort"
		backupTarget:       string
		backupTargetSecret: string
	}

	// TODO: Implement Longhorn HA
	// - 3x replication by default
	// - Automatic rebuild on node failure
	// - S3/NFS backup integration
}

// #CephService - Enterprise Storage (Planned)
#CephService: base.#ServiceDefinition & {
	name:        "ceph"
	displayName: "Ceph (Rook)"
	category:    "storage"
	type:        "distributed-storage"
	required:    false
	status:      "planned"
	description: "Enterprise distributed storage via Rook operator"
	needs:       ["k3s-ha"]

	config: {
		osdCount:           3
		monCount:           3
		enableCephFS:       true
		enableRGW:          false // S3-compatible gateway
		replicationFactor:  3
	}

	// TODO: Implement Ceph via Rook
	// - Block storage (RBD)
	// - File storage (CephFS)
	// - Object storage (RGW) optional
}

// =============================================================================
// BACKUP & DISASTER RECOVERY
// =============================================================================

// #VeleroService - Backup & DR (Planned)
#VeleroService: base.#ServiceDefinition & {
	name:        "velero"
	displayName: "Velero"
	category:    "backup"
	type:        "disaster-recovery"
	required:    true
	status:      "planned"
	description: "Kubernetes backup and disaster recovery"
	needs:       ["k3s-ha"]

	config: {
		provider:        "aws" | "gcp" | "azure" | "minio" | *"minio"
		backupSchedule:  string | *"0 1 * * *"  // Daily at 1 AM
		retentionPeriod: string | *"720h"       // 30 days
		includeClusterResources: true
	}

	// TODO: Implement Velero
	// - Scheduled backups
	// - On-demand backups
	// - Disaster recovery to new cluster
	// - Namespace migration
}

// =============================================================================
// SERVICE COLLECTIONS (Planned)
// =============================================================================

// #DefaultHAServices - Standard HA deployment
#DefaultHAServices: [
	#K3sHAService,
	#MetalLBService,
	modern_homelab.#FluxService,
	modern_homelab.#TraefikIngressService,
	#PrometheusHAService,
	#ThanosService,
	modern_homelab.#GrafanaService,
	modern_homelab.#LokiService,
	#LonghornHAService,
	#VeleroService,
]

// #EnterpriseServices - Full enterprise stack
#EnterpriseServices: [
	#K3sHAService,
	#MetalLBService,
	#HAProxyService,
	modern_homelab.#ArgoCDService,
	modern_homelab.#TraefikIngressService,
	#PrometheusHAService,
	#ThanosService,
	modern_homelab.#GrafanaService,
	modern_homelab.#LokiService,
	#CephService,
	#VeleroService,
]
