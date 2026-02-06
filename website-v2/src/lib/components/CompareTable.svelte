<script lang="ts">
	import { Check, X } from 'lucide-svelte';

	const features = [
		'Validated Configuration',
		'Auto-Dependencies',
		'One-Command Deploy',
		'State Management',
		'Type Safety',
		'Idempotent'
	];

	const tools = [
		{
			name: 'StackKits',
			highlight: true,
			checks: [true, true, true, true, true, true]
		},
		{
			name: 'Docker Compose',
			highlight: false,
			checks: [false, false, false, false, false, true]
		},
		{
			name: 'Ansible',
			highlight: false,
			checks: [false, true, false, false, false, true]
		},
		{
			name: 'DIY Terraform',
			highlight: false,
			checks: [false, false, false, true, false, true]
		}
	];
</script>

<div class="overflow-x-auto">
	<table class="w-full text-sm">
		<thead>
			<tr class="border-b border-border">
				<th class="text-left py-3 px-4 text-muted-foreground font-medium">Feature</th>
				{#each tools as tool}
					<th
						class="text-center py-3 px-4 font-semibold {tool.highlight
							? 'text-primary'
							: 'text-foreground'}"
					>
						{tool.name}
					</th>
				{/each}
			</tr>
		</thead>
		<tbody>
			{#each features as feature, fi}
				<tr class="border-b border-border/50">
					<td class="py-3 px-4 text-muted-foreground">{feature}</td>
					{#each tools as tool}
						<td class="text-center py-3 px-4">
							{#if tool.checks[fi]}
								<Check
									class="w-5 h-5 mx-auto {tool.highlight
										? 'text-primary'
										: 'text-success'}"
								/>
							{:else}
								<X class="w-5 h-5 mx-auto text-muted-foreground/40" />
							{/if}
						</td>
					{/each}
				</tr>
			{/each}
		</tbody>
	</table>
</div>
