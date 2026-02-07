export interface StackKit {
	id: string;
	name: string;
	tagline: string;
	description: string;
	icon: string;
	status: 'available' | 'planned';
	nodes: string;
	cloud: boolean;
	features: string[];
	services: string[];
}

export const stackkits: StackKit[] = [
	{
		id: 'base-homelab',
		name: 'Base Homelab',
		tagline: 'Single-server, local-only',
		description:
			'Single-server setup with Docker, reverse proxy, and monitoring. Everything you need for a professional homelab.',
		icon: 'server',
		status: 'available',
		nodes: '1 Node',
		cloud: false,
		features: [
			'Docker-based deployments',
			'Traefik reverse proxy',
			'Automatic TLS certificates',
			'Uptime monitoring with Uptime Kuma',
			'Dokploy PaaS interface'
		],
		services: ['Traefik', 'Dokploy', 'Uptime Kuma', 'Dozzle']
	},
	{
		id: 'modern-homelab',
		name: 'Modern Homelab',
		tagline: 'Local + Cloud hybrid',
		description:
			'Multi-server hybrid setup that connects local and cloud infrastructure. Scale beyond your home network.',
		icon: 'cloud',
		status: 'planned',
		nodes: '2+ Nodes',
		cloud: true,
		features: [
			'VPN overlay network',
			'Hybrid local/cloud nodes',
			'Coolify deployment platform',
			'Distributed storage',
			'Public access support'
		],
		services: ['Headscale/Tailscale', 'Coolify', 'Prometheus', 'Grafana']
	},
	{
		id: 'ha-homelab',
		name: 'HA Homelab',
		tagline: 'Enterprise-grade reliability',
		description:
			'High-availability Docker Swarm cluster with automatic failover. Production-ready infrastructure at home.',
		icon: 'shield',
		status: 'planned',
		nodes: '3+ Nodes',
		cloud: true,
		features: [
			'Docker Swarm cluster',
			'Automatic failover',
			'Keepalived for high availability',
			'Distributed monitoring',
			'Enterprise observability'
		],
		services: ['Docker Swarm', 'Keepalived', 'Traefik', 'Prometheus', 'Grafana']
	}
];
