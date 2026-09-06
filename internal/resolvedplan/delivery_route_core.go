package resolvedplan

import "fmt"

// Bind the selected core workload on the route's actual nodes. Site kind and
// ambient Docker networks are not authority for choosing a routing owner.
func bindDeliveryRouteCore(route map[string]any, workloads []any) error {
	nodes, err := stringListField(route, "deliveryRoute", "originNodeRefs", true)
	if err != nil {
		return err
	}
	sites, err := stringListField(route, "deliveryRoute", "originSiteRefs", true)
	if err != nil {
		return err
	}
	owner := ""
	for i, raw := range workloads {
		p := fmt.Sprintf("workloads[%d]", i)
		workload, err := asObject(raw, p)
		if err != nil {
			return err
		}
		id, _ := workload["id"].(string)
		if id != "basement-core" && id != "cloud-core" {
			continue
		}
		alternative, err := objectField(workload, p, "alternative")
		if err != nil {
			return err
		}
		module, err := stringField(alternative, p+".alternative", "moduleRef")
		if err != nil {
			return err
		}
		coreNodes, err := stringListField(workload, p, "nodeRefs", true)
		if err != nil {
			return err
		}
		coreSites, err := stringListField(workload, p, "siteRefs", true)
		if err != nil {
			return err
		}
		covers := len(nodes) > 0 && len(sites) > 0
		for _, node := range nodes {
			covers = covers && contains(coreNodes, node)
		}
		for _, site := range sites {
			covers = covers && contains(coreSites, site)
		}
		if !covers {
			continue
		}
		if owner != "" {
			return fmt.Errorf("delivery route has multiple selected core owners")
		}
		owner = module
	}
	if owner != "" {
		route["coreModuleRef"] = owner
	}
	return nil
}
