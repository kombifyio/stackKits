<script lang="ts">
	import { ArrowRight, Shield, Zap, CheckCircle, GitBranch, Lock, Blocks, Award, Eye } from 'lucide-svelte';
	import TerminalDemo from '$lib/components/TerminalDemo.svelte';
	import ScrollReveal from '$lib/components/ScrollReveal.svelte';
	import StackKitCard from '$lib/components/StackKitCard.svelte';
	import CompareTable from '$lib/components/CompareTable.svelte';
	import { stackkits } from '$lib/data/stackkits';
</script>

<svelte:head>
	<title>kombify StackKits - Your Homelab. Two Commands.</title>
	<meta name="description" content="Deploy your homelab infrastructure in two commands. StackKits provides validated, battle-tested blueprints powered by CUE, OpenTofu, and Terramate." />
</svelte:head>

<!-- Hero Section -->
<section class="relative overflow-hidden min-h-[90vh] flex items-center">
	<div class="absolute inset-0 bg-[radial-gradient(ellipse_at_top,oklch(from_var(--primary)_l_c_h_/_0.08),transparent_60%)]"></div>
	<img
		src="/stackkits-icon.png"
		alt=""
		class="absolute right-[-8%] top-[15%] w-[500px] h-[500px] opacity-[0.04] pointer-events-none select-none hidden lg:block"
	/>

	<div class="relative max-w-6xl mx-auto px-6 py-24 lg:py-32">
		<div class="grid lg:grid-cols-2 gap-12 items-center">
			<div>
				<ScrollReveal>
					<h1 class="text-4xl sm:text-5xl lg:text-6xl font-extrabold leading-tight">
						Your Homelab.
						<br />
						<span class="text-gradient">Two Commands.</span>
					</h1>
				</ScrollReveal>

				<ScrollReveal delay={0.1}>
					<p class="mt-6 text-lg text-muted-foreground max-w-lg">
						Deploy, manage, and scale your infrastructure with pre-validated blueprints.
						No YAML chaos. No manual setup. Just results.
					</p>
				</ScrollReveal>

				<ScrollReveal delay={0.2}>
					<div class="mt-8 flex flex-wrap gap-4">
						<a href="/get-started" class="btn btn-primary btn-lg">
							Get Started
							<ArrowRight class="w-4 h-4" />
						</a>
						<a href="/how-it-works" class="btn btn-outline btn-lg">
							See How It Works
						</a>
					</div>
				</ScrollReveal>
			</div>

			<ScrollReveal delay={0.3}>
				<TerminalDemo />
			</ScrollReveal>
		</div>
	</div>
</section>

<!-- Social Proof Bar -->
<section class="border-y border-border bg-card/30">
	<div class="max-w-6xl mx-auto px-6 py-6">
		<div class="flex flex-wrap justify-center gap-8 md:gap-16 text-sm text-muted-foreground">
			<div class="flex items-center gap-2">
				<Award class="w-4 h-4 text-primary" />
				<span>Curated Tools</span>
			</div>
			<div class="flex items-center gap-2">
				<Shield class="w-4 h-4 text-primary" />
				<span>Professional Standards</span>
			</div>
			<div class="flex items-center gap-2">
				<Lock class="w-4 h-4 text-primary" />
				<span>CUE-Validated</span>
			</div>
			<div class="flex items-center gap-2">
				<GitBranch class="w-4 h-4 text-primary" />
				<span>Open Source</span>
			</div>
			<div class="flex items-center gap-2">
				<Zap class="w-4 h-4 text-primary" />
				<span>Deploy in Minutes</span>
			</div>
		</div>
	</div>
</section>

<!-- Problem / Solution -->
<section class="py-20">
	<div class="max-w-6xl mx-auto px-6">
		<ScrollReveal>
			<h2 class="text-3xl font-bold text-center mb-4">Stop Fighting Your Infrastructure</h2>
			<p class="text-muted-foreground text-center max-w-2xl mx-auto mb-16">
				Traditional homelab setup is complex, error-prone, and time-consuming. StackKits changes that.
			</p>
		</ScrollReveal>

		<div class="grid md:grid-cols-2 gap-8">
			<ScrollReveal delay={0.1}>
				<div class="card p-8 border-destructive/20">
					<h3 class="text-lg font-semibold text-destructive mb-6">The Old Way</h3>
					<div class="space-y-3 font-mono text-sm">
						<div class="text-muted-foreground/50 line-through">$ ssh root@server "apt update && apt install docker.io -y"</div>
						<div class="text-muted-foreground/50 line-through">$ scp docker-compose.yml root@server:/opt/</div>
						<div class="text-muted-foreground/50 line-through">$ ssh root@server "cd /opt && docker compose up -d"</div>
						<div class="text-muted-foreground/50 line-through">$ # configure reverse proxy manually...</div>
						<div class="text-muted-foreground/50 line-through">$ # set up TLS certificates...</div>
						<div class="text-muted-foreground/50 line-through">$ # add monitoring...</div>
						<div class="text-muted-foreground/50 line-through">$ # hope nothing breaks</div>
					</div>
					<p class="mt-6 text-sm text-muted-foreground">Hours of manual configuration. No validation. No reproducibility.</p>
				</div>
			</ScrollReveal>

			<ScrollReveal delay={0.2}>
				<div class="card p-8 border-success/20">
					<h3 class="text-lg font-semibold text-success mb-6">The StackKits Way</h3>
					<div class="space-y-3 font-mono text-sm">
						<div class="text-primary">$ stackkit prepare</div>
						<div class="text-success">&check; Environment validated</div>
						<div class="text-primary mt-4">$ stackkit init base</div>
						<div class="text-success">&check; Your homelab is running!</div>
					</div>
					<p class="mt-6 text-sm text-muted-foreground">Two commands. Validated. Reproducible. Done.</p>
				</div>
			</ScrollReveal>
		</div>
	</div>
</section>

<!-- Features Grid -->
<section class="py-20 bg-card/30">
	<div class="max-w-6xl mx-auto px-6">
		<ScrollReveal>
			<h2 class="text-3xl font-bold text-center mb-4">Curated & Professional Standards</h2>
			<p class="text-muted-foreground text-center max-w-2xl mx-auto mb-16">
				Every tool is hand-picked, every configuration validated. Enterprise-grade practices made accessible for everyone.
			</p>
		</ScrollReveal>

		<div class="grid md:grid-cols-2 lg:grid-cols-4 gap-8">
			<ScrollReveal delay={0}>
				<div class="card card-hover p-8">
					<div class="w-12 h-12 bg-primary/10 rounded-xl flex items-center justify-center text-primary mb-6">
						<Award class="w-6 h-6" />
					</div>
					<h3 class="text-xl font-semibold mb-3">Curated Selection</h3>
					<p class="text-muted-foreground">
						Every tool is hand-picked and tested for compatibility, security, and long-term maintainability.
					</p>
				</div>
			</ScrollReveal>

			<ScrollReveal delay={0.1}>
				<div class="card card-hover p-8">
					<div class="w-12 h-12 bg-primary/10 rounded-xl flex items-center justify-center text-primary mb-6">
						<Shield class="w-6 h-6" />
					</div>
					<h3 class="text-xl font-semibold mb-3">Validated Config</h3>
					<p class="text-muted-foreground">
						CUE schemas catch errors before deployment. Type-safe, constraint-validated, production-ready.
					</p>
				</div>
			</ScrollReveal>

			<ScrollReveal delay={0.2}>
				<div class="card card-hover p-8">
					<div class="w-12 h-12 bg-primary/10 rounded-xl flex items-center justify-center text-primary mb-6">
						<Eye class="w-6 h-6" />
					</div>
					<h3 class="text-xl font-semibold mb-3">Fully Transparent</h3>
					<p class="text-muted-foreground">
						Open source, declarative, and auditable. No black-box magic — you always know what runs.
					</p>
				</div>
			</ScrollReveal>

			<ScrollReveal delay={0.3}>
				<div class="card card-hover p-8">
					<div class="w-12 h-12 bg-primary/10 rounded-xl flex items-center justify-center text-primary mb-6">
						<Zap class="w-6 h-6" />
					</div>
					<h3 class="text-xl font-semibold mb-3">Minutes to Deploy</h3>
					<p class="text-muted-foreground">
						Professional infrastructure in minutes. The same IaC practices used by Fortune 500 companies.
					</p>
				</div>
			</ScrollReveal>
		</div>
	</div>
</section>

<!-- StackKits Preview -->
<section class="py-20">
	<div class="max-w-6xl mx-auto px-6">
		<ScrollReveal>
			<h2 class="text-3xl font-bold text-center mb-4">Choose Your Architecture Pattern</h2>
			<p class="text-muted-foreground text-center max-w-2xl mx-auto mb-16">
				Three architecture patterns for different infrastructure needs. Add capabilities with composable Add-Ons.
			</p>
		</ScrollReveal>

		<div class="grid md:grid-cols-3 gap-8">
			{#each stackkits as kit, i}
				<ScrollReveal delay={i * 0.1}>
					<StackKitCard {kit} />
				</ScrollReveal>
			{/each}
		</div>

		<ScrollReveal delay={0.3}>
			<div class="mt-8 text-center">
				<a href="/overview" class="btn btn-outline">
					See Full Comparison
					<ArrowRight class="w-4 h-4" />
				</a>
			</div>
		</ScrollReveal>
	</div>
</section>

<!-- Comparison -->
<section class="py-20 bg-card/30">
	<div class="max-w-4xl mx-auto px-6">
		<ScrollReveal>
			<h2 class="text-3xl font-bold text-center mb-4">Why StackKits?</h2>
			<p class="text-muted-foreground text-center max-w-2xl mx-auto mb-12">
				See how StackKits compares to traditional approaches.
			</p>
		</ScrollReveal>

		<ScrollReveal delay={0.1}>
			<div class="card p-6">
				<CompareTable />
			</div>
		</ScrollReveal>
	</div>
</section>

<!-- CTA Section -->
<section class="py-20">
	<div class="max-w-4xl mx-auto px-6 text-center">
		<ScrollReveal>
			<h2 class="text-3xl font-bold mb-4">Ready to simplify your infrastructure?</h2>
			<p class="text-muted-foreground mb-8">
				Start with our Base Kit and deploy your infrastructure today.
			</p>
			<a href="/get-started" class="btn btn-primary btn-lg">
				Get Started Now
				<ArrowRight class="w-4 h-4" />
			</a>
		</ScrollReveal>
	</div>
</section>
