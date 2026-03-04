<script lang="ts">
	import { Copy, Check } from 'lucide-svelte';

	interface Props {
		command: string;
		class?: string;
	}

	let { command, class: className = '' }: Props = $props();
	let copied = $state(false);

	function handleCopy() {
		navigator.clipboard.writeText(command);
		copied = true;
		setTimeout(() => (copied = false), 2000);
	}
</script>

<div class="relative group {className}">
	<pre class="bg-[oklch(0.1_0_0)] text-[oklch(0.9_0_0)] rounded-lg p-4 font-mono text-sm overflow-x-auto border border-border">{command}</pre>
	<button
		onclick={handleCopy}
		class="absolute top-2 right-2 p-2 rounded-lg bg-[oklch(0.15_0_0)] hover:bg-[oklch(0.2_0_0)] opacity-0 group-hover:opacity-100 transition-opacity"
		aria-label="Copy to clipboard"
	>
		{#if copied}
			<Check class="w-4 h-4 text-success" />
		{:else}
			<Copy class="w-4 h-4 text-muted-foreground" />
		{/if}
	</button>
</div>
