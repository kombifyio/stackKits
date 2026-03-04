<script lang="ts">
	import { ArrowRight, Zap, Terminal, Github } from 'lucide-svelte';
	import ScrollReveal from '$lib/components/ScrollReveal.svelte';
	import CodeBlock from '$lib/components/CodeBlock.svelte';
	import TerminalDemo from '$lib/components/TerminalDemo.svelte';

	const detailedSteps = [
		{ number: '01', title: 'Clone the repository', command: 'git clone https://github.com/kombifyio/stackkits.git\ncd stackkits' },
		{ number: '02', title: 'Copy the default spec', command: 'cp base/default-spec.yaml my-spec.yaml' },
		{ number: '03', title: 'Configure your server', command: '# Edit my-spec.yaml\n# Set your server IP, SSH credentials, and domain' },
		{ number: '04', title: 'Validate your configuration', command: 'stackkit validate my-spec.yaml' },
		{ number: '05', title: 'Deploy', command: 'stackkit apply my-spec.yaml' }
	];

	let showDetailed = $state(false);
</script>

<svelte:head>
	<title>Get Started - kombify StackKits</title>
	<meta name="description" content="Get started with StackKits. From zero to running homelab in two simple commands." />
</svelte:head>

<!-- Header -->
<section class="py-16 border-b border-border">
	<div class="max-w-6xl mx-auto px-6">
		<ScrollReveal>
			<div class="text-center">
				<h1 class="text-4xl font-bold">Get Started</h1>
				<p class="mt-4 text-lg text-muted-foreground max-w-2xl mx-auto">
					From zero to running homelab in two simple commands.
				</p>
			</div>
		</ScrollReveal>
	</div>
</section>

<!-- Core Message -->
<section class="py-12 border-b border-border bg-primary/5">
	<div class="max-w-4xl mx-auto px-6 text-center">
		<ScrollReveal>
			<Zap class="w-12 h-12 text-primary mx-auto mb-4" />
			<h2 class="text-3xl font-bold mb-4">
				Run One Command. Your Homelab Stands.
			</h2>
			<p class="text-lg text-muted-foreground">
				That's our vision: A CLI tool that makes infrastructure deployment as simple as possible.
			</p>
		</ScrollReveal>
	</div>
</section>

<!-- Quick Start -->
<section class="py-16">
	<div class="max-w-4xl mx-auto px-6">
		<ScrollReveal>
			<div class="text-center mb-12">
				<h2 class="text-2xl font-bold mb-4">The Simple Way</h2>
				<p class="text-muted-foreground">Two commands to deploy your entire homelab.</p>
			</div>
		</ScrollReveal>

		<ScrollReveal delay={0.1}>
			<div class="grid md:grid-cols-2 gap-6 mb-12">
				<div class="card p-8 text-center border-primary/20">
					<div class="text-5xl font-bold text-primary/20 mb-4">01</div>
					<h3 class="text-xl font-semibold mb-3">Prepare your environment</h3>
					<div class="card p-4 font-mono text-sm text-primary">$ stackkit prepare</div>
					<p class="text-muted-foreground text-sm mt-4">
						Validates dependencies and sets up your local environment.
					</p>
				</div>

				<div class="card p-8 text-center border-primary/20">
					<div class="text-5xl font-bold text-primary/20 mb-4">02</div>
					<h3 class="text-xl font-semibold mb-3">Initialize your homelab</h3>
					<div class="card p-4 font-mono text-sm text-primary">$ stackkit init</div>
					<p class="text-muted-foreground text-sm mt-4">
						Deploys your complete infrastructure - that's it!
					</p>
				</div>
			</div>
		</ScrollReveal>

		<div class="text-center">
			<button
				onclick={() => (showDetailed = !showDetailed)}
				class="text-primary hover:text-primary/80 font-medium text-sm"
			>
				{showDetailed ? 'Hide detailed steps' : 'Show current detailed steps'}
			</button>
		</div>
	</div>
</section>

<!-- Detailed Steps -->
{#if showDetailed}
	<section class="py-16 bg-card/30">
		<div class="max-w-3xl mx-auto px-6">
			<div class="text-center mb-12">
				<h2 class="text-2xl font-bold mb-4">Current Process</h2>
				<p class="text-muted-foreground">
					Here's how it works today - we're working towards simplifying this.
				</p>
			</div>

			<div class="space-y-6">
				{#each detailedSteps as step, i}
					<ScrollReveal delay={i * 0.1}>
						<div class="card p-8 flex gap-6">
							<div class="flex-shrink-0">
								<div class="w-12 h-12 rounded-full bg-primary/10 flex items-center justify-center">
									<span class="text-primary font-bold text-sm">{step.number}</span>
								</div>
							</div>
							<div class="flex-1">
								<h3 class="text-xl font-semibold mb-3">{step.title}</h3>
								<CodeBlock command={step.command} />
							</div>
						</div>
					</ScrollReveal>
				{/each}
			</div>

			<ScrollReveal delay={0.5}>
				<div class="mt-12 alert">
					<Terminal class="w-6 h-6 text-primary flex-shrink-0" />
					<div>
						<h4 class="font-semibold mb-2">Need Help?</h4>
						<p class="text-sm text-muted-foreground mb-4">
							Check the documentation or join our community for support.
						</p>
						<a
							href="https://github.com/kombifyio/stackkits"
							target="_blank"
							rel="noopener"
							class="btn btn-primary btn-sm"
						>
							<Github class="w-4 h-4" />
							View on GitHub
						</a>
					</div>
				</div>
			</ScrollReveal>
		</div>
	</section>
{/if}

<!-- Why StackKits -->
<section class="py-16">
	<div class="max-w-6xl mx-auto px-6">
		<ScrollReveal>
			<h2 class="text-3xl font-bold text-center mb-12">Why StackKits?</h2>
		</ScrollReveal>

		<div class="grid md:grid-cols-3 gap-8">
			<ScrollReveal delay={0.1}>
				<div class="text-center">
					<div class="w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center mx-auto mb-4">
						<Zap class="w-8 h-8 text-primary" />
					</div>
					<h3 class="text-xl font-semibold mb-2">Lightning Fast</h3>
					<p class="text-muted-foreground">
						Deploy complex infrastructure in minutes, not hours or days.
					</p>
				</div>
			</ScrollReveal>

			<ScrollReveal delay={0.2}>
				<div class="text-center">
					<div class="w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center mx-auto mb-4">
						<Terminal class="w-8 h-8 text-primary" />
					</div>
					<h3 class="text-xl font-semibold mb-2">Simple CLI</h3>
					<p class="text-muted-foreground">
						No complex configurations. Just simple, intuitive commands.
					</p>
				</div>
			</ScrollReveal>

			<ScrollReveal delay={0.3}>
				<div class="text-center">
					<div class="w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center mx-auto mb-4">
						<Github class="w-8 h-8 text-primary" />
					</div>
					<h3 class="text-xl font-semibold mb-2">Open Source</h3>
					<p class="text-muted-foreground">
						Community-driven, transparent, and free to use and modify.
					</p>
				</div>
			</ScrollReveal>
		</div>
	</div>
</section>

<!-- CTA -->
<section class="py-16 bg-card/50 border-t border-border">
	<div class="max-w-4xl mx-auto px-6 text-center">
		<ScrollReveal>
			<h2 class="text-3xl font-bold mb-4">Ready to Start?</h2>
			<p class="text-muted-foreground mb-8">
				Join developers building better homelabs with StackKits.
			</p>
			<a href="/how-it-works" class="btn btn-primary btn-lg">
				Learn How It Works
				<ArrowRight class="w-5 h-5" />
			</a>
		</ScrollReveal>
	</div>
</section>
