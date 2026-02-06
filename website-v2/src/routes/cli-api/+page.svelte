<script lang="ts">
	import { ArrowRight, Terminal, Globe, FileCode, Zap, Shield, Server, ExternalLink, HelpCircle, Cpu, Copy, Check } from 'lucide-svelte';
	import ScrollReveal from '$lib/components/ScrollReveal.svelte';
	import CodeBlock from '$lib/components/CodeBlock.svelte';

	const cliCommands = [
		{
			command: 'stackkit prepare',
			description: 'Validates your environment: checks dependencies, SSH access, and server readiness.',
			flags: ['--verbose', '--skip-ssh', '--check-only']
		},
		{
			command: 'stackkit init <kit-name>',
			description: 'Initializes and deploys a StackKit to your target server.',
			flags: ['--dry-run', '--spec <file>', '--force']
		},
		{
			command: 'stackkit validate <spec>',
			description: 'Validates a spec file against the CUE schema. Catches configuration errors before deployment.',
			flags: ['--strict', '--show-defaults']
		},
		{
			command: 'stackkit status',
			description: 'Shows the current state of your deployed infrastructure.',
			flags: ['--json', '--watch']
		},
		{
			command: 'stackkit update',
			description: 'Applies configuration changes or upgrades to your running stack.',
			flags: ['--plan-only', '--auto-approve']
		},
		{
			command: 'stackkit destroy',
			description: 'Tears down your deployed infrastructure cleanly and completely.',
			flags: ['--force', '--keep-data']
		}
	];

	const apiEndpoints = [
		{
			method: 'GET',
			path: '/api/v1/stackkits',
			description: 'List all available StackKits with metadata, versions, and compatibility info.'
		},
		{
			method: 'GET',
			path: '/api/v1/stackkits/{id}',
			description: 'Get detailed information about a specific StackKit including schema and defaults.'
		},
		{
			method: 'POST',
			path: '/api/v1/validate',
			description: 'Validate a spec file against the StackKit schema. Returns errors and warnings.'
		},
		{
			method: 'POST',
			path: '/api/v1/plan',
			description: 'Generate an execution plan without applying changes. Shows what would happen.'
		},
		{
			method: 'POST',
			path: '/api/v1/apply',
			description: 'Apply a validated spec to provision or update infrastructure.'
		},
		{
			method: 'GET',
			path: '/api/v1/status',
			description: 'Query the current state of deployed infrastructure and running services.'
		}
	];

	const methodColors: Record<string, string> = {
		GET: 'badge-success',
		POST: 'badge-primary',
		PUT: 'badge-secondary',
		DELETE: 'badge-destructive'
	};

	const softwareRequirements = [
		{ name: 'Docker', version: '24.0+', required: true, description: 'Container runtime', url: 'https://docs.docker.com/get-docker/' },
		{ name: 'OpenTofu', version: '1.6+', required: true, description: 'Infrastructure provisioning', url: 'https://opentofu.org/docs/intro/install/' },
		{ name: 'Terramate', version: '0.6+', required: false, description: 'Stack orchestration', url: 'https://terramate.io/docs/cli/installation' },
		{ name: 'CUE', version: '0.9+', required: false, description: 'Schema validation', url: 'https://cuelang.org/docs/introduction/installation/' }
	];
</script>

<svelte:head>
	<title>CLI & API - kombify StackKits</title>
	<meta name="description" content="StackKits CLI reference and API documentation. Deploy infrastructure with simple commands or integrate programmatically." />
</svelte:head>

<!-- Header -->
<section class="py-16 border-b border-border">
	<div class="max-w-6xl mx-auto px-6">
		<ScrollReveal>
			<div class="text-center">
				<h1 class="text-4xl font-bold">CLI & API</h1>
				<p class="mt-4 text-lg text-muted-foreground max-w-2xl mx-auto">
					Deploy with simple commands or integrate programmatically. Two interfaces, one powerful platform.
				</p>
			</div>
		</ScrollReveal>
	</div>
</section>

<!-- CLI Section -->
<section class="py-20">
	<div class="max-w-5xl mx-auto px-6">
		<ScrollReveal>
			<div class="flex items-center gap-3 mb-8">
				<div class="w-12 h-12 bg-primary/10 rounded-xl flex items-center justify-center text-primary">
					<Terminal class="w-6 h-6" />
				</div>
				<div>
					<h2 class="text-3xl font-bold">CLI Tool</h2>
					<p class="text-muted-foreground">The fastest way to deploy and manage your infrastructure.</p>
				</div>
			</div>
		</ScrollReveal>

		<!-- Install -->
		<ScrollReveal delay={0.1}>
			<div class="card p-6 mb-8 border-primary/20">
				<h3 class="text-sm font-semibold text-muted-foreground uppercase tracking-wide mb-3">Installation</h3>
				<CodeBlock command="curl -fsSL https://stackkits.kombify.io/install.sh | sh" />
				<p class="text-sm text-muted-foreground mt-3">
					Or install via npm: <code class="text-primary">npm install -g @kombify/stackkit-cli</code>
				</p>
			</div>
		</ScrollReveal>

		<!-- Commands -->
		<div class="space-y-4">
			{#each cliCommands as cmd, i}
				<ScrollReveal delay={i * 0.06}>
					<div class="card p-6">
						<div class="flex flex-col sm:flex-row sm:items-start gap-4">
							<div class="flex-1">
								<code class="text-primary font-semibold text-sm">$ {cmd.command}</code>
								<p class="text-muted-foreground text-sm mt-2">{cmd.description}</p>
							</div>
							<div class="flex flex-wrap gap-2">
								{#each cmd.flags as flag}
									<span class="text-xs font-mono text-muted-foreground bg-muted px-2 py-1 rounded">{flag}</span>
								{/each}
							</div>
						</div>
					</div>
				</ScrollReveal>
			{/each}
		</div>
	</div>
</section>

<!-- API Section -->
<section class="py-20 bg-card/30">
	<div class="max-w-5xl mx-auto px-6">
		<ScrollReveal>
			<div class="flex items-center gap-3 mb-8">
				<div class="w-12 h-12 bg-primary/10 rounded-xl flex items-center justify-center text-primary">
					<Globe class="w-6 h-6" />
				</div>
				<div>
					<h2 class="text-3xl font-bold">REST API</h2>
					<p class="text-muted-foreground">Programmatic access for automation and integration.</p>
				</div>
			</div>
		</ScrollReveal>

		<ScrollReveal delay={0.1}>
			<div class="card p-6 mb-8 border-primary/20">
				<h3 class="text-sm font-semibold text-muted-foreground uppercase tracking-wide mb-3">Base URL</h3>
				<code class="text-primary font-semibold text-sm">https://api.stackkits.kombify.io/api/v1</code>
				<p class="text-sm text-muted-foreground mt-3">
					Authentication via API key in the <code class="text-primary">Authorization</code> header. Available with kombify Pro and Team plans.
				</p>
			</div>
		</ScrollReveal>

		<div class="space-y-4">
			{#each apiEndpoints as endpoint, i}
				<ScrollReveal delay={i * 0.06}>
					<div class="card p-6">
						<div class="flex items-start gap-4">
							<span class="badge {methodColors[endpoint.method]} text-xs font-mono flex-shrink-0 mt-0.5">
								{endpoint.method}
							</span>
							<div class="flex-1">
								<code class="text-foreground font-semibold text-sm">{endpoint.path}</code>
								<p class="text-muted-foreground text-sm mt-1">{endpoint.description}</p>
							</div>
						</div>
					</div>
				</ScrollReveal>
			{/each}
		</div>

		<ScrollReveal delay={0.4}>
			<div class="mt-8 card p-6">
				<h3 class="font-semibold mb-3">Example: Validate a Spec</h3>
				<CodeBlock command={'curl -X POST https://api.stackkits.kombify.io/api/v1/validate \\\n  -H "Authorization: Bearer $API_KEY" \\\n  -H "Content-Type: application/json" \\\n  -d @my-spec.yaml'} />
			</div>
		</ScrollReveal>
	</div>
</section>

<!-- Requirements -->
<section class="py-20">
	<div class="max-w-5xl mx-auto px-6">
		<ScrollReveal>
			<div class="flex items-center gap-3 mb-8">
				<div class="w-12 h-12 bg-primary/10 rounded-xl flex items-center justify-center text-primary">
					<Server class="w-6 h-6" />
				</div>
				<div>
					<h2 class="text-3xl font-bold">Requirements</h2>
					<p class="text-muted-foreground">Minimal dependencies. Standard hardware. Maximum flexibility.</p>
				</div>
			</div>
		</ScrollReveal>

		<div class="grid md:grid-cols-2 gap-8">
			<!-- Software -->
			<div class="space-y-4">
				<h3 class="text-sm font-semibold text-muted-foreground uppercase tracking-wide">Software Dependencies</h3>
				{#each softwareRequirements as req, i}
					<ScrollReveal delay={i * 0.08}>
						<div class="card p-5">
							<div class="flex items-center gap-3 mb-1">
								<span class="font-semibold">{req.name}</span>
								<span class="text-sm text-muted-foreground">{req.version}</span>
								<span class="badge {req.required ? 'badge-primary' : 'badge-secondary'} text-xs">
									{req.required ? 'Required' : 'Optional'}
								</span>
							</div>
							<p class="text-sm text-muted-foreground">{req.description}</p>
							<a href={req.url} target="_blank" rel="noopener" class="inline-flex items-center gap-1 text-sm text-primary hover:text-primary/80 mt-2">
								Install <ExternalLink class="w-3 h-3" />
							</a>
						</div>
					</ScrollReveal>
				{/each}
			</div>

			<!-- Hardware -->
			<div>
				<h3 class="text-sm font-semibold text-muted-foreground uppercase tracking-wide mb-4">Server Requirements</h3>
				<ScrollReveal delay={0.1}>
					<div class="card p-6 mb-4">
						<div class="grid grid-cols-2 gap-8">
							<div>
								<h4 class="text-sm font-medium text-muted-foreground uppercase mb-3">Minimum</h4>
								<ul class="space-y-2 text-sm">
									<li class="flex items-center gap-2"><Cpu class="w-3 h-3 text-primary/40" /> 2 Cores</li>
									<li class="flex items-center gap-2"><Cpu class="w-3 h-3 text-primary/40" /> 4 GB RAM</li>
									<li class="flex items-center gap-2"><Cpu class="w-3 h-3 text-primary/40" /> 50 GB SSD</li>
								</ul>
							</div>
							<div>
								<h4 class="text-sm font-medium text-muted-foreground uppercase mb-3">Recommended</h4>
								<ul class="space-y-2 text-sm">
									<li class="flex items-center gap-2"><Cpu class="w-3 h-3 text-primary" /> 4 Cores</li>
									<li class="flex items-center gap-2"><Cpu class="w-3 h-3 text-primary" /> 8 GB RAM</li>
									<li class="flex items-center gap-2"><Cpu class="w-3 h-3 text-primary" /> 100 GB SSD</li>
								</ul>
							</div>
						</div>
					</div>
				</ScrollReveal>

				<ScrollReveal delay={0.2}>
					<div class="card p-6">
						<h4 class="text-sm font-medium text-muted-foreground uppercase mb-3">Supported OS</h4>
						<ul class="space-y-2 text-sm">
							<li class="flex items-center justify-between">
								<span>Ubuntu 24.04 LTS</span>
								<span class="badge badge-success text-xs">Recommended</span>
							</li>
							<li class="text-muted-foreground">Ubuntu 22.04 LTS</li>
							<li class="text-muted-foreground">Debian 12</li>
						</ul>
					</div>
				</ScrollReveal>

				<ScrollReveal delay={0.3}>
					<div class="mt-4 flex items-start gap-3 p-4 rounded-lg bg-primary/5 border border-primary/10">
						<HelpCircle class="w-5 h-5 text-primary flex-shrink-0 mt-0.5" />
						<p class="text-sm text-muted-foreground">
							For local development, you only need Docker and OpenTofu. Your target server just needs SSH access and Docker.
						</p>
					</div>
				</ScrollReveal>
			</div>
		</div>
	</div>
</section>

<!-- CTA -->
<section class="py-16 bg-card/50 border-t border-border">
	<div class="max-w-4xl mx-auto px-6 text-center">
		<ScrollReveal>
			<h2 class="text-3xl font-bold mb-4">Start Deploying</h2>
			<p class="text-muted-foreground mb-8">
				Install the CLI and deploy your first StackKit in minutes.
			</p>
			<a href="/get-started" class="btn btn-primary btn-lg">
				Get Started
				<ArrowRight class="w-4 h-4" />
			</a>
		</ScrollReveal>
	</div>
</section>
