<script lang="ts">
	interface Props {
		autoplay?: boolean;
		class?: string;
	}

	let { autoplay = true, class: className = '' }: Props = $props();

	interface Line {
		type: 'command' | 'output' | 'success' | 'progress';
		text: string;
		delay: number;
	}

	const lines: Line[] = [
		{ type: 'command', text: '$ stackkit prepare', delay: 0 },
		{ type: 'output', text: 'Checking dependencies...', delay: 600 },
		{ type: 'progress', text: '[################] 100%', delay: 1200 },
		{ type: 'success', text: 'Environment validated', delay: 1800 },
		{ type: 'command', text: '$ stackkit init base-homelab', delay: 2600 },
		{ type: 'output', text: 'Validating configuration with CUE...', delay: 3200 },
		{ type: 'success', text: 'Configuration valid', delay: 3800 },
		{ type: 'output', text: 'Deploying Traefik...', delay: 4200 },
		{ type: 'success', text: 'Traefik running', delay: 4800 },
		{ type: 'output', text: 'Deploying Dokploy...', delay: 5200 },
		{ type: 'success', text: 'Dokploy running', delay: 5800 },
		{ type: 'output', text: 'Deploying Uptime Kuma...', delay: 6200 },
		{ type: 'success', text: 'Uptime Kuma running', delay: 6800 },
		{ type: 'output', text: '', delay: 7200 },
		{ type: 'success', text: 'Your homelab is running!', delay: 7400 }
	];

	let visibleLines = $state<number>(0);
	let element: HTMLDivElement | undefined = $state();
	let started = $state(false);

	function startAnimation() {
		if (started) return;
		started = true;
		visibleLines = 0;

		lines.forEach((line, i) => {
			setTimeout(() => {
				visibleLines = i + 1;
			}, line.delay);
		});

		// Reset after full cycle
		setTimeout(() => {
			started = false;
		}, 9000);
	}

	$effect(() => {
		if (!element || !autoplay) return;

		const observer = new IntersectionObserver(
			(entries) => {
				entries.forEach((entry) => {
					if (entry.isIntersecting) {
						startAnimation();
					}
				});
			},
			{ threshold: 0.3 }
		);

		observer.observe(element);
		return () => observer.disconnect();
	});
</script>

<div bind:this={element} class="rounded-xl overflow-hidden border border-border {className}">
	<!-- Terminal title bar -->
	<div class="bg-[oklch(0.15_0_0)] px-4 py-3 flex items-center gap-2">
		<div class="flex gap-1.5">
			<div class="w-3 h-3 rounded-full bg-destructive/60"></div>
			<div class="w-3 h-3 rounded-full bg-warning/60"></div>
			<div class="w-3 h-3 rounded-full bg-success/60"></div>
		</div>
		<span class="text-xs text-muted-foreground ml-2 font-mono">terminal</span>
	</div>

	<!-- Terminal body -->
	<div class="bg-[oklch(0.08_0_0)] p-6 font-mono text-sm min-h-[320px]">
		{#each lines.slice(0, visibleLines) as line}
			<div class="mb-1">
				{#if line.type === 'command'}
					<span class="text-primary font-medium">{line.text}</span>
				{:else if line.type === 'success'}
					<span class="text-success">&check; {line.text}</span>
				{:else if line.type === 'progress'}
					<span class="text-primary/70">{line.text}</span>
				{:else}
					<span class="text-muted-foreground">{line.text}</span>
				{/if}
			</div>
		{/each}
		{#if visibleLines < lines.length && started}
			<span class="inline-block w-2 h-4 bg-primary animate-pulse"></span>
		{/if}
	</div>
</div>
