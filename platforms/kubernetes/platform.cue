// =============================================================================
// PLATFORM: KUBERNETES - CUE SCHEMA DEFINITION
// =============================================================================
// Layer 2 (PLATFORM): CUE schema for Kubernetes (k3s) platform configuration
//
// This schema defines:
// - K3s cluster configuration options
// - Ingress controller options
// - Storage class configuration
// - Platform-specific constraints
// =============================================================================

package kubernetes

import (
	"github.com/kombihq/stackkits/base"
)

// #KubernetesPlatform extends base configuration for Kubernetes deployments
#KubernetesPlatform: base.#BaseStackKit & {
	// Platform identifier
	platform: "kubernetes"
	
	// K3s-specific configuration
	k3s: #K3sConfig
	
	// Ingress controller configuration
	ingress: #IngressConfig
	
	// Storage configuration
	storage: #StorageConfig
	
	// Namespaces to create
	namespaces: [...#KubernetesNamespace]
}

// #K3sConfig defines k3s cluster settings
#K3sConfig: {
	// K3s version
	version: string | *"v1.30.2+k3s1"
	
	// Cluster mode
	mode: "single-node" | "multi-node" | *"single-node"
	
	// Node configuration
	nodes: [...#K3sNode]
	
	// Network configuration
	network: {
		// Flannel backend
		backend: "vxlan" | "host-gw" | "wireguard-native" | "none" | *"vxlan"
		// Pod CIDR
		cluster_cidr: string | *"10.42.0.0/16"
		// Service CIDR
		service_cidr: string | *"10.43.0.0/16"
		// Cluster DNS IP
		cluster_dns: string | *"10.43.0.10"
	}
	
	// Components to disable
	disable: [...#K3sComponent]
	
	// TLS configuration
	tls: {
		// Additional SANs for the API server
		san: [...string]
	}
	
	// Data directory
	data_dir: string | *"/var/lib/rancher/k3s"
	
	// Write kubeconfig mode
	write_kubeconfig_mode: string | *"0644"
}

// #K3sNode defines a node in the k3s cluster
#K3sNode: {
	// Node name
	name: string
	
	// Node IP address
	ip: string
	
	// Node role
	role: "server" | "agent"
	
	// Node labels
	labels: [string]: string
	
	// Node taints
	taints: [...{
		key: string
		value: string
		effect: "NoSchedule" | "PreferNoSchedule" | "NoExecute"
	}]
}

// #K3sComponent defines k3s components that can be disabled
#K3sComponent: "traefik" | "servicelb" | "local-storage" | "metrics-server" | "coredns"

// #IngressConfig defines ingress controller settings
#IngressConfig: {
	// Ingress controller type
	type: "traefik" | "nginx" | "none" | *"traefik"
	
	// Traefik-specific settings (k3s built-in)
	traefik?: {
		// Dashboard enabled
		dashboard: bool | *true
		// Dashboard insecure mode
		dashboard_insecure: bool | *false
		// Log level
		log_level: "DEBUG" | "INFO" | "WARN" | "ERROR" | *"INFO"
	}
	
	// NGINX-specific settings
	nginx?: {
		// Replica count
		replicas: int | *1
		// Default TLS secret
		default_tls_secret?: string
	}
	
	// TLS configuration
	tls: {
		// auto = use cert-manager, self-signed for local
		mode: "auto" | "cert-manager" | "self-signed" | "custom" | *"auto"
		
		// cert-manager configuration
		cert_manager?: {
			email: string
			// Issuer type
			issuer: "letsencrypt-staging" | "letsencrypt-prod" | "self-signed" | *"letsencrypt-prod"
		}
	}
}

// #StorageConfig defines storage configuration
#StorageConfig: {
	// Default storage class
	default_class: "local-path" | "longhorn" | "nfs" | *"local-path"
	
	// local-path provisioner settings (k3s built-in)
	local_path?: {
		// Path on node for storage
		path: string | *"/opt/local-path-provisioner"
		// Reclaim policy
		reclaim_policy: "Delete" | "Retain" | *"Delete"
	}
	
	// Longhorn settings
	longhorn?: {
		// Enable Longhorn
		enabled: bool | *false
		// UI enabled
		ui: bool | *true
		// Default replica count
		replicas: int | *3
	}
	
	// NFS settings
	nfs?: {
		// NFS server address
		server: string
		// NFS path
		path: string
	}
}

// #KubernetesNamespace defines a namespace
#KubernetesNamespace: {
	// Namespace name
	name: string
	
	// Labels
	labels: [string]: string
	
	// Annotations
	annotations: [string]: string
	
	// Resource quotas
	resource_quota?: {
		hard: {
			"requests.cpu"?: string
			"requests.memory"?: string
			"limits.cpu"?: string
			"limits.memory"?: string
			"pods"?: string
		}
	}
}

// #KubernetesService defines a service deployed via Kubernetes
#KubernetesService: {
	// Service name
	name: string
	
	// Namespace
	namespace: string | *"kombistack"
	
	// Deployment specification
	deployment: {
		// Container image
		image: string
		// Image tag
		tag: string | *"latest"
		// Replica count
		replicas: int | *1
		
		// Container ports
		ports: [...{
			name: string
			port: int
			protocol: "TCP" | "UDP" | *"TCP"
		}]
		
		// Environment variables
		env: [string]: string
		
		// Environment from secrets/configmaps
		env_from: [...{
			type: "secret" | "configmap"
			name: string
		}]
		
		// Volume mounts
		volume_mounts: [...{
			name: string
			mount_path: string
			read_only: bool | *false
		}]
		
		// Resource limits
		resources?: {
			requests?: {
				cpu: string
				memory: string
			}
			limits?: {
				cpu: string
				memory: string
			}
		}
		
		// Liveness probe
		liveness_probe?: #Probe
		
		// Readiness probe
		readiness_probe?: #Probe
	}
	
	// Service type
	service_type: "ClusterIP" | "NodePort" | "LoadBalancer" | *"ClusterIP"
	
	// Ingress configuration
	ingress?: {
		enabled: bool | *true
		host: string
		path: string | *"/"
		tls: bool | *true
	}
	
	// Volumes
	volumes: [...{
		name: string
		type: "pvc" | "configmap" | "secret" | "emptydir"
		// For PVC
		pvc?: {
			size: string
			storage_class?: string
		}
		// For configmap/secret
		source?: string
	}]
}

// #Probe defines a Kubernetes probe
#Probe: {
	http_get?: {
		path: string
		port: int
	}
	tcp_socket?: {
		port: int
	}
	exec?: {
		command: [...string]
	}
	initial_delay_seconds: int | *10
	period_seconds: int | *30
	timeout_seconds: int | *5
	failure_threshold: int | *3
}

// Default namespaces for Kubernetes platform
#DefaultKubernetesNamespaces: [
	{
		name: "kombistack"
		labels: {
			"app.kubernetes.io/managed-by": "kombistack"
		}
		annotations: {}
	}
]
