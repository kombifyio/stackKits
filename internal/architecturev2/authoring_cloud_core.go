package architecturev2

import "fmt"

// Initial authoring materializes the selected CUE core's endpoints using the
// kit's declared public access policy. Persisted candidate specs bypass this
// authoring path and retain their existing routes and module identities.
func projectCloudInitialCoreRoutes(spec map[string]any, core useCaseWorkloadSelection) error {
	routes, ok := spec["routes"].(map[string]any)
	if !ok || len(core.CoreServiceRefs) == 0 {
		return fmt.Errorf("selected Cloud core has no initial endpoint contract")
	}
	template, ok := routes["cloud-hub-public"].(map[string]any)
	if !ok {
		return fmt.Errorf("Cloud initial spec has no public route policy template")
	}
	declared := map[string]bool{}
	for _, service := range core.CoreServiceRefs {
		declared[service] = true
	}
	present := map[string]bool{}
	for id, raw := range routes {
		route, ok := raw.(map[string]any)
		if !ok {
			return fmt.Errorf("Cloud initial route is not an object")
		}
		module, _ := route["moduleRef"].(string)
		if module != "stackkits-cloud-core-runtime" && module != "stackkits-cloud-core-standalone-runtime" {
			continue
		}
		service, _ := route["serviceRef"].(string)
		if !declared[service] {
			delete(routes, id)
			continue
		}
		route["moduleRef"] = core.ModuleRef
		present[service] = true
	}
	for _, service := range core.CoreServiceRefs {
		if present[service] {
			continue
		}
		route := map[string]any{}
		for key, value := range template {
			route[key] = value
		}
		route["serviceRef"], route["moduleRef"] = service, core.ModuleRef
		routes["cloud-"+service+"-public"] = route
	}
	network, _ := spec["network"].(map[string]any)
	domain, _ := network["domain"].(map[string]any)
	base, _ := domain["base"].(string)
	return projectCloudInitialPublicRouteHosts(spec, base)
}
