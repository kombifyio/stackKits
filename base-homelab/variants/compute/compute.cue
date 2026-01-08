// Package base_homelab - Compute tier variants
package base_homelab

// #HighComputeVariant for high-performance servers (8+ CPU, 16+ GB RAM)
#HighComputeVariant: #ComputeVariant & {
	tier: "high"

	requirements: {
		minCpu:    8
		minMemory: 16
		minDisk:   100
	}

	// Additional services for high-compute
	additionalServices: [
		"portainer",
		"prometheus",
		"grafana",
	]

	// Service overrides
	serviceConfig: {
		netdata: {
			enabled:    true
			claimCloud: true
		}
		prometheus: {
			enabled:         true
			retentionPeriod: "30d"
			scrapeInterval:  "15s"
		}
		grafana: {
			enabled:        true
			anonymousAuth:  false
			adminPassword:  "secret://grafana-admin-password"
		}
	}

	// Docker resource defaults
	docker: {
		defaultMemoryLimit:       "4g"
		defaultMemoryReservation: "1g"
		defaultCpuLimit:          4.0
		maxContainers:            50
		logMaxSize:               "100m"
		logMaxFile:               10
	}

	// Enhanced monitoring
	monitoring: {
		metricsRetention:  "30d"
		logsRetention:     "14d"
		enableTracing:     true
		enableProfiling:   true
	}

	// More frequent backups
	backup: {
		schedule:   "0 */6 * * *"
		retention: {
			daily:   14
			weekly:  8
			monthly: 12
			yearly:  2
		}
	}
}

// #StandardComputeVariant for typical servers (4-7 CPU, 8-15 GB RAM)
#StandardComputeVariant: #ComputeVariant & {
	tier: "standard"

	requirements: {
		minCpu:    4
		minMemory: 8
		minDisk:   50
	}

	// No additional services (use defaults)
	additionalServices: []

	// Service overrides
	serviceConfig: {
		netdata: {
			enabled:    true
			claimCloud: false
		}
	}

	// Docker resource defaults
	docker: {
		defaultMemoryLimit:       "1g"
		defaultMemoryReservation: "256m"
		defaultCpuLimit:          1.0
		maxContainers:            20
		logMaxSize:               "50m"
		logMaxFile:               5
	}

	// Standard monitoring
	monitoring: {
		metricsRetention: "7d"
		logsRetention:    "7d"
		enableTracing:    false
		enableProfiling:  false
	}

	// Daily backups
	backup: {
		schedule:   "0 3 * * *"
		retention: {
			daily:   7
			weekly:  4
			monthly: 6
			yearly:  1
		}
	}
}

// #LowComputeVariant for resource-constrained devices (Raspberry Pi, NUC, etc.)
#LowComputeVariant: #ComputeVariant & {
	tier: "low"

	requirements: {
		minCpu:    2
		minMemory: 4
		minDisk:   32
	}

	// Use lightweight alternatives
	additionalServices: []

	// Service overrides - disable heavy services
	serviceConfig: {
		netdata: {
			enabled: false  // Use glances instead
		}
		glances: {
			enabled: true
		}
		portainer: {
			enabled: false  // Too resource-intensive
		}
	}

	// Minimal Docker resources
	docker: {
		defaultMemoryLimit:       "512m"
		defaultMemoryReservation: "128m"
		defaultCpuLimit:          0.5
		maxContainers:            10
		logMaxSize:               "20m"
		logMaxFile:               3
	}

	// Minimal monitoring
	monitoring: {
		metricsRetention: "3d"
		logsRetention:    "3d"
		enableTracing:    false
		enableProfiling:  false
	}

	// Weekly backups
	backup: {
		schedule:   "0 4 * * 0"
		retention: {
			daily:   3
			weekly:  2
			monthly: 1
			yearly:  0
		}
	}

	// Disable memory-intensive features
	optimizations: {
		disableSwap:           false  // Keep swap for low-memory
		reduceBufferSizes:     true
		disableJournalPersist: true
		limitSystemdServices:  true
	}
}

// #ComputeVariant base definition
#ComputeVariant: {
	tier: "high" | "standard" | "low"

	requirements: {
		minCpu:    int
		minMemory: int
		minDisk:   int
	}

	additionalServices: [...string]

	serviceConfig: [string]: {...}

	docker: {
		defaultMemoryLimit:       string
		defaultMemoryReservation: string
		defaultCpuLimit:          number
		maxContainers:            int
		logMaxSize:               string
		logMaxFile:               int
	}

	monitoring: {
		metricsRetention: string
		logsRetention:    string
		enableTracing:    bool
		enableProfiling:  bool
	}

	backup: {
		schedule:  string
		retention: {
			daily:   int
			weekly:  int
			monthly: int
			yearly:  int
		}
	}

	optimizations?: {
		disableSwap:           bool
		reduceBufferSizes:     bool
		disableJournalPersist: bool
		limitSystemdServices:  bool
	}
}
