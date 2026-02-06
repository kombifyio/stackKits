<script lang="ts">
	import { Server, Cloud, Shield, Check, ChevronDown, ChevronUp } from 'lucide-svelte';
	import type { StackKit } from '$lib/data/stackkits';

	interface Props {
		kit: StackKit;
		delay?: number;
	}

	let { kit, delay = 0 }: Props = $props();
	let expanded = $state(false);

	const icons = { server: Server, cloud: Cloud, shield: Shield };
	let Icon = $derived(icons[kit.icon as keyof typeof icons] || Server);
</script>

<div class="card card-hover p-8 cursor-pointer group" role="button" tabindex="0" onclick={() => (expanded = !expanded)} onkeydown={(e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); expanded = !expanded; } }}>
	<div class="flex items-center justify-between mb-6">
		<div class="w-12 h-12 bg-primary/10 rounded-xl flex items-center justify-center text-primary">
			<Icon class="w-6 h-6" />
		</div>
		<span
			class="badge {kit.status === 'available' ? 'badge-success' : 'badge-secondary'}"
		>
			{kit.status === 'available' ? 'Available' : 'Coming Soon'}
		</span>
	</div>

	<h3 class="text-xl font-bold text-foreground mb-2">{kit.name}</h3>
	<p class="text-sm text-primary mb-4">{kit.tagline}</p>
	<p class="text-muted-foreground mb-6">{kit.description}</p>

	<div class="flex items-center gap-4 text-sm text-muted-foreground mb-6">
		<div class="flex items-center gap-1">
			<Server class="w-4 h-4" />
			{kit.nodes}
		</div>
		<div class="flex items-center gap-1 {kit.cloud ? 'text-primary' : ''}">
			<Cloud class="w-4 h-4" />
			{kit.cloud ? 'Cloud-Ready' : 'Local Only'}
		</div>
	</div>

	<button class="flex items-center gap-2 text-primary font-medium text-sm">
		{expanded ? 'Hide Details' : 'View Details'}
		{#if expanded}
			<ChevronUp class="w-4 h-4" />
		{:else}
			<ChevronDown class="w-4 h-4" />
		{/if}
	</button>

	{#if expanded}
		<div class="mt-6 pt-6 border-t border-border space-y-6">
			<div>
				<h4 class="font-semibold text-foreground mb-3">Features</h4>
				<ul class="space-y-2">
					{#each kit.features as feature}
						<li class="flex items-start gap-3">
							<Check class="w-4 h-4 text-primary flex-shrink-0 mt-0.5" />
							<span class="text-sm text-muted-foreground">{feature}</span>
						</li>
					{/each}
				</ul>
			</div>

			<div>
				<h4 class="font-semibold text-foreground mb-3">Included Services</h4>
				<div class="flex flex-wrap gap-2">
					{#each kit.services as service}
						<span class="badge badge-secondary">{service}</span>
					{/each}
				</div>
			</div>

			{#if kit.status === 'available'}
				<a href="/get-started" class="btn btn-primary w-full justify-center">
					Get Started with {kit.name}
				</a>
			{/if}
		</div>
	{/if}
</div>
