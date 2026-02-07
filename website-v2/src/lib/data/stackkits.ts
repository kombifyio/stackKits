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
		name: 'Base',
		tagline: 'Single-environment pattern',
		description:
			'All services in one deployment target. Docker Compose, context-aware defaults, composable Add-Ons. Works on any hardware — from Pi to powerful server.',
		icon: 'server',
		status: 'available',
		pattern: 'Single-Environment',
		cloud: false,
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
		name: 'Modern',
		tagline: 'Hybrid infrastructure pattern',
		description:
			'Bridge local and cloud environments with VPN overlay networking. Distributed services across heterogeneous nodes with Coolify management.',
		icon: 'cloud',
		status: 'planned',
		pattern: 'Hybrid',
		cloud: true,
		features: [
			'VPN overlay (Headscale/Tailscale)',
			'Local + cloud node bridging',
			'Coolify deployment platform',
			'Split DNS (public/private)',
			'Multi-environment coordination'
		],
		services: ['Headscale/Tailscale', 'Coolify', 'Prometheus', 'Grafana']
	},
	{
		id: 'ha',
		name: 'HA',
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
