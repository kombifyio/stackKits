package cue

import (
	"fmt"
	"strings"

	"cuelang.org/go/cue"
	"cuelang.org/go/cue/cuecontext"
	"cuelang.org/go/cue/load"
)

// ServiceDef represents an extracted service definition from CUE.
type ServiceDef struct {
	Name          string
	DisplayName   string
	Category      string
	Type          string
	Required      bool
	Enabled       bool
	Image         string
	Tag           string
	Description   string
	Needs         []string
	RestartPolicy string
	Ports         []PortDef
	Volumes       []VolumeDef
	Environment   map[string]string
	Labels        map[string]string
	HealthCheck   *HealthCheckDef
	Resources     *ResourceDef
	TraefikRule   string
	TraefikPort   int
	OutputURL     string
	OutputDesc    string
}

// PortDef represents a port mapping.
type PortDef struct {
	Host      int
	Container int
	Protocol  string
}

// VolumeDef represents a volume mount.
type VolumeDef struct {
	Source   string
	Target  string
	Type    string // "bind" or "volume"
	ReadOnly bool
}

// HealthCheckDef represents a health check.
type HealthCheckDef struct {
	Path        string
	Port        int
	Scheme      string
	Interval    string
	Timeout     string
	Retries     int
	StartPeriod string
}

// ResourceDef represents resource limits.
type ResourceDef struct {
	Memory    string
	MemoryMax string
	CPUs      float64
}

// Extractor reads CUE service definitions and returns Go structs.
type Extractor struct {
	ctx         *cue.Context
	stackkitDir string
}

// NewExtractor creates a new CUE service extractor.
func NewExtractor(stackkitDir string) *Extractor {
	return &Extractor{
		ctx:         cuecontext.New(),
		stackkitDir: stackkitDir,
	}
}

// ExtractServices loads CUE definitions and extracts the service collection
// matching the given variant.
func (e *Extractor) ExtractServices(variant string) ([]ServiceDef, error) {
	cfg := &load.Config{
		Dir: e.stackkitDir,
	}

	instances := load.Instances([]string{"."}, cfg)
	if len(instances) == 0 {
		return nil, fmt.Errorf("no CUE files found in %s", e.stackkitDir)
	}

	inst := instances[0]
	if inst.Err != nil {
		return nil, fmt.Errorf("failed to load CUE instance: %w", inst.Err)
	}

	value := e.ctx.BuildInstance(inst)
	if err := value.Err(); err != nil {
		return nil, fmt.Errorf("failed to build CUE value: %w", err)
	}

	// Map variant name to CUE service collection identifier
	collectionName := variantToCollection(variant)

	// Look up the service collection
	collection := value.LookupPath(cue.ParsePath(collectionName))
	if !collection.Exists() {
		return nil, fmt.Errorf("service collection %q not found in CUE (variant: %s)", collectionName, variant)
	}

	return e.extractFromCollection(collection)
}

// variantToCollection maps a variant name to the CUE service collection.
func variantToCollection(variant string) string {
	switch variant {
	case "default", "":
		return "#DefaultServices"
	case "beszel":
		return "#DefaultServicesWithBeszel"
	case "secure":
		return "#SecureServices"
	case "minimal":
		return "#MinimalServices"
	default:
		return "#DefaultServices"
	}
}

// extractFromCollection iterates over the fields in a service collection
// and extracts each service definition.
func (e *Extractor) extractFromCollection(collection cue.Value) ([]ServiceDef, error) {
	var services []ServiceDef

	iter, err := collection.Fields(cue.Optional(true))
	if err != nil {
		return nil, fmt.Errorf("failed to iterate service collection: %w", err)
	}

	for iter.Next() {
		svc, err := e.extractService(iter.Value())
		if err != nil {
			return nil, fmt.Errorf("failed to extract service %s: %w", iter.Selector().String(), err)
		}
		services = append(services, svc)
	}

	return services, nil
}

// extractService extracts a single service definition from a CUE value.
func (e *Extractor) extractService(v cue.Value) (ServiceDef, error) {
	svc := ServiceDef{
		Enabled:       true,
		RestartPolicy: "unless-stopped",
		Environment:   make(map[string]string),
		Labels:        make(map[string]string),
	}

	// Basic fields
	svc.Name = stringField(v, "name")
	svc.DisplayName = stringField(v, "displayName")
	svc.Category = stringField(v, "category")
	svc.Type = stringField(v, "type")
	svc.Image = stringField(v, "image")
	svc.Tag = stringField(v, "tag")
	svc.Description = stringField(v, "description")
	svc.RestartPolicy = stringFieldOr(v, "restartPolicy", "unless-stopped")

	if req := v.LookupPath(cue.ParsePath("required")); req.Exists() {
		b, _ := req.Bool()
		svc.Required = b
	}
	if en := v.LookupPath(cue.ParsePath("enabled")); en.Exists() {
		b, _ := en.Bool()
		svc.Enabled = b
	}

	// Needs (dependencies)
	if needs := v.LookupPath(cue.ParsePath("needs")); needs.Exists() {
		iter, _ := needs.List()
		for iter.Next() {
			s, _ := iter.Value().String()
			svc.Needs = append(svc.Needs, s)
		}
	}

	// Network: ports
	if ports := v.LookupPath(cue.ParsePath("network.ports")); ports.Exists() {
		iter, _ := ports.List()
		for iter.Next() {
			p := iter.Value()
			pd := PortDef{
				Protocol: stringFieldOr(p, "protocol", "tcp"),
			}
			if h := p.LookupPath(cue.ParsePath("host")); h.Exists() {
				n, _ := h.Int64()
				pd.Host = int(n)
			}
			if c := p.LookupPath(cue.ParsePath("container")); c.Exists() {
				n, _ := c.Int64()
				pd.Container = int(n)
			}
			svc.Ports = append(svc.Ports, pd)
		}
	}

	// Network: traefik
	if traefik := v.LookupPath(cue.ParsePath("network.traefik")); traefik.Exists() {
		svc.TraefikRule = stringField(traefik, "rule")
		if port := traefik.LookupPath(cue.ParsePath("port")); port.Exists() {
			n, _ := port.Int64()
			svc.TraefikPort = int(n)
		}
	}

	// Volumes
	if vols := v.LookupPath(cue.ParsePath("volumes")); vols.Exists() {
		iter, _ := vols.List()
		for iter.Next() {
			vol := iter.Value()
			vd := VolumeDef{
				Source: stringField(vol, "source"),
				Target: stringField(vol, "target"),
				Type:   stringFieldOr(vol, "type", "volume"),
			}
			if ro := vol.LookupPath(cue.ParsePath("readOnly")); ro.Exists() {
				b, _ := ro.Bool()
				vd.ReadOnly = b
			}
			svc.Volumes = append(svc.Volumes, vd)
		}
	}

	// Environment
	if env := v.LookupPath(cue.ParsePath("environment")); env.Exists() {
		iter, _ := env.Fields()
		for iter.Next() {
			k := iter.Selector().String()
			// Remove quotes from CUE field selectors
			k = strings.Trim(k, "\"")
			s, _ := iter.Value().String()
			svc.Environment[k] = s
		}
	}

	// Labels
	if labels := v.LookupPath(cue.ParsePath("labels")); labels.Exists() {
		iter, _ := labels.Fields()
		for iter.Next() {
			k := iter.Selector().String()
			k = strings.Trim(k, "\"")
			s, _ := iter.Value().String()
			svc.Labels[k] = s
		}
	}

	// Health check
	if hc := v.LookupPath(cue.ParsePath("healthCheck")); hc.Exists() {
		if en := hc.LookupPath(cue.ParsePath("enabled")); en.Exists() {
			b, _ := en.Bool()
			if b {
				hcd := &HealthCheckDef{
					Path:        stringField(hc, "http.path"),
					Scheme:      stringFieldOr(hc, "http.scheme", "http"),
					Interval:    stringFieldOr(hc, "interval", "30s"),
					Timeout:     stringFieldOr(hc, "timeout", "5s"),
					StartPeriod: stringFieldOr(hc, "startPeriod", "10s"),
				}
				if port := hc.LookupPath(cue.ParsePath("http.port")); port.Exists() {
					n, _ := port.Int64()
					hcd.Port = int(n)
				}
				if retries := hc.LookupPath(cue.ParsePath("retries")); retries.Exists() {
					n, _ := retries.Int64()
					hcd.Retries = int(n)
				}
				svc.HealthCheck = hcd
			}
		}
	}

	// Resources
	if res := v.LookupPath(cue.ParsePath("resources")); res.Exists() {
		rd := &ResourceDef{
			Memory:    stringField(res, "memory"),
			MemoryMax: stringField(res, "memoryMax"),
		}
		if cpus := res.LookupPath(cue.ParsePath("cpus")); cpus.Exists() {
			f, _ := cpus.Float64()
			rd.CPUs = f
		}
		svc.Resources = rd
	}

	// Output
	if out := v.LookupPath(cue.ParsePath("output")); out.Exists() {
		svc.OutputURL = stringField(out, "url")
		svc.OutputDesc = stringField(out, "description")
	}

	return svc, nil
}

// stringField extracts a string from a CUE value path, returning "" on error.
func stringField(v cue.Value, path string) string {
	f := v.LookupPath(cue.ParsePath(path))
	if !f.Exists() {
		return ""
	}
	s, _ := f.String()
	return s
}

// stringFieldOr extracts a string with a default fallback.
func stringFieldOr(v cue.Value, path, def string) string {
	s := stringField(v, path)
	if s == "" {
		return def
	}
	return s
}
