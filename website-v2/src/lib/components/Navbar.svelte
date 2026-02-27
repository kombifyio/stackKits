<script lang="ts">
	import { NavigationMenu } from 'bits-ui';
	import { page } from '$app/stores';
	import { ChevronDown, Menu, X, Rocket, BookOpen, Terminal, Layers, Server, Globe, Eye, Cloud, Shield, Zap, ExternalLink } from 'lucide-svelte';
	import ThemeSwitcher from './ThemeSwitcher.svelte';

	interface NavItem {
		href: string;
		label: string;
		description?: string;
		external?: boolean;
	}

	const getStartedItems: NavItem[] = [
		{ href: '/get-started', label: 'Quick Start', description: 'Deploy your first StackKit in minutes' },
		{ href: '/how-it-works', label: 'How It Works', description: 'Architecture: CUE, OpenTofu, Terramate' },
		{ href: '/cli-api', label: 'CLI & API', description: 'Command reference and API documentation' }
	];

	const kombifyTools: NavItem[] = [
		{ href: import.meta.env.VITE_PORTAL_URL || 'https://kombify.io', label: 'kombify Cloud', description: 'The guided platform for modern self-hosted infrastructure', external: true },
		{ href: import.meta.env.VITE_KOMBISTACK_URL || 'https://stack.kombify.io', label: 'kombify Stack', description: 'Hybrid cloud control plane - unify home and cloud', external: true },
		{ href: import.meta.env.VITE_KOMBISIM_URL || 'https://simulate.kombify.io', label: 'kombify Sim', description: 'Simulate and test your homelab before deployment', external: true }
	];

	const mobileNavItems: NavItem[] = [
		{ href: '/overview', label: 'Overview' },
		{ href: '/use-cases', label: 'Use Cases' },
		{ href: '/get-started', label: 'Get Started' },
		{ href: '/how-it-works', label: 'How It Works' },
		{ href: '/cli-api', label: 'CLI & API' }
	];

	let currentPath = $derived($page.url.pathname);
	let mobileMenuOpen = $state(false);

	function isActive(href: string): boolean {
		return currentPath === href || currentPath.startsWith(href + '/');
	}

	function isGroupActive(items: NavItem[]): boolean {
		return items.some(item => !item.external && isActive(item.href));
	}

	let getStartedActive = $derived(isGroupActive(getStartedItems));
</script>

<header class="sticky top-0 z-50 glass border-b border-border">
	<div class="max-w-7xl mx-auto px-4 sm:px-6 py-3">
		<div class="flex items-center justify-between gap-4">
			<!-- Logo -->
			<div class="flex items-center gap-3 flex-shrink-0">
				<a href="/" class="flex items-center gap-3 hover:opacity-80 transition-opacity">
					<img src="/kombifyKits.png" alt="kombify StackKits" class="h-9 sm:h-10" />
				</a>
			</div>

			<!-- Desktop Navigation -->
			<nav class="hidden lg:flex items-center flex-1 justify-center">
				<NavigationMenu.Root class="relative z-50">
					<NavigationMenu.List class="flex items-center gap-1">
						<!-- Overview -->
						<NavigationMenu.Item value="overview">
							<a
								href="/overview"
								class="inline-flex h-9 items-center justify-center rounded-lg px-3 py-2 text-sm font-medium transition-colors
									hover:bg-muted hover:text-accent-foreground
									{isActive('/overview') ? 'text-primary bg-primary/5' : ''}"
							>
								Overview
							</a>
						</NavigationMenu.Item>

						<!-- Use Cases -->
						<NavigationMenu.Item value="use-cases">
							<a
								href="/use-cases"
								class="inline-flex h-9 items-center justify-center rounded-lg px-3 py-2 text-sm font-medium transition-colors
									hover:bg-muted hover:text-accent-foreground
									{isActive('/use-cases') ? 'text-primary bg-primary/5' : ''}"
							>
								Use Cases
							</a>
						</NavigationMenu.Item>

						<!-- Get Started Dropdown -->
						<NavigationMenu.Item value="get-started">
							<NavigationMenu.Trigger
								class="group inline-flex h-9 items-center justify-center gap-1 rounded-lg px-3 py-2 text-sm font-medium transition-colors
									hover:bg-muted hover:text-accent-foreground
									focus-visible:bg-muted focus-visible:text-accent-foreground focus-visible:outline-none
									data-[state=open]:bg-primary/10 data-[state=open]:text-primary
									{getStartedActive ? 'text-primary bg-primary/5' : ''}"
							>
								<Rocket class="h-4 w-4 {getStartedActive ? 'text-primary' : ''}" />
								<span>Get Started</span>
								<ChevronDown
									class="h-3 w-3 transition-transform duration-200 group-data-[state=open]:rotate-180"
									aria-hidden="true"
								/>
							</NavigationMenu.Trigger>
							<NavigationMenu.Content
								class="data-[motion=from-end]:animate-in data-[motion=from-start]:animate-in data-[motion=to-end]:animate-out data-[motion=to-start]:animate-out
									data-[motion=from-end]:slide-in-from-right-52 data-[motion=from-start]:slide-in-from-left-52
									data-[motion=to-end]:slide-out-to-right-52 data-[motion=to-start]:slide-out-to-left-52
									w-max max-w-none p-5"
							>
								<div class="grid gap-2 min-w-[320px]">
									{#each getStartedItems as item}
										<NavigationMenu.Link
											href={item.href}
											class="flex items-center gap-3 rounded-lg p-3 transition-colors
												hover:bg-muted
												{isActive(item.href) ? 'bg-primary/10 text-primary' : ''}"
										>
											{#if item.label === 'Quick Start'}
												<Zap class="h-5 w-5 text-muted-foreground flex-shrink-0" />
											{:else if item.label === 'How It Works'}
												<BookOpen class="h-5 w-5 text-muted-foreground flex-shrink-0" />
											{:else}
												<Terminal class="h-5 w-5 text-muted-foreground flex-shrink-0" />
											{/if}
											<div>
												<div class="text-sm font-medium">{item.label}</div>
												{#if item.description}
													<p class="text-xs text-muted-foreground">{item.description}</p>
												{/if}
											</div>
										</NavigationMenu.Link>
									{/each}
								</div>
							</NavigationMenu.Content>
						</NavigationMenu.Item>

						<!-- kombify Tools Dropdown -->
						<NavigationMenu.Item value="tools">
							<NavigationMenu.Trigger
								class="group inline-flex h-9 items-center justify-center gap-1 rounded-lg px-3 py-2 text-sm font-medium transition-colors
									hover:bg-muted hover:text-accent-foreground
									focus-visible:bg-muted focus-visible:text-accent-foreground focus-visible:outline-none
									data-[state=open]:bg-primary/10 data-[state=open]:text-primary"
							>
								<Layers class="h-4 w-4" />
								<span>kombify Tools</span>
								<ChevronDown
									class="h-3 w-3 transition-transform duration-200 group-data-[state=open]:rotate-180"
									aria-hidden="true"
								/>
							</NavigationMenu.Trigger>
							<NavigationMenu.Content
								class="data-[motion=from-end]:animate-in data-[motion=from-start]:animate-in data-[motion=to-end]:animate-out data-[motion=to-start]:animate-out
									data-[motion=from-end]:slide-in-from-right-52 data-[motion=from-start]:slide-in-from-left-52
									data-[motion=to-end]:slide-out-to-right-52 data-[motion=to-start]:slide-out-to-left-52
									w-max max-w-none p-5"
							>
								<div class="grid grid-cols-2 gap-4 min-w-[480px]">
									<!-- StackKits (current) -->
									<div>
										<h4 class="mb-3 text-xs font-semibold uppercase tracking-wider text-muted-foreground">
											Current Product
										</h4>
										<div class="rounded-lg bg-primary/5 border border-primary/20 p-3">
											<div class="flex items-center gap-2 mb-1">
												<Server class="h-4 w-4 text-primary" />
												<span class="text-sm font-medium text-primary">StackKits</span>
											</div>
											<p class="text-xs text-muted-foreground">Curated infrastructure blueprints for homelabs and self-hosted environments</p>
										</div>
									</div>

									<!-- Other Tools -->
									<div>
										<h4 class="mb-3 text-xs font-semibold uppercase tracking-wider text-muted-foreground">
											kombify Platform
										</h4>
										<div class="space-y-1">
											{#each kombifyTools as tool}
												<a
													href={tool.href}
													target="_blank"
													rel="noopener"
													class="flex items-center gap-3 rounded-lg p-2 transition-colors hover:bg-muted"
												>
													{#if tool.label === 'kombify Cloud'}
														<Cloud class="h-4 w-4 text-muted-foreground" />
													{:else if tool.label === 'kombify Stack'}
														<Layers class="h-4 w-4 text-muted-foreground" />
													{:else if tool.label === 'kombify Sim'}
														<Eye class="h-4 w-4 text-muted-foreground" />
													{/if}
													<div class="flex-1">
														<div class="text-sm font-medium flex items-center gap-1">
															{tool.label}
															<ExternalLink class="h-3 w-3 text-muted-foreground" />
														</div>
														<p class="text-xs text-muted-foreground">{tool.description}</p>
													</div>
												</a>
											{/each}
										</div>
									</div>
								</div>

								<!-- Bottom featured -->
								<div class="mt-4 border-t border-border pt-4">
									<a
										href={import.meta.env.VITE_PORTAL_URL || 'https://kombify.io'}
										target="_blank"
										rel="noopener"
										class="flex items-center gap-3 rounded-lg bg-linear-to-r from-primary/10 to-primary/5 p-3 transition-colors hover:from-primary/20 hover:to-primary/10"
									>
										<div class="flex h-10 w-10 items-center justify-center rounded-lg bg-primary/20">
											<Globe class="h-5 w-5 text-primary" />
										</div>
										<div class="flex-1">
											<div class="text-sm font-medium">Explore kombify.io</div>
											<p class="text-xs text-muted-foreground">The guided platform for modern self-hosted infrastructure</p>
										</div>
										<ExternalLink class="h-4 w-4 text-muted-foreground" />
									</a>
								</div>
							</NavigationMenu.Content>
						</NavigationMenu.Item>

						<!-- Indicator -->
						<NavigationMenu.Indicator
							class="top-full z-10 flex h-2.5 items-end justify-center overflow-hidden transition-[width,transform_250ms_ease]
								data-[state=hidden]:animate-out data-[state=visible]:animate-in
								data-[state=hidden]:fade-out data-[state=visible]:fade-in"
						>
							<div class="relative top-[60%] h-2 w-2 rotate-45 rounded-tl-sm bg-primary/50"></div>
						</NavigationMenu.Indicator>
					</NavigationMenu.List>

					<!-- Viewport -->
					<div class="absolute left-0 top-full flex w-full justify-center perspective-[2000px]">
						<NavigationMenu.Viewport
							class="relative mt-1.5 origin-top-center overflow-visible rounded-xl border border-border bg-popover text-popover-foreground shadow-lg
								h-auto w-max max-w-none
								data-[state=closed]:animate-out data-[state=open]:animate-in
								data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95
								data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0"
						/>
					</div>
				</NavigationMenu.Root>
			</nav>

			<!-- Right Side -->
			<div class="flex items-center gap-2">
				<ThemeSwitcher />

				<button
					class="lg:hidden p-2 rounded-lg hover:bg-muted transition-colors"
					onclick={() => (mobileMenuOpen = !mobileMenuOpen)}
					aria-label="Toggle menu"
				>
					{#if mobileMenuOpen}
						<X class="h-5 w-5" />
					{:else}
						<Menu class="h-5 w-5" />
					{/if}
				</button>
			</div>
		</div>

		<!-- Mobile Navigation -->
		{#if mobileMenuOpen}
			<nav class="lg:hidden mt-4 pb-2 border-t border-border pt-4">
				<div class="grid grid-cols-2 gap-2">
					{#each mobileNavItems as item}
						<a
							href={item.href}
							onclick={() => (mobileMenuOpen = false)}
							class="px-3 py-2 text-sm rounded-lg transition-colors {isActive(item.href)
								? 'bg-primary/10 text-primary font-medium'
								: 'text-muted-foreground hover:text-foreground hover:bg-muted'}"
						>
							{item.label}
						</a>
					{/each}
				</div>
				<div class="mt-3 pt-3 border-t border-border">
					<a
						href={import.meta.env.VITE_PORTAL_URL || 'https://kombify.io'}
						target="_blank"
						rel="noopener"
						onclick={() => (mobileMenuOpen = false)}
						class="flex items-center gap-2 px-3 py-2 text-sm text-muted-foreground hover:text-foreground rounded-lg hover:bg-muted transition-colors"
					>
						<Globe class="h-4 w-4" />
						kombify Platform
						<ExternalLink class="h-3 w-3" />
					</a>
				</div>
			</nav>
		{/if}
	</div>
</header>
