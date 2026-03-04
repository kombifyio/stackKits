export interface StackKit {
	id: string;
	name: string;
	tagline: string;
	description: string;
	icon: string;
	status: 'available' | 'planned';
	pattern: string;
	cloud: boolean;
	features: string[];
	services: string[];
}

export const stackkits: StackKit[] = [
	{
		id: 'base',
		name: 'Base Kit',
		tagline: 'Single-environment pattern',
		description:
			'All services in one deployment target — local server or cloud VPS. Docker Compose, context-aware defaults, composable Add-Ons. Works on any hardware.',
		icon: 'server',
		status: 'available',
		pattern: 'Single Environment',
		cloud: true,
		features: [
			'Docker Compose deployments',
			'Context-aware defaults (local/cloud/pi)',
			'Traefik reverse proxy',
			'Composable Add-Ons',
			'Dokploy or Coolify PaaS'
		],
		services: ['Traefik', 'Dokploy', 'TinyAuth', 'Dozzle']
	},
	{
		id: 'modern',
		name: 'Modern Homelab',
		tagline: 'Hybrid infrastructure pattern',
		description:
			'Bridge local and cloud environments with zero-trust identity access. Distributed services across heterogeneous nodes with Coolify management.',
		icon: 'cloud',
		status: 'planned',
		pattern: 'Hybrid',
		cloud: true,
		features: [
			'Zero-trust identity (LLDAP+Step-CA+PocketID)',
			'Local + cloud node bridging',
			'Coolify deployment platform',
			'Split DNS (public/private)',
			'Multi-environment coordination'
		],
		services: ['LLDAP', 'Step-CA', 'PocketID', 'Coolify', 'Prometheus']
	},
	{
		id: 'ha',
		name: 'High Availability Kit',
		tagline: 'High-availability cluster pattern',
		description:
			'No single point of failure. Docker Swarm cluster with automatic failover, quorum consensus, and data replication.',
		icon: 'shield',
		status: 'planned',
		pattern: 'HA Cluster',
		cloud: true,
		features: [
			'Docker Swarm orchestration',
			'Automatic failover',
			'Keepalived VIP load balancing',
			'Quorum-based consensus',
			'Enterprise observability'
		],
		services: ['Docker Swarm', 'Keepalived', 'Traefik', 'Prometheus', 'Grafana']
	}
];
