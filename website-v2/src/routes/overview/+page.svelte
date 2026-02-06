<script lang="ts">
	import { ArrowRight, ArrowDown } from 'lucide-svelte';
	import ScrollReveal from '$lib/components/ScrollReveal.svelte';
	import StackKitCard from '$lib/components/StackKitCard.svelte';
	import { stackkits } from '$lib/data/stackkits';

	const compFeatures = [
		{ name: 'Docker Support', checks: [true, true, true] },
		{ name: 'Reverse Proxy', checks: [true, true, true] },
		{ name: 'TLS Certificates', checks: [true, true, true] },
		{ name: 'Monitoring', checks: [true, true, true] },
		{ name: 'Multi-Node', checks: [false, true, true] },
		{ name: 'Cloud Hybrid', checks: [false, true, true] },
		{ name: 'VPN Overlay', checks: [false, true, true] },
		{ name: 'Kubernetes', checks: [false, false, true] },
		{ name: 'Auto-Failover', checks: [false, false, true] },
		{ name: 'GitOps', checks: [false, false, true] }
	];
</script>

<svelte:head>
	<title>StackKits Overview - kombify</title>
	<meta name="description" content="Explore the three StackKits: Base Homelab, Modern Homelab, and HA Homelab. Find the right blueprint for your infrastructure." />
</svelte:head>

<!-- Header -->
<section class="py-16 border-b border-border">
	<div class="max-w-6xl mx-auto px-6">
		<ScrollReveal>
			<div class="text-center">
				<h1 class="text-4xl font-bold">Choose Your Stack</h1>
				<p class="mt-4 text-lg text-muted-foreground max-w-2xl mx-auto">
					Three curated blueprints built to professional standards. Every tool hand-picked, every config validated. Start simple, scale when ready.
				</p>
			</div>
		</ScrollReveal>
	</div>
</section>

<!-- StackKits with Upgrade Path -->
<section class="py-16">
	<div class="max-w-6xl mx-auto px-6">
		<div class="grid md:grid-cols-3 gap-8">
			{#each stackkits as kit, i}
				<ScrollReveal delay={i * 0.1}>
					<StackKitCard {kit} />
				</ScrollReveal>
			{/each}
		</div>

		<!-- Upgrade Path -->
		<ScrollReveal delay={0.3}>
			<div class="mt-12 flex items-center justify-center gap-4">
				<div class="text-center">
					<div class="badge badge-success">Base</div>
				</div>
				<ArrowRight class="w-5 h-5 text-muted-foreground" />
				<div class="text-center">
					<div class="badge badge-secondary">Modern</div>
				</div>
				<ArrowRight class="w-5 h-5 text-muted-foreground" />
				<div class="text-center">
					<div class="badge badge-secondary">HA</div>
				</div>
			</div>
			<p class="text-center text-sm text-muted-foreground mt-4">
				Upgrade path: Start with Base, grow into Modern or HA when your needs expand.
			</p>
		</ScrollReveal>
	</div>
</section>

<!-- Comparison Matrix -->
<section class="py-16 bg-card/30">
	<div class="max-w-4xl mx-auto px-6">
		<ScrollReveal>
			<h2 class="text-3xl font-bold text-center mb-12">Feature Comparison</h2>
		</ScrollReveal>

		<ScrollReveal delay={0.1}>
			<div class="card p-6 overflow-x-auto">
				<table class="w-full text-sm">
					<thead>
						<tr class="border-b border-border">
							<th class="text-left py-3 px-4 text-muted-foreground font-medium">Feature</th>
							{#each stackkits as kit}
								<th class="text-center py-3 px-4 font-semibold text-foreground">{kit.name}</th>
							{/each}
						</tr>
					</thead>
					<tbody>
						{#each compFeatures as feature}
							<tr class="border-b border-border/50">
								<td class="py-3 px-4 text-muted-foreground">{feature.name}</td>
								{#each feature.checks as check}
									<td class="text-center py-3 px-4">
										{#if check}
											<span class="text-primary">&#10003;</span>
										{:else}
											<span class="text-muted-foreground/30">&mdash;</span>
										{/if}
									</td>
								{/each}
							</tr>
						{/each}
					</tbody>
				</table>
			</div>
		</ScrollReveal>
	</div>
</section>

<!-- CTA -->
<section class="py-16">
	<div class="max-w-4xl mx-auto px-6 text-center">
		<ScrollReveal>
			<h2 class="text-3xl font-bold mb-4">Start with Base Homelab</h2>
			<p class="text-muted-foreground mb-8">
				The best way to start is with the Base Homelab StackKit. It's available now and gives you everything you need.
			</p>
			<a href="/get-started" class="btn btn-primary btn-lg">
				Get Started
				<ArrowRight class="w-4 h-4" />
			</a>
		</ScrollReveal>
	</div>
</section>
