//go:build production

package production

import (
	"fmt"
	"strings"
	"testing"
	"time"
)

// TestGatewayHealth verifies Kong gateway is routing to both APIs correctly.
func TestGatewayHealth(t *testing.T) {
	cfg, err := LoadConfig()
	if err != nil {
		t.Fatalf("load config: %v", err)
	}

	client := NewClient(cfg)

	t.Run("SimAPI", func(t *testing.T) {
		sim := NewSimClient(client)
		health, err := sim.Health()
		if err != nil {
			t.Fatalf("sim health check failed: %v", err)
		}
		if health.Status != "ok" && health.Status != "healthy" {
			t.Errorf("unexpected sim health status: %s", health.Status)
		}
		t.Logf("Sim API healthy: %s", health.Status)
	})

	t.Run("StackKitsAPI", func(t *testing.T) {
		sk := NewStackKitsClient(client)
		health, err := sk.Health()
		if err != nil {
			t.Fatalf("stackkits health check failed: %v", err)
		}
		if health.Status != "ok" && health.Status != "healthy" {
			t.Errorf("unexpected stackkits health status: %s", health.Status)
		}
		t.Logf("StackKits API healthy: %s", health.Status)
	})
}

// TestSimulationLifecycle tests the full simulation workflow through the gateway.
func TestSimulationLifecycle(t *testing.T) {
	cfg, err := LoadConfig()
	if err != nil {
		t.Fatalf("load config: %v", err)
	}

	client := NewClient(cfg)
	sim := NewSimClient(client)

	// Generate unique name for this test run
	testName := fmt.Sprintf("prodtest-%d", time.Now().Unix())

	// Create simulation
	t.Log("Creating simulation...")
	simulation, err := sim.CreateSimulation(testName)
	if err != nil {
		t.Fatalf("create simulation: %v", err)
	}
	t.Logf("Created simulation: %s (%s)", simulation.Name, simulation.ID)

	// Always clean up
	defer func() {
		t.Log("Cleaning up simulation...")
		if err := sim.DeleteSimulation(simulation.ID); err != nil {
			t.Errorf("cleanup failed: %v", err)
		}
	}()

	// Verify simulation appears in list
	t.Log("Listing simulations...")
	sims, err := sim.ListSimulations()
	if err != nil {
		t.Fatalf("list simulations: %v", err)
	}

	found := false
	for _, s := range sims {
		if s.ID == simulation.ID {
			found = true
			break
		}
	}
	if !found {
		t.Errorf("created simulation not found in list")
	}
	t.Logf("Found %d simulations, test simulation present", len(sims))
}

// TestNodeLifecycle tests node creation and lifecycle through the gateway.
func TestNodeLifecycle(t *testing.T) {
	if testing.Short() {
		t.Skip("skipping node lifecycle test in short mode")
	}

	cfg, err := LoadConfig()
	if err != nil {
		t.Fatalf("load config: %v", err)
	}

	client := NewClient(cfg)
	sim := NewSimClient(client)

	// Create simulation for nodes
	testName := fmt.Sprintf("nodetest-%d", time.Now().Unix())
	simulation, err := sim.CreateSimulation(testName)
	if err != nil {
		t.Fatalf("create simulation: %v", err)
	}
	t.Logf("Created simulation: %s", simulation.ID)

	// Always clean up
	defer func() {
		t.Log("Cleaning up...")
		if err := sim.DeleteSimulation(simulation.ID); err != nil {
			t.Logf("cleanup simulation warning: %v", err)
		}
	}()

	// Create node
	t.Log("Creating node...")
	node, err := sim.CreateNode(simulation.ID, CreateNodeRequest{
		Name: "test-node",
	})
	if err != nil {
		t.Fatalf("create node: %v", err)
	}
	t.Logf("Created node: %s (status: %s)", node.ID, node.Status)

	// Cleanup node on test completion
	defer func() {
		if err := sim.DeleteNode(node.ID); err != nil {
			t.Logf("cleanup node warning: %v", err)
		}
	}()

	// Start node
	t.Log("Starting node...")
	node, err = sim.StartNode(node.ID)
	if err != nil {
		t.Fatalf("start node: %v", err)
	}
	t.Logf("Node started: %s (status: %s)", node.ID, node.Status)

	// Wait for node to be running (poll with timeout)
	t.Log("Waiting for node to be running...")
	timeout := time.After(5 * time.Minute)
	ticker := time.NewTicker(10 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-timeout:
			t.Fatalf("timeout waiting for node to start")
		case <-ticker.C:
			node, err = sim.GetNode(node.ID)
			if err != nil {
				t.Logf("get node: %v (retrying)", err)
				continue
			}
			t.Logf("Node status: %s", node.Status)
			if strings.ToLower(node.Status) == "running" {
				goto NodeRunning
			}
		}
	}

NodeRunning:
	t.Logf("Node is running! SSH: %s@%s:%d", node.SSHUser, node.SSHIP, node.SSHPort)

	// Stop node
	t.Log("Stopping node...")
	node, err = sim.StopNode(node.ID)
	if err != nil {
		t.Errorf("stop node: %v", err)
	} else {
		t.Logf("Node stopped: %s", node.Status)
	}
}

// TestStackKitsList verifies the StackKits catalog is accessible.
func TestStackKitsList(t *testing.T) {
	cfg, err := LoadConfig()
	if err != nil {
		t.Fatalf("load config: %v", err)
	}

	client := NewClient(cfg)
	sk := NewStackKitsClient(client)

	stackkits, err := sk.ListStackKits()
	if err != nil {
		t.Fatalf("list stackkits: %v", err)
	}

	t.Logf("Found %d StackKits in catalog", len(stackkits))

	// Log first few for visibility
	for i, kit := range stackkits {
		if i >= 5 {
			t.Logf("  ... and %d more", len(stackkits)-5)
			break
		}
		t.Logf("  - %s: %s", kit.ID, kit.Name)
	}
}
