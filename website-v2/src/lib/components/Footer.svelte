<script lang="ts">
	/**
	 * Modern Full Footer - Based on FooterModern from kombify Design Showcase
	 */
	import { Github, Twitter, Heart } from 'lucide-svelte';

	const currentYear = new Date().getFullYear();

	let logoImageFailed = $state(false);

	function handleLogoError() {
		logoImageFailed = true;
	}

	const productLinks = [
		{ label: 'Overview', href: '/overview' },
		{ label: 'Use Cases', href: '/use-cases' },
		{ label: 'Get Started', href: '/get-started' },
		{ label: 'CLI & API', href: '/cli-api' },
		{ label: 'How It Works', href: '/how-it-works' }
	];

	const portalUrl = import.meta.env.VITE_PORTAL_URL || 'https://kombify.io';

	const companyLinks = [
		{ label: 'kombify Platform', href: portalUrl, external: true },
		{ label: 'About', href: portalUrl, external: true },
		{ label: 'Contact', href: 'mailto:info@kombify.io', external: true }
	];

	const legalLinks = [
		{ label: 'Impressum', href: '/impressum' },
		{ label: 'Privacy', href: '/privacy' },
		{ label: 'Terms', href: '/terms' }
	];

	const socialLinks = [
		{ label: 'GitHub', href: 'https://github.com/kombiverse', icon: Github },
		{ label: 'Twitter', href: 'https://twitter.com/kombify', icon: Twitter }
	];

	function isExternal(link: { external?: boolean; href: string }): boolean {
		return link.external === true || link.href.startsWith('http') || link.href.startsWith('mailto:');
	}
</script>

<footer class="w-full border-t border-border bg-gradient-to-b from-background to-muted/20">
	<div class="max-w-7xl mx-auto px-4 sm:px-6">
		<!-- Main Footer Content -->
		<div class="py-10 grid grid-cols-2 md:grid-cols-5 gap-8">
			<!-- Logo + Description Column (spans 2 cols) -->
			<div class="col-span-2">
				<div class="flex items-center gap-3 mb-4">
					<a href="/" class="inline-flex items-center gap-3 group">
						<div class="w-auto h-12 rounded-xl overflow-hidden flex-shrink-0 transition-transform group-hover:scale-105">
							{#if !logoImageFailed}
								<img
									src="/kombify-logo.png"
									alt="kombify"
									class="h-full w-auto object-contain"
									onerror={handleLogoError}
								/>
							{:else}
								<div class="h-full w-12 rounded-xl bg-gradient-to-br from-violet-500 via-cyan-500 to-orange-500 flex items-center justify-center text-white font-bold text-lg">
									K
								</div>
							{/if}
						</div>
					</a>
				</div>
				<p class="text-sm text-muted-foreground max-w-xs mb-4 leading-relaxed">
					Curated infrastructure blueprints for your digital home.
					Professional standards, open source, fully yours.
				</p>
				<!-- Social Links -->
				<div class="flex items-center gap-2">
					{#each socialLinks as social}
						{@const Icon = social.icon}
						<a
							href={social.href}
							target="_blank"
							rel="noopener noreferrer"
							class="p-2 rounded-lg text-muted-foreground hover:text-foreground hover:bg-muted/50 transition-all"
							aria-label={social.label}
						>
							<Icon class="w-5 h-5" />
						</a>
					{/each}
				</div>
			</div>

			<!-- Product Links -->
			<div>
				<h3 class="text-sm font-semibold text-foreground mb-4">Product</h3>
				<ul class="space-y-3">
					{#each productLinks as link}
						<li>
							<a
								href={link.href}
								class="text-sm text-muted-foreground hover:text-foreground transition-colors"
							>
								{link.label}
							</a>
						</li>
					{/each}
				</ul>
			</div>

			<!-- Company Links -->
			<div>
				<h3 class="text-sm font-semibold text-foreground mb-4">Company</h3>
				<ul class="space-y-3">
					{#each companyLinks as link}
						<li>
							<a
								href={link.href}
								target={isExternal(link) ? '_blank' : undefined}
								rel={isExternal(link) ? 'noopener noreferrer' : undefined}
								class="text-sm text-muted-foreground hover:text-foreground transition-colors"
							>
								{link.label}
							</a>
						</li>
					{/each}
				</ul>
			</div>

			<!-- Legal Links -->
			<div>
				<h3 class="text-sm font-semibold text-foreground mb-4">Legal</h3>
				<ul class="space-y-3">
					{#each legalLinks as link}
						<li>
							<span class="text-sm text-muted-foreground">
								{link.label}
							</span>
						</li>
					{/each}
				</ul>
			</div>
		</div>

		<!-- Bottom Bar -->
		<div class="py-4 border-t border-border flex flex-col sm:flex-row items-center justify-between gap-4">
			<p class="text-sm text-muted-foreground">
				&copy; {currentYear} Kombiverse Labs. Made for humans, powered by intelligence.
			</p>
			<p class="text-sm text-muted-foreground flex items-center gap-1.5">
				Made with <Heart class="w-3.5 h-3.5 text-red-500 fill-red-500" /> for the homelab community
			</p>
		</div>
	</div>
</footer>
