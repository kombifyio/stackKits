package cue

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func testGraph() *ModuleGraph {
	contracts := []ModuleContract{
		{
			Metadata: ModuleMetadata{Name: "socket-proxy", Layer: "l1-foundation", Version: "0.1.0"},
			Services: map[string]ServiceDef{
				"socket-proxy": {
					Image: "tecnativa/docker-socket-proxy",
					Tag:   "latest",
					Ports: []PortDef{{Container: 2375}},
					Environment: map[string]string{
						"CONTAINERS": "1",
						"NETWORKS":   "1",
					},
				},
			},
			Enabled: true,
		},
		{
			Metadata: ModuleMetadata{Name: "traefik", Layer: "l2-platform", Version: "3.0.0"},
			Requires: &RequiresSpec{
				Services: map[string]RequiredService{
					"socket-proxy": {Optional: false},
				},
			},
			Services: map[string]ServiceDef{
				"traefik": {
					Image:       "traefik",
					Tag:         "v3.3",
					Ports:       []PortDef{{Container: 80, Host: 80}, {Container: 443, Host: 443}},
					TraefikPort: 8080,
					TraefikRule: "Host(`traefik.{{.domain}}`)",
					Volumes: []VolumeDef{
						{Source: "traefik_certs", Target: "/certs", Type: "volume"},
					},
					Environment: map[string]string{
						"TRAEFIK_API_DASHBOARD": "true",
					},
					Labels: map[string]string{
						"com.centurylinklabs.watchtower.enable": "true",
					},
					RestartPolicy: "always",
					HealthCheck: &HealthCheckDef{
						Path:     "/ping",
						Port:     8080,
						Interval: "10s",
						Timeout:  "3s",
						Retries:  3,
					},
					Resources: &ResourceDef{
						Memory:    "256m",
						MemoryMax: "512m",
					},
				},
			},
			Enabled: true,
		},
		{
			Metadata: ModuleMetadata{Name: "whoami", Layer: "l3-application", Version: "1.0.0"},
			Requires: &RequiresSpec{
				Services: map[string]RequiredService{
					"traefik": {Optional: false},
				},
			},
			Services: map[string]ServiceDef{
				"whoami": {
					Image:       "traefik/whoami",
					Tag:         "latest",
					TraefikPort: 80,
					Environment: map[string]string{
						"WHOAMI_NAME": "whoami.{{.domain}}",
					},
				},
			},
			Enabled: true,
		},
	}

	resolver := NewResolver()
	graph, err := resolver.Resolve(contracts)
	if err != nil {
		panic("testGraph: " + err.Error())
	}
	return graph
}

func TestGenerateAllCreatesFiles(t *testing.T) {
	dir := t.TempDir()
	gen := NewGenerator("test.local")

	graph := testGraph()
	if err := gen.GenerateAll(graph, dir); err != nil {
		t.Fatalf("GenerateAll() error = %v", err)
	}

	// Check shared files exist
	for _, f := range []string{"providers.tf", "networks.tf", "variables.tf", "terraform.tfvars.json"} {
		path := filepath.Join(dir, f)
		if _, err := os.Stat(path); os.IsNotExist(err) {
			t.Errorf("expected %s to exist", f)
		}
	}

	// Check per-module files
	for _, name := range []string{"socket-proxy", "traefik", "whoami"} {
		path := filepath.Join(dir, "modules", name+".tf")
		if _, err := os.Stat(path); os.IsNotExist(err) {
			t.Errorf("expected modules/%s.tf to exist", name)
		}
	}
}

func TestProvidersTF(t *testing.T) {
	dir := t.TempDir()
	gen := NewGenerator("test.local")

	if err := gen.writeProviders(dir); err != nil {
		t.Fatalf("writeProviders() error = %v", err)
	}

	data, _ := os.ReadFile(filepath.Join(dir, "providers.tf"))
	content := string(data)

	if !strings.Contains(content, "kreuzwerker/docker") {
		t.Error("providers.tf should reference kreuzwerker/docker")
	}
	if !strings.Contains(content, "var.docker_host") {
		t.Error("providers.tf should use var.docker_host")
	}
}

func TestNetworksTF(t *testing.T) {
	dir := t.TempDir()
	gen := NewGenerator("test.local")
	graph := testGraph()

	if err := gen.writeNetworks(graph, dir); err != nil {
		t.Fatalf("writeNetworks() error = %v", err)
	}

	data, _ := os.ReadFile(filepath.Join(dir, "networks.tf"))
	content := string(data)

	if !strings.Contains(content, `docker_network`) {
		t.Error("networks.tf should contain docker_network resources")
	}
	if !strings.Contains(content, `"frontend"`) {
		t.Error("networks.tf should include frontend network")
	}
}

func TestVariablesTF(t *testing.T) {
	dir := t.TempDir()
	gen := NewGenerator("test.local")
	graph := testGraph()

	if err := gen.writeVariables(graph, dir); err != nil {
		t.Fatalf("writeVariables() error = %v", err)
	}

	data, _ := os.ReadFile(filepath.Join(dir, "variables.tf"))
	content := string(data)

	// Global variables
	if !strings.Contains(content, `variable "domain"`) {
		t.Error("variables.tf should declare domain variable")
	}
	if !strings.Contains(content, `variable "docker_host"`) {
		t.Error("variables.tf should declare docker_host variable")
	}

	// Per-module enable flags
	for _, name := range []string{"socket_proxy", "traefik", "whoami"} {
		expected := `variable "enable_` + name + `"`
		if !strings.Contains(content, expected) {
			t.Errorf("variables.tf should declare %s", expected)
		}
	}
}

func TestTFVarsJSON(t *testing.T) {
	dir := t.TempDir()
	gen := NewGenerator("mystack.example.com")
	graph := testGraph()

	if err := gen.writeTFVarsJSON(graph, dir); err != nil {
		t.Fatalf("writeTFVarsJSON() error = %v", err)
	}

	data, _ := os.ReadFile(filepath.Join(dir, "terraform.tfvars.json"))
	var vars map[string]any
	if err := json.Unmarshal(data, &vars); err != nil {
		t.Fatalf("failed to parse tfvars JSON: %v", err)
	}

	if vars["domain"] != "mystack.example.com" {
		t.Errorf("domain = %v, want mystack.example.com", vars["domain"])
	}

	// All modules should have enable flags
	for _, name := range []string{"enable_socket_proxy", "enable_traefik", "enable_whoami"} {
		v, ok := vars[name]
		if !ok {
			t.Errorf("tfvars should have %s", name)
			continue
		}
		if v != true {
			t.Errorf("%s = %v, want true", name, v)
		}
	}
}

func TestModuleTFContent(t *testing.T) {
	dir := t.TempDir()
	modulesDir := filepath.Join(dir, "modules")
	os.MkdirAll(modulesDir, 0750)

	gen := NewGenerator("test.local")
	graph := testGraph()

	// Generate traefik module
	mc := graph.Modules["traefik"]
	if err := gen.writeModuleTF(mc, graph, modulesDir); err != nil {
		t.Fatalf("writeModuleTF() error = %v", err)
	}

	data, _ := os.ReadFile(filepath.Join(modulesDir, "traefik.tf"))
	content := string(data)

	// docker_image resource
	if !strings.Contains(content, `resource "docker_image" "traefik"`) {
		t.Error("should contain docker_image resource for traefik")
	}

	// docker_container resource
	if !strings.Contains(content, `resource "docker_container" "traefik"`) {
		t.Error("should contain docker_container resource for traefik")
	}

	// Enable flag
	if !strings.Contains(content, `var.enable_traefik`) {
		t.Error("should reference enable_traefik variable")
	}

	// Image reference
	if !strings.Contains(content, `traefik:v3.3`) {
		t.Error("should contain image reference traefik:v3.3")
	}

	// Ports
	if !strings.Contains(content, "internal = 80") {
		t.Error("should have port 80 mapping")
	}
	if !strings.Contains(content, "external = 443") {
		t.Error("should have port 443 mapping")
	}

	// Volumes
	if !strings.Contains(content, "container_path") {
		t.Error("should have volume mount")
	}

	// Environment with domain templating
	if !strings.Contains(content, "${var.domain}") {
		t.Error("should template domain references")
	}

	// Health check
	if !strings.Contains(content, "healthcheck") {
		t.Error("should have healthcheck block")
	}

	// Resource limits
	if !strings.Contains(content, "memory = 256") {
		t.Error("should have memory limit of 256 MB")
	}

	// Restart policy
	if !strings.Contains(content, `restart = "always"`) {
		t.Error("should have restart policy 'always'")
	}

	// Network
	if !strings.Contains(content, "networks_advanced") {
		t.Error("should have networks_advanced block")
	}

	// Dependencies
	if !strings.Contains(content, "depends_on") {
		t.Error("should have depends_on for socket-proxy")
	}
}

func TestDomainTemplating(t *testing.T) {
	dir := t.TempDir()
	modulesDir := filepath.Join(dir, "modules")
	os.MkdirAll(modulesDir, 0750)

	gen := NewGenerator("test.local")
	graph := testGraph()

	mc := graph.Modules["whoami"]
	if err := gen.writeModuleTF(mc, graph, modulesDir); err != nil {
		t.Fatalf("writeModuleTF() error = %v", err)
	}

	data, _ := os.ReadFile(filepath.Join(modulesDir, "whoami.tf"))
	content := string(data)

	// Should NOT contain the raw template marker
	if strings.Contains(content, "{{.domain}}") {
		t.Error("should not contain raw {{.domain}} template marker")
	}

	// Should contain OpenTofu variable interpolation
	if !strings.Contains(content, "${var.domain}") {
		t.Error("should contain ${var.domain} OpenTofu interpolation")
	}
}

func TestBuildLabels(t *testing.T) {
	gen := NewGenerator("test.local")

	svc := ServiceDef{
		TraefikRule: "Host(`traefik.{{.domain}}`)",
		TraefikPort: 8080,
		Labels: map[string]string{
			"custom": "value",
		},
	}
	mc := ModuleContract{
		Metadata: ModuleMetadata{Name: "traefik"},
	}

	labels := gen.buildLabels("traefik", svc, mc)

	if labels["traefik.enable"] != "true" {
		t.Error("should set traefik.enable=true")
	}

	if !strings.Contains(labels["traefik.http.routers.traefik.rule"], "${var.domain}") {
		t.Error("traefik rule should template domain")
	}

	if labels["traefik.http.services.traefik.loadbalancer.server.port"] != "8080" {
		t.Error("should set loadbalancer port to 8080")
	}

	if labels["custom"] != "value" {
		t.Error("should preserve custom labels")
	}
}

func TestParseMemoryMB(t *testing.T) {
	tests := []struct {
		input string
		want  int
	}{
		{"128m", 128},
		{"256M", 256},
		{"1g", 1024},
		{"2G", 2048},
		{"512", 512},
	}

	for _, tt := range tests {
		got := parseMemoryMB(tt.input)
		if got != tt.want {
			t.Errorf("parseMemoryMB(%q) = %d, want %d", tt.input, got, tt.want)
		}
	}
}

func TestModuleVarName(t *testing.T) {
	tests := []struct {
		input, want string
	}{
		{"traefik", "traefik"},
		{"socket-proxy", "socket_proxy"},
		{"adguard-home", "adguard_home"},
		{"uptime-kuma", "uptime_kuma"},
	}

	for _, tt := range tests {
		got := moduleVarName(tt.input)
		if got != tt.want {
			t.Errorf("moduleVarName(%q) = %q, want %q", tt.input, got, tt.want)
		}
	}
}

func TestEmptyDomainFallback(t *testing.T) {
	dir := t.TempDir()
	gen := NewGenerator("")
	graph := testGraph()

	if err := gen.writeTFVarsJSON(graph, dir); err != nil {
		t.Fatalf("writeTFVarsJSON() error = %v", err)
	}

	data, _ := os.ReadFile(filepath.Join(dir, "terraform.tfvars.json"))
	var vars map[string]any
	json.Unmarshal(data, &vars)

	if vars["domain"] != "stack.local" {
		t.Errorf("empty domain should default to stack.local, got %v", vars["domain"])
	}
}
