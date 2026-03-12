package commands

import (
	"context"
	"crypto/rand"
	"encoding/json"
	"fmt"
	"log/slog"
	"math/big"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/kombifyio/stackkits/internal/config"
	cueval "github.com/kombifyio/stackkits/internal/cue"
	"github.com/kombifyio/stackkits/internal/kombifyme"
	"github.com/kombifyio/stackkits/internal/netenv"
	"github.com/kombifyio/stackkits/internal/template"
	"github.com/kombifyio/stackkits/pkg/models"
	"github.com/spf13/cobra"
	"golang.org/x/crypto/bcrypt"
)

var (
	genOutputDir string
	genForce     bool
)

var generateCmd = &cobra.Command{
	Use:     "generate",
	Aliases: []string{"gen"},
	Short:   "Generate OpenTofu files from stack specification",
	Long: `Generate OpenTofu configuration files from your stack specification.

This command reads your stack-spec.yaml and the associated StackKit templates
to generate ready-to-apply OpenTofu files in the output directory.

Examples:
  stackkit generate                     Generate using defaults
  stackkit generate -o ./terraform      Output to custom directory
  stackkit generate --force             Overwrite existing files`,
	RunE: runGenerate,
}

func init() {
	generateCmd.Flags().StringVarP(&genOutputDir, "output", "o", "deploy", "Output directory for generated files")
	generateCmd.Flags().BoolVarP(&genForce, "force", "f", false, "Overwrite existing files")
}

func runGenerate(cmd *cobra.Command, args []string) error {
	start := time.Now()
	wd := getWorkDir()

	// Load spec (loader.resolvePath handles absolute vs relative paths)
	loader := config.NewLoader(wd)

	spec, err := loader.LoadStackSpec(specFile)
	if err != nil {
		return fmt.Errorf("failed to load spec file: %w", err)
	}

	deployLog.Event("spec.loaded",
		slog.String("stackkit", spec.StackKit),
		slog.String("mode", spec.Mode),
		slog.String("domain", spec.Domain),
		slog.String("tier", spec.Compute.Tier),
	)

	// Apply --context flag override if provided
	if contextFlag != "" {
		spec.Context = contextFlag
	}

	// Resolve NodeContext: use stored capabilities or detect on-the-fly
	resolvedCtx := resolveNodeContextForGenerate(spec)
	if spec.Context == "" {
		spec.Context = string(resolvedCtx)
	}

	printInfo("Generating OpenTofu files for: %s", bold(spec.Name))
	printInfo("StackKit: %s, Mode: %s, Context: %s", spec.StackKit, spec.Mode, netenv.FormatNodeContext(resolvedCtx))

	// Find StackKit directory
	stackkitDir, err := loader.FindStackKitDir(spec.StackKit)
	if err != nil {
		// Try parent directories for development
		parentDir := filepath.Dir(wd)
		loader = config.NewLoader(parentDir)
		stackkitDir, err = loader.FindStackKitDir(spec.StackKit)
		if err != nil {
			return fmt.Errorf("stackkit '%s' not found: %w", spec.StackKit, err)
		}
	}

	// Load StackKit
	stackkitPath := filepath.Join(stackkitDir, "stackkit.yaml")
	stackkit, err := loader.LoadStackKit(stackkitPath)
	if err != nil {
		return fmt.Errorf("failed to load stackkit: %w", err)
	}

	// Validate CUE schemas before generating
	cueValidator := cueval.NewValidator(wd)
	if cueResult, valErr := cueValidator.ValidateStackKit(stackkitDir); valErr != nil {
		printWarning("CUE validation: %v", valErr)
		deployLog.Warn("cue.validation",
			slog.String("status", "error"),
			slog.String("error", valErr.Error()),
		)
	} else if !cueResult.Valid {
		for _, e := range cueResult.Errors {
			printWarning("CUE: %s: %s", e.Path, e.Message)
		}
		deployLog.Warn("cue.validation",
			slog.String("status", "invalid"),
			slog.Int("error_count", len(cueResult.Errors)),
		)
	} else {
		deployLog.Event("cue.validation",
			slog.String("status", "valid"),
		)
	}

	// Determine template directory: runtime overrides mode for native deployments
	templateKey := spec.Mode
	if spec.Runtime == models.RuntimeNative {
		templateKey = models.RuntimeNative
	}
	templateDir := filepath.Join(stackkitDir, "templates", templateKey)
	templateFallback := false
	if _, statErr := os.Stat(templateDir); os.IsNotExist(statErr) {
		// Fall back to simple mode
		templateFallback = true
		templateDir = filepath.Join(stackkitDir, "templates", "simple")
		if _, statErr2 := os.Stat(templateDir); os.IsNotExist(statErr2) {
			return fmt.Errorf("no templates found for mode '%s' in %s", templateKey, stackkitDir)
		}
	}
	deployLog.Event("decision.template",
		slog.String("template_key", templateKey),
		slog.Bool("fallback_to_simple", templateFallback),
		slog.String("template_dir", templateDir),
	)

	// Create output directory
	outputPath := filepath.Join(wd, genOutputDir)
	if _, statErr := os.Stat(outputPath); statErr == nil && !genForce {
		return fmt.Errorf("output directory already exists: %s (use --force to overwrite)", outputPath)
	}

	if mkdirErr := os.MkdirAll(outputPath, 0750); mkdirErr != nil {
		return fmt.Errorf("failed to create output directory: %w", mkdirErr)
	}

	// Check if templates use Go templating or are plain files
	err = copyOrRenderTemplates(templateDir, outputPath, spec, stackkit)
	if err != nil {
		return fmt.Errorf("failed to generate files: %w", err)
	}

	// Generate main.tf if not present
	mainTfPath := filepath.Join(outputPath, "main.tf")
	if _, statErr := os.Stat(mainTfPath); os.IsNotExist(statErr) {
		// Generate a basic main.tf
		renderCtx := &template.RenderContext{
			Spec:     spec,
			StackKit: stackkit,
		}
		mainTf, err := template.GenerateMainTf(renderCtx)
		if err != nil {
			return fmt.Errorf("failed to generate main.tf: %w", err)
		}
		if err := os.WriteFile(mainTfPath, []byte(mainTf), 0600); err != nil {
			return fmt.Errorf("failed to write main.tf: %w", err)
		}
		printSuccess("Generated: main.tf")
	}

	// kombify.me subdomain registration (when domain is kombify.me)
	if isKombifyMeDomain(spec.Domain) {
		if err := registerKombifyMeSubdomains(spec); err != nil {
			printWarning("kombify.me registration: %v", err)
			printInfo("Continuing with existing subdomainPrefix if set")
			deployLog.Warn("kombifyme.registration",
				slog.String("error", err.Error()),
			)
		} else {
			deployLog.Event("kombifyme.registration",
				slog.String("prefix", spec.SubdomainPrefix),
			)
		}
	}

	// Generate terraform.tfvars.json from spec (JSON format for consistency with API)
	tfvarsPath := filepath.Join(outputPath, "terraform.tfvars.json")
	tfvarsData, err := generateTfvarsJSON(spec)
	if err != nil {
		return fmt.Errorf("failed to generate tfvars: %w", err)
	}
	if err := os.WriteFile(tfvarsPath, tfvarsData, 0600); err != nil {
		return fmt.Errorf("failed to write terraform.tfvars.json: %w", err)
	}
	printSuccess("Generated: terraform.tfvars.json")
	printWarning("terraform.tfvars.json contains sensitive data (passwords, tokens). Do not commit it to version control.")

	// Print summary
	files, _ := countFiles(outputPath)
	fmt.Println()
	printSuccess("Generated %d files in: %s", files, outputPath)

	// Print next steps
	fmt.Println()
	printInfo("Next steps:")
	fmt.Printf("  1. Review generated files: %s\n", cyan("ls "+genOutputDir))
	fmt.Printf("  2. Initialize OpenTofu:    %s\n", cyan("cd "+genOutputDir+" && tofu init"))
	fmt.Printf("  3. Or use StackKit:        %s\n", cyan("stackkit plan"))

	deployLog.Event("generate.complete",
		slog.Int("file_count", files),
		slog.Int64("elapsed_ms", time.Since(start).Milliseconds()),
	)

	return nil
}

// copyOrRenderTemplates renders template files using the template.Renderer,
// falling back to plain copy for non-template files.
func copyOrRenderTemplates(srcDir, dstDir string, spec *models.StackSpec, stackkit *models.StackKit) error {
	renderer := template.NewRenderer(srcDir, dstDir)
	renderCtx := &template.RenderContext{
		Spec:     spec,
		StackKit: stackkit,
	}
	return renderer.Render(renderCtx)
}

// generateRandomPassword generates a cryptographically random alphanumeric password.
func generateRandomPassword(length int) (string, error) {
	const charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	b := make([]byte, length)
	for i := range b {
		n, err := rand.Int(rand.Reader, big.NewInt(int64(len(charset))))
		if err != nil {
			return "", fmt.Errorf("generate random password: %w", err)
		}
		b[i] = charset[n.Int64()]
	}
	return string(b), nil
}

// bcryptHash returns a bcrypt hash of the given password.
func bcryptHash(password string) (string, error) {
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return "", fmt.Errorf("bcrypt hash: %w", err)
	}
	return string(hash), nil
}

// generateTfvarsJSON generates terraform.tfvars.json matching the template variables.
// Service enablement is driven by compute tier (v4 architecture):
//   - L1/L2 core (traefik, tinyauth, pocketid) = ALWAYS enabled
//   - L2 PAAS = tier-dependent (Dokploy for standard/high, Dockge for low)
//   - Monitoring = tier-dependent
//
// Per-service overrides can be applied via spec.Services[name]["enabled"].
func generateTfvarsJSON(spec *models.StackSpec) ([]byte, error) { //nolint:gocyclo
	vars := make(map[string]interface{})

	// Domain
	domain := models.DomainHomelab
	if spec.Domain != "" {
		domain = spec.Domain
	}
	vars["domain"] = domain

	// Subdomain prefix (kombify.me flat naming mode)
	if spec.SubdomainPrefix != "" {
		vars["subdomain_prefix"] = spec.SubdomainPrefix
	}

	// Network environment: check capabilities written by `stackkit prepare`
	// or detect on-the-fly if prepare wasn't run
	caps := loadDockerCapabilities()
	resolvedCtx := resolveNodeContextFromCaps(caps, spec)

	// Smart domain resolution: use NodeContext instead of raw NetworkEnvironment
	if suggested, reason := netenv.SuggestDomainForContext(resolvedCtx, domain); reason != "" {
		printWarning("Domain mismatch: %s", reason)
		if domain != suggested {
			printInfo("Auto-correcting domain: %s -> %s", domain, suggested)
			domain = suggested
			vars["domain"] = domain
			// For kombify.me, ensure SubdomainPrefix will be set during registration
			if isKombifyMeDomain(domain) && spec.Domain != models.DomainKombifyMe {
				spec.Domain = models.DomainKombifyMe
			}
		}
	}

	// Access mode detection
	isLocalMode := domain == "" || domain == models.DomainHomelab || domain == models.DomainHomeLab || domain == "stack.local" ||
		strings.HasSuffix(domain, ".local") || strings.HasSuffix(domain, ".lan") ||
		strings.HasSuffix(domain, ".home") || strings.HasSuffix(domain, ".internal") ||
		strings.HasSuffix(domain, ".test") || strings.HasSuffix(domain, ".lab")
	isKombifyMe := isKombifyMeDomain(domain)

	// Local mode: deploy dnsmasq for *.home.lab resolution
	// Two-level domain required by TinyAuth (rejects single-level TLDs)
	if isLocalMode {
		domain = models.DomainHomeLab
		vars["domain"] = domain
		vars["enable_dnsmasq"] = true
		if len(spec.Nodes) > 0 && spec.Nodes[0].IP != "" {
			vars["server_lan_ip"] = spec.Nodes[0].IP
		}
		printInfo("Local mode: services at *.home.lab (dnsmasq DNS)")
	}

	deployLog.Event("decision.domain_mode",
		slog.String("input_domain", spec.Domain),
		slog.Bool("is_local_mode", isLocalMode),
		slog.Bool("is_kombify_me", isKombifyMe),
		slog.String("final_domain", domain),
		slog.Bool("enable_dnsmasq", isLocalMode),
	)

	// TLS/HTTPS — enabled only for real public domains
	enableHTTPS := !isLocalMode && !isKombifyMe
	vars["enable_https"] = enableHTTPS

	if enableHTTPS {
		// ACME email
		acmeEmail := spec.AdminEmail
		if acmeEmail == "" || acmeEmail == "admin" {
			acmeEmail = "admin@" + domain
		}
		vars["acme_email"] = acmeEmail

		// Challenge type and DNS provider
		challenge := spec.TLS.Challenge
		if challenge == "" {
			if spec.TLS.Provider != "" {
				challenge = "dns" // DNS provider specified → use DNS-01
			} else {
				challenge = "tls" // Default to TLS-ALPN-01
			}
		}
		vars["acme_challenge"] = challenge

		if spec.TLS.Provider != "" {
			vars["dns_provider"] = spec.TLS.Provider
		}

		// DNS API credentials from environment
		dnsToken := os.Getenv("STACKKIT_DNS_TOKEN")
		if dnsToken != "" {
			vars["dns_api_token"] = dnsToken
		}
		dnsEmail := os.Getenv("STACKKIT_DNS_EMAIL")
		if dnsEmail != "" {
			vars["dns_api_email"] = dnsEmail
		}

		printInfo("HTTPS enabled (ACME %s challenge, email: %s)", challenge, acmeEmail)
		deployLog.Event("decision.tls",
			slog.Bool("enable_https", true),
			slog.String("challenge", challenge),
			slog.String("acme_email", acmeEmail),
		)
	} else {
		deployLog.Event("decision.tls",
			slog.Bool("enable_https", false),
			slog.String("reason_local", fmt.Sprintf("%v", isLocalMode)),
			slog.String("reason_kombifyme", fmt.Sprintf("%v", isKombifyMe)),
		)
	}

	// Network
	vars["network_name"] = "base_net"
	if spec.Network.Subnet != "" {
		vars["network_subnet"] = spec.Network.Subnet
	} else {
		vars["network_subnet"] = "172.20.0.0/16"
	}

	// Compute tier drives service selection (v4 architecture)
	tier := spec.Compute.Tier
	if tier == "" {
		tier = models.ComputeTierStandard
	}

	// Resolve PAAS and reverse proxy backend (ADR-0006: Service URL Matrix)
	paas := spec.ResolvePAAS()
	reverseProxy := spec.ResolveReverseProxy()
	vars["paas"] = paas
	vars["reverse_proxy_backend"] = reverseProxy

	// L1/L2 core — ALWAYS enabled (non-negotiable)
	// When using Dokploy/Coolify's Traefik, we skip deploying a standalone Traefik
	vars["enable_traefik"] = reverseProxy == models.ReverseProxyStandalone
	vars["enable_tinyauth"] = true
	vars["enable_pocketid"] = true

	// L2 PAAS — driven by explicit paas field or tier
	switch paas {
	case models.PAASDockge:
		vars["enable_dokploy"] = false
		vars["enable_dokploy_apps"] = false
		vars["enable_dockge"] = true
		vars["enable_coolify"] = false
	case models.PAASCoolify:
		vars["enable_dokploy"] = false
		vars["enable_dokploy_apps"] = false
		vars["enable_dockge"] = false
		vars["enable_coolify"] = true
	default: // dokploy (standard/high default)
		vars["enable_dokploy"] = true
		vars["enable_dokploy_apps"] = true
		vars["enable_dockge"] = false
		vars["enable_coolify"] = false
	}

	// Dashboard — always (lightweight)
	vars["enable_dashboard"] = true

	// Uptime Kuma — always enabled (lightweight test/validation service)
	vars["enable_uptime_kuma"] = true

	// L3 Application use cases — tier-gated
	vars["enable_vaultwarden"] = true // all tiers (lightweight, ~128MB RAM)
	isStandardPlus := tier == models.ComputeTierStandard || tier == models.ComputeTierHigh
	vars["enable_jellyfin"] = isStandardPlus
	vars["enable_immich"] = isStandardPlus

	// Jellyfin media directory (host bind mount for user media files)
	vars["media_path"] = "/opt/media"

	deployLog.Event("decision.compute_tier",
		slog.String("tier", tier),
		slog.String("paas", paas),
		slog.String("reverse_proxy_backend", reverseProxy),
		slog.Bool("enable_dokploy", vars["enable_dokploy"].(bool)),
		slog.Bool("enable_dockge", vars["enable_dockge"].(bool)),
	)

	printInfo("Compute tier: %s, PAAS: %s, Reverse proxy: %s", tier, paas, reverseProxy)

	// Admin email (fallback to "admin" for backwards compatibility)
	adminEmail := spec.AdminEmail
	if adminEmail == "" {
		adminEmail = "admin"
	}
	vars["admin_email"] = adminEmail

	// Generate random password and bcrypt hash for TinyAuth
	adminPassword, err := generateRandomPassword(16)
	if err != nil {
		return nil, fmt.Errorf("failed to generate admin password (crypto/rand): %w", err)
	}
	vars["admin_password_plaintext"] = adminPassword

	hash, err := bcryptHash(adminPassword)
	if err != nil {
		return nil, fmt.Errorf("failed to hash admin password (bcrypt): %w", err)
	}

	// TinyAuth configuration
	proto := "http"
	if enableHTTPS {
		proto = "https"
	}
	if spec.SubdomainPrefix != "" {
		vars["tinyauth_app_url"] = fmt.Sprintf("%s://%s-tinyauth.%s", proto, spec.SubdomainPrefix, domain)
	} else {
		vars["tinyauth_app_url"] = fmt.Sprintf("%s://auth.%s", proto, domain)
	}
	vars["tinyauth_users"] = fmt.Sprintf("%s:%s", adminEmail, hash)

	// Dashboard
	vars["brand_color"] = "#F97316"
	if spec.Name != "" {
		vars["dashboard_title"] = spec.Name
	} else {
		vars["dashboard_title"] = "My Homelab"
	}

	// Docker capabilities — detect network mode and dashboard hints
	vars["network_mode"] = "bridge"
	vars["dns_fixed"] = false
	vars["dns_fix_method"] = ""
	vars["storage_driver_degraded"] = false
	vars["storage_driver"] = models.StorageOverlay2
	if caps := loadDockerCapabilities(); caps != nil {
		if !caps.BridgeNetworking {
			vars["network_mode"] = "host"
			printInfo("Host networking mode (bridge unavailable on this system)")
		}
		if caps.DNSFix != "" && caps.DNSFix != models.DNSFixNone {
			vars["dns_fixed"] = true
			vars["dns_fix_method"] = caps.DNSFix
			printInfo("DNS fix applied: %s", caps.DNSFix)
		}
		if caps.StorageDriver != "" && caps.StorageDriver != models.StorageOverlay2 {
			vars["storage_driver_degraded"] = true
			vars["storage_driver"] = caps.StorageDriver
			printInfo("Degraded storage driver: %s", caps.StorageDriver)
		}
		deployLog.Event("decision.docker_caps",
			slog.String("network_mode", vars["network_mode"].(string)),
			slog.Bool("dns_fix", vars["dns_fixed"].(bool)),
			slog.String("storage_driver", vars["storage_driver"].(string)),
		)
	}

	// Allow spec-level service overrides
	if spec.Services != nil {
		for name, cfg := range spec.Services {
			if cfgMap, ok := cfg.(map[string]interface{}); ok {
				if enabled, exists := cfgMap["enabled"]; exists {
					vars["enable_"+name] = enabled
				}
			}
		}
	}

	data, err := json.MarshalIndent(vars, "", "  ")
	if err != nil {
		return nil, fmt.Errorf("failed to marshal tfvars: %w", err)
	}
	return append(data, '\n'), nil
}

// countFiles counts files in a directory
// loadDockerCapabilities reads the capabilities file written by `stackkit prepare`.
func loadDockerCapabilities() *models.DockerCapabilities {
	home, err := os.UserHomeDir()
	if err != nil {
		return nil
	}
	data, err := os.ReadFile(filepath.Join(home, ".stackkits", "capabilities.json"))
	if err != nil {
		return nil
	}
	var caps models.DockerCapabilities
	if err := json.Unmarshal(data, &caps); err != nil {
		return nil
	}
	return &caps
}

func countFiles(dir string) (int, error) {
	count := 0
	err := filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() {
			count++
		}
		return nil
	})
	return count, err
}

// resolveNodeContextForGenerate resolves the NodeContext for the generate command.
// Uses stored capabilities from prepare, or detects on-the-fly.
func resolveNodeContextForGenerate(spec *models.StackSpec) models.NodeContext {
	// If --context flag was provided, use it directly
	if spec.Context != "" {
		return models.NodeContext(spec.Context)
	}

	caps := loadDockerCapabilities()
	return resolveNodeContextFromCaps(caps, spec)
}

// resolveNodeContextFromCaps resolves NodeContext from DockerCapabilities.
// If capabilities aren't available, detects on-the-fly.
func resolveNodeContextFromCaps(caps *models.DockerCapabilities, spec *models.StackSpec) models.NodeContext {
	// If --context flag was set on spec, honor it
	if spec.Context != "" {
		return models.NodeContext(spec.Context)
	}

	// Use stored resolved context from prepare
	if caps != nil && caps.ResolvedContext != "" {
		return caps.ResolvedContext
	}

	// Detect on-the-fly if prepare wasn't run
	detected := netenv.Detect(context.Background())

	// Update caps with detection results for downstream use
	if caps == nil {
		caps = &models.DockerCapabilities{}
	}
	caps.NetworkEnv = detected.Environment
	caps.PublicIP = detected.PublicIP
	caps.PrivateIP = detected.PrivateIP
	caps.IsNAT = detected.IsNAT
	caps.HasPublicInterface = detected.HasPublicInterface

	resolved := netenv.ResolveFromResult(detected, caps.CPUCores, caps.MemoryGB)
	caps.ResolvedContext = resolved
	return resolved
}

// isKombifyMeDomain returns true if the domain is kombify.me (the subdomain service).
func isKombifyMeDomain(domain string) bool {
	return strings.EqualFold(domain, models.DomainKombifyMe)
}

// registerKombifyMeSubdomains registers base + service subdomains on the kombify.me API
// and sets spec.SubdomainPrefix if not already set.
func registerKombifyMeSubdomains(spec *models.StackSpec) error {
	apiKey := os.Getenv("KOMBIFY_API_KEY")
	if apiKey == "" {
		return fmt.Errorf("KOMBIFY_API_KEY environment variable is required for kombify.me domain")
	}

	homelabName := spec.Name
	if homelabName == "" {
		return fmt.Errorf("spec name is required for kombify.me registration")
	}

	// Device fingerprint: use existing prefix suffix or generate one
	fingerprint := ""
	if spec.SubdomainPrefix != "" {
		// Extract fingerprint from existing prefix: "sh-name-FINGERPRINT"
		parts := strings.SplitN(spec.SubdomainPrefix, "-", 3)
		if len(parts) >= 3 {
			fingerprint = parts[2]
		}
	}
	if fingerprint == "" {
		fingerprint = kombifyme.DeviceFingerprint()
	}

	tier := spec.Compute.Tier
	if tier == "" {
		tier = models.ComputeTierStandard
	}

	printInfo("Registering subdomains on kombify.me...")

	result, err := kombifyme.RegisterAll(apiKey, homelabName, fingerprint, tier)
	if err != nil {
		return err
	}

	// Update spec with the registered prefix
	spec.SubdomainPrefix = result.Prefix

	printSuccess("Registered base subdomain: %s.kombify.me", result.Prefix)
	for _, svc := range result.Services {
		printSuccess("  Service: %s.kombify.me (exposed)", svc.Name)
	}

	return nil
}
