<script lang="ts">
	import type { Snippet } from 'svelte';

	interface Props {
		children: Snippet;
		direction?: 'up' | 'down' | 'left' | 'right';
		delay?: number;
		duration?: number;
		class?: string;
	}

	let {
		children,
		direction = 'up',
		delay = 0,
		duration = 0.6,
		class: className = ''
	}: Props = $props();

	let element: HTMLDivElement | undefined = $state();
	let visible = $state(false);

	const transforms: Record<string, string> = {
		up: 'translateY(30px)',
		down: 'translateY(-30px)',
		left: 'translateX(30px)',
		right: 'translateX(-30px)'
	};

	$effect(() => {
		if (!element) return;

		const observer = new IntersectionObserver(
			(entries) => {
				entries.forEach((entry) => {
					if (entry.isIntersecting) {
						visible = true;
						observer.unobserve(entry.target);
					}
				});
			},
			{ threshold: 0.1 }
		);

		observer.observe(element);

		return () => observer.disconnect();
	});
</script>

<div
	bind:this={element}
	class={className}
	style="opacity: {visible ? 1 : 0}; transform: {visible ? 'none' : transforms[direction]}; transition: opacity {duration}s ease-out {delay}s, transform {duration}s ease-out {delay}s;"
>
	{@render children()}
</div>
