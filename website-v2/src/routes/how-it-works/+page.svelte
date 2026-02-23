<script lang="ts">
	import { ArrowRight, FileCode, Box, GitBranch, Shield, Zap, Layers, Terminal } from 'lucide-svelte';
	import ScrollReveal from '$lib/components/ScrollReveal.svelte';

	const architectureComponents = [
		{
			icon: FileCode,
			name: 'CUE',
			role: 'Schema & Validation',
			description:
				'Defines and validates your infrastructure configuration. Type-safe YAML with built-in validation ensures your specs are correct before deployment.'
		},
		{
			icon: Box,
			name: 'OpenTofu',
			role: 'Infrastructure Provisioning',
			description:
				'Open-source infrastructure provisioning tool. Manages state, dependencies, and ensures idempotent deployments.'
		},
		{
			icon: GitBranch,
			name: 'Terramate',
			role: 'Stack Orchestration',
			description:
				'Orchestrates multiple OpenTofu stacks. Handles dependency graphs, parallel execution, and change detection across your infrastructure.'
		}
	];

	const benefits = [
		{
			icon: Shield,
			title: 'Type-Safe Configuration',
			description:
				'CUE validates your configuration before deployment, catching errors early and preventing invalid states.'
		},
		{
			icon: Zap,
			title: 'Fast & Efficient',
			description:
				"Terramate detects changes and only applies what's needed. Parallel execution speeds up large deployments."
		},
		{
			icon: Layers,
			title: 'Composable Architecture',
			description:
				'Mix and match StackKits, Add-Ons, and services. Build complex infrastructures from simple, tested components.'
		}
	];

	const flowSteps = [
		{ label: 'YAML Spec', color: 'bg-info/10 text-info border-info/20' },
		{ label: 'CUE Validation', color: 'bg-info/10 text-info border-info/20' },
		{ label: 'Terramate Orchestration', color: 'bg-success/10 text-success border-success/20' },
		{ label: 'OpenTofu Deploy', color: 'bg-primary/10 text-primary border-primary/20' }
	];

	const deepDiveSections = [
		{
			id: 'cue',
			title: 'Type Safety with CUE',
			content: 'CUE brings type safety to infrastructure configuration. Unlike plain YAML, CUE enforces constraints, validates relationships, and catches configuration errors before deployment. This means fewer runtime failures and more confidence in your infrastructure.'
		},
		{
			id: 'tofu',
			title: 'Declarative Infrastructure with OpenTofu',
			content: "OpenTofu manages your infrastructure state and ensures idempotency. It provisions resources in the correct order, handles dependencies, and makes infrastructure changes predictable and reversible. As an open-source project, it's community-driven and enterprise-ready."
		},
		{
			id: 'terramate',
			title: 'Smart Orchestration with Terramate',
			content: 'Terramate adds intelligent orchestration on top of OpenTofu. It detects which stacks have changed, executes them in the correct order based on dependencies, and can run independent stacks in parallel. This dramatically speeds up large infrastructure deployments.'
		},
		{
			id: 'result',
			title: 'The Result: StackKits',
			content: 'By combining these tools, StackKits provides pre-validated infrastructure templates that "just work". The complexity is hidden behind simple commands, but the power and flexibility remain available when you need them.'
		}
	];

	let expandedSection = $state<string | null>(null);

	function toggleSection(id: string) {
		expandedSection = expandedSection === id ? null : id;
	}
</script>

<svelte:head>
	<title>How It Works - kombify StackKits</title>
	<meta name="description" content="Learn how StackKits combines CUE, OpenTofu, and Terramate to create a robust, type-safe infrastructure deployment platform." />
</svelte:head>

<!-- Header -->
<section class="py-16 border-b border-border">
	<div class="max-w-6xl mx-auto px-6">
		<ScrollReveal>
			<div class="text-center">
				<h1 class="text-4xl font-bold">How It Works</h1>
				<p class="mt-4 text-lg text-muted-foreground max-w-3xl mx-auto">
					StackKits combines three powerful tools to create a robust, type-safe infrastructure deployment platform.
				</p>
			</div>
		</ScrollReveal>
	</div>
</section>

<!-- Core Vision -->
<section class="py-16">
	<div class="max-w-4xl mx-auto px-6">
		<ScrollReveal>
			<div class="text-center mb-12">
				<Terminal class="w-16 h-16 text-primary mx-auto mb-6" />
				<h2 class="text-3xl font-bold mb-4">One Vision: Simplicity</h2>
				<p class="text-xl text-muted-foreground mb-8">
					Our goal is to reduce infrastructure deployment to its essence:
				</p>

				<div class="inline-block text-left">
					<div class="card p-8 font-mono text-sm">
						<div class="text-primary mb-2">$ stackkit prepare</div>
						<div class="text-success text-xs mb-4">&check; Environment validated</div>
						<div class="text-primary mb-2">$ stackkit init</div>
						<div class="text-success text-xs">&check; Your homelab is running!</div>
					</div>
				</div>

				<p class="text-muted-foreground mt-6">Two commands. No complexity. Your infrastructure stands.</p>
			</div>
		</ScrollReveal>
	</div>
</section>

<!-- Architecture Flow -->
<section class="py-16 bg-card/30">
	<div class="max-w-6xl mx-auto px-6">
		<ScrollReveal>
			<h2 class="text-3xl font-bold text-center mb-4">The Architecture</h2>
			<p class="text-lg text-muted-foreground text-center max-w-2xl mx-auto mb-12">
				Three best-in-class tools work together seamlessly.
			</p>
		</ScrollReveal>

		<!-- Tech Cards -->
		<div class="grid md:grid-cols-3 gap-8 mb-12">
			{#each architectureComponents as component, i}
				{@const Icon = component.icon}
				<ScrollReveal delay={i * 0.1}>
					<div class="card card-hover p-8">
						<div class="w-16 h-16 bg-primary/10 rounded-lg flex items-center justify-center mb-6">
							<Icon class="w-8 h-8 text-primary" />
						</div>
						<h3 class="text-2xl font-bold mb-2">{component.name}</h3>
						<div class="text-sm font-semibold text-primary mb-4">{component.role}</div>
						<p class="text-muted-foreground leading-relaxed">{component.description}</p>
					</div>
				</ScrollReveal>
			{/each}
		</div>

		<!-- Flow Diagram -->
		<ScrollReveal delay={0.3}>
			<div class="card p-8">
				<h3 class="text-xl font-bold text-center mb-6">The Flow</h3>
				<div class="flex flex-col md:flex-row items-center justify-center gap-4">
					{#each flowSteps as step, i}
						<div class="text-center">
							<div class="rounded-lg px-6 py-3 font-semibold text-sm border {step.color}">
								{step.label}
							</div>
						</div>
						{#if i < flowSteps.length - 1}
							<ArrowRight class="w-6 h-6 text-muted-foreground rotate-90 md:rotate-0" />
						{/if}
					{/each}
				</div>
				<p class="text-center text-muted-foreground mt-6 text-sm">
					Your configuration flows through validation, orchestration, and provisioning - all automated.
				</p>
			</div>
		</ScrollReveal>
	</div>
</section>

<!-- Benefits -->
<section class="py-16">
	<div class="max-w-6xl mx-auto px-6">
		<ScrollReveal>
			<h2 class="text-3xl font-bold text-center mb-4">Why This Makes StackKits Great</h2>
			<p class="text-lg text-muted-foreground text-center max-w-2xl mx-auto mb-12">
				Each tool brings essential capabilities to the platform.
			</p>
		</ScrollReveal>

		<div class="grid md:grid-cols-3 gap-8">
			{#each benefits as benefit, i}
				{@const Icon = benefit.icon}
				<ScrollReveal delay={i * 0.1}>
					<div class="card p-8 border-primary/10">
						<Icon class="w-12 h-12 text-primary mb-4" />
						<h3 class="text-xl font-bold mb-3">{benefit.title}</h3>
						<p class="text-muted-foreground leading-relaxed">{benefit.description}</p>
					</div>
				</ScrollReveal>
			{/each}
		</div>
	</div>
</section>

<!-- Technical Deep Dive -->
<section class="py-16 bg-card/30">
	<div class="max-w-4xl mx-auto px-6">
		<ScrollReveal>
			<div class="card p-8">
				<h2 class="text-2xl font-bold mb-6">Technical Deep Dive</h2>

				<div class="space-y-4">
					{#each deepDiveSections as section}
						<div class="border border-border rounded-lg">
							<button
								class="w-full text-left px-6 py-4 flex items-center justify-between hover:bg-muted/50 transition-colors rounded-lg"
								onclick={() => toggleSection(section.id)}
							>
								<h3 class="text-lg font-semibold">{section.title}</h3>
								<span class="text-muted-foreground text-xl">
									{expandedSection === section.id ? '−' : '+'}
								</span>
							</button>
							{#if expandedSection === section.id}
								<div class="px-6 pb-4">
									<p class="text-muted-foreground leading-relaxed">{section.content}</p>
								</div>
							{/if}
						</div>
					{/each}
				</div>
			</div>
		</ScrollReveal>
	</div>
</section>
