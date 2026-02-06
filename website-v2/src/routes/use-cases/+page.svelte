<script lang="ts">
	import { ArrowRight, Server, Shield, Eye, Cpu, Cloud, Database, Lock, BookOpen, Users, Gauge, Globe } from 'lucide-svelte';
	import ScrollReveal from '$lib/components/ScrollReveal.svelte';

	const useCases = [
		{
			icon: Server,
			title: 'Personal Homelab',
			audience: 'Enthusiasts & Tinkerers',
			description: 'Run a complete homelab with reverse proxy, monitoring, backup, and TLS — all validated and reproducible. No more fragile docker-compose files scattered across your server.',
			features: ['Automated TLS certificates', 'Centralized monitoring', 'Scheduled backups', 'Reverse proxy with auto-discovery'],
			stackkit: 'base-homelab'
		},
		{
			icon: Lock,
			title: 'Privacy-First Self-Hosting',
			audience: 'Privacy-Conscious Users',
			description: 'Host your own cloud storage, email, password manager, and communication tools. Own your data instead of renting it from Big Tech.',
			features: ['Nextcloud / Immich for photos', 'Vaultwarden password manager', 'Private VPN access', 'Encrypted backups'],
			stackkit: 'base-homelab'
		},
		{
			icon: Cpu,
			title: 'Local AI & ML Workloads',
			audience: 'AI Enthusiasts & Developers',
			description: 'Run local LLMs, image generation, and AI workflows on your own hardware. Full GPU passthrough support with validated configurations.',
			features: ['Ollama / LocalAI integration', 'GPU passthrough configs', 'Model management', 'Private AI — your data stays local'],
			stackkit: 'modern-homelab'
		},
		{
			icon: Cloud,
			title: 'Hybrid Cloud Infrastructure',
			audience: 'Small Teams & Startups',
			description: 'Combine local servers with cloud resources. Secure overlay networking connects your on-prem and cloud nodes into a unified environment.',
			features: ['WireGuard overlay networking', 'Multi-node orchestration', 'Cloud provider integration', 'Consistent configuration across nodes'],
			stackkit: 'modern-homelab'
		},
		{
			icon: Database,
			title: 'Media & Storage Server',
			audience: 'Digital Media Collectors',
			description: 'Professional media server setup with automated organization, transcoding, and multi-device streaming. Proper storage management included.',
			features: ['Plex / Jellyfin setup', 'Automated media management', 'Storage tiering & monitoring', 'Remote access via VPN'],
			stackkit: 'base-homelab'
		},
		{
			icon: Users,
			title: 'Development Environment',
			audience: 'Developers & DevOps Engineers',
			description: 'Reproducible development infrastructure with CI/CD, container registry, Git hosting, and observability. Professional-grade but self-hosted.',
			features: ['Gitea / Forgejo hosting', 'Container registry', 'CI/CD pipelines', 'Observability stack'],
			stackkit: 'modern-homelab'
		}
	];

	const whyProfessional = [
		{
			icon: Shield,
			title: 'Curated Tool Selection',
			description: 'Every tool in a StackKit is hand-picked and tested for compatibility, security, and long-term maintainability. No random community picks.'
		},
		{
			icon: Gauge,
			title: 'Enterprise-Grade Standards',
			description: 'CUE schema validation, Infrastructure as Code, drift detection, and automated testing. The same practices used by Fortune 500 companies.'
		},
		{
			icon: Eye,
			title: 'Transparent & Auditable',
			description: 'Every configuration is declarative, versioned, and fully readable. No black-box magic — you always know what your infrastructure does.'
		},
		{
			icon: BookOpen,
			title: 'Opinionated Defaults, Full Flexibility',
			description: 'Secure defaults get you started fast. Expert mode gives you full control when you need it. Professional standards without the rigidity.'
		}
	];
</script>

<svelte:head>
	<title>Use Cases - kombify StackKits</title>
	<meta name="description" content="Discover homelab use cases: personal servers, privacy-first self-hosting, local AI, hybrid cloud, media servers, and development environments." />
</svelte:head>

<!-- Header -->
<section class="py-16 border-b border-border">
	<div class="max-w-6xl mx-auto px-6">
		<ScrollReveal>
			<div class="text-center">
				<h1 class="text-4xl font-bold">What Will You Build?</h1>
				<p class="mt-4 text-lg text-muted-foreground max-w-2xl mx-auto">
					StackKits are designed for real-world scenarios. From personal homelabs to hybrid cloud setups — curated blueprints for every ambition.
				</p>
			</div>
		</ScrollReveal>
	</div>
</section>

<!-- Use Cases Grid -->
<section class="py-20">
	<div class="max-w-6xl mx-auto px-6">
		<div class="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
			{#each useCases as useCase, i}
				{@const Icon = useCase.icon}
				<ScrollReveal delay={i * 0.08}>
					<div class="card card-hover p-8 h-full flex flex-col">
						<div class="flex items-start gap-4 mb-4">
							<div class="w-12 h-12 bg-primary/10 rounded-xl flex items-center justify-center text-primary flex-shrink-0">
								<Icon class="w-6 h-6" />
							</div>
							<div>
								<h3 class="text-xl font-semibold">{useCase.title}</h3>
								<p class="text-sm text-primary">{useCase.audience}</p>
							</div>
						</div>
						<p class="text-muted-foreground text-sm leading-relaxed mb-6">{useCase.description}</p>
						<ul class="space-y-2 mb-6 flex-1">
							{#each useCase.features as feature}
								<li class="flex items-center gap-2 text-sm">
									<span class="text-primary">&#10003;</span>
									<span class="text-muted-foreground">{feature}</span>
								</li>
							{/each}
						</ul>
						<div class="pt-4 border-t border-border">
							<span class="badge badge-primary text-xs">{useCase.stackkit}</span>
						</div>
					</div>
				</ScrollReveal>
			{/each}
		</div>
	</div>
</section>

<!-- Curated & Professional Standards -->
<section class="py-20 bg-card/30">
	<div class="max-w-6xl mx-auto px-6">
		<ScrollReveal>
			<div class="text-center mb-16">
				<h2 class="text-3xl font-bold mb-4">Curated & Professional Standards</h2>
				<p class="text-lg text-muted-foreground max-w-2xl mx-auto">
					StackKits aren't random templates. Every blueprint is curated by infrastructure experts,
					validated through CUE schemas, and built to professional standards used in production environments.
				</p>
			</div>
		</ScrollReveal>

		<div class="grid md:grid-cols-2 gap-8">
			{#each whyProfessional as item, i}
				{@const Icon = item.icon}
				<ScrollReveal delay={i * 0.1}>
					<div class="card p-8 flex gap-5">
						<div class="w-12 h-12 bg-primary/10 rounded-xl flex items-center justify-center text-primary flex-shrink-0">
							<Icon class="w-6 h-6" />
						</div>
						<div>
							<h3 class="text-lg font-semibold mb-2">{item.title}</h3>
							<p class="text-muted-foreground text-sm leading-relaxed">{item.description}</p>
						</div>
					</div>
				</ScrollReveal>
			{/each}
		</div>
	</div>
</section>

<!-- The kombify Advantage -->
<section class="py-20">
	<div class="max-w-4xl mx-auto px-6">
		<ScrollReveal>
			<div class="card p-10 text-center border-primary/20">
				<Globe class="w-12 h-12 text-primary mx-auto mb-6" />
				<h2 class="text-2xl font-bold mb-4">Part of the kombify Ecosystem</h2>
				<p class="text-muted-foreground max-w-xl mx-auto mb-6 leading-relaxed">
					StackKits are the foundation layer of the kombify platform. As your needs grow,
					combine them with kombify Stack for orchestration, kombify Sim for simulation,
					and kombify Cloud for the full managed experience.
				</p>
				<div class="flex flex-wrap justify-center gap-3">
					<span class="badge badge-primary">StackKits</span>
					<span class="badge badge-secondary">kombify Cloud</span>
					<span class="badge badge-secondary">kombify Stack</span>
					<span class="badge badge-secondary">kombify Sim</span>
				</div>
			</div>
		</ScrollReveal>
	</div>
</section>

<!-- CTA -->
<section class="py-16 bg-card/50 border-t border-border">
	<div class="max-w-4xl mx-auto px-6 text-center">
		<ScrollReveal>
			<h2 class="text-3xl font-bold mb-4">Ready to get started?</h2>
			<p class="text-muted-foreground mb-8">
				Pick a use case, choose a StackKit, and deploy in minutes.
			</p>
			<div class="flex flex-wrap gap-4 justify-center">
				<a href="/get-started" class="btn btn-primary btn-lg">
					Get Started
					<ArrowRight class="w-4 h-4" />
				</a>
				<a href="/overview" class="btn btn-outline btn-lg">
					Compare StackKits
				</a>
			</div>
		</ScrollReveal>
	</div>
</section>
