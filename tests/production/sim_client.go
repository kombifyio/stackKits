//go:build production

package production

import (
	"fmt"
	"net/http"
	"time"
)

// Simulation represents a simulation returned by the Sim API.
type Simulation struct {
	ID        string    `json:"id"`
	Name      string    `json:"name"`
	Status    string    `json:"status"`
	CreatedAt time.Time `json:"created_at"`
}

// Node represents a VM node in a simulation.
type Node struct {
	ID         string `json:"id"`
	Name       string `json:"name"`
	Status     string `json:"status"`
	SSHIP      string `json:"ssh_ip,omitempty"`
	SSHPort    int    `json:"ssh_port,omitempty"`
	SSHUser    string `json:"ssh_user,omitempty"`
	SSHKeyPath string `json:"ssh_key_path,omitempty"`
}

// HealthResponse from the Sim API health endpoint.
type HealthResponse struct {
	Status  string `json:"status"`
	Version string `json:"version,omitempty"`
}

// SimClient provides typed access to the Sim API through Kong gateway.
type SimClient struct {
	client *Client
}

// NewSimClient creates a Sim API client using the given production client.
func NewSimClient(c *Client) *SimClient {
	return &SimClient{client: c}
}

// Health checks the Sim API health endpoint.
func (s *SimClient) Health() (*HealthResponse, error) {
	var result HealthResponse
	resp, err := s.client.Get("/v1/simulation/health", &result)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("health check failed: status %d", resp.StatusCode)
	}
	return &result, nil
}

// ListSimulations returns all simulations for the authenticated user.
func (s *SimClient) ListSimulations() ([]Simulation, error) {
	var result []Simulation
	resp, err := s.client.Get("/v1/simulation/simulations", &result)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("list simulations failed: status %d", resp.StatusCode)
	}
	return result, nil
}

// CreateSimulationRequest is the body for creating a simulation.
type CreateSimulationRequest struct {
	Name string `json:"name"`
}

// CreateSimulation creates a new simulation.
func (s *SimClient) CreateSimulation(name string) (*Simulation, error) {
	var result Simulation
	resp, err := s.client.Post("/v1/simulation/simulations", CreateSimulationRequest{Name: name}, &result)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusCreated && resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("create simulation failed: status %d", resp.StatusCode)
	}
	return &result, nil
}

// DeleteSimulation deletes a simulation by ID.
func (s *SimClient) DeleteSimulation(simID string) error {
	resp, err := s.client.Delete("/v1/simulation/simulations/" + simID)
	if err != nil {
		return err
	}
	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusNoContent {
		return fmt.Errorf("delete simulation failed: status %d", resp.StatusCode)
	}
	return nil
}

// CreateNodeRequest is the body for creating a node.
type CreateNodeRequest struct {
	Name     string            `json:"name"`
	Template string            `json:"template,omitempty"`
	Config   map[string]string `json:"config,omitempty"`
}

// CreateNode creates a new node in a simulation.
func (s *SimClient) CreateNode(simID string, req CreateNodeRequest) (*Node, error) {
	var result Node
	path := fmt.Sprintf("/v1/simulation/simulations/%s/nodes", simID)
	resp, err := s.client.Post(path, req, &result)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusCreated && resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("create node failed: status %d", resp.StatusCode)
	}
	return &result, nil
}

// StartNode starts a node.
func (s *SimClient) StartNode(nodeID string) (*Node, error) {
	var result Node
	path := fmt.Sprintf("/v1/simulation/nodes/%s/start", nodeID)
	resp, err := s.client.Post(path, nil, &result)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("start node failed: status %d", resp.StatusCode)
	}
	return &result, nil
}

// StopNode stops a node.
func (s *SimClient) StopNode(nodeID string) (*Node, error) {
	var result Node
	path := fmt.Sprintf("/v1/simulation/nodes/%s/stop", nodeID)
	resp, err := s.client.Post(path, nil, &result)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("stop node failed: status %d", resp.StatusCode)
	}
	return &result, nil
}

// DeleteNode deletes a node.
func (s *SimClient) DeleteNode(nodeID string) error {
	path := fmt.Sprintf("/v1/simulation/nodes/%s", nodeID)
	resp, err := s.client.Delete(path)
	if err != nil {
		return err
	}
	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusNoContent {
		return fmt.Errorf("delete node failed: status %d", resp.StatusCode)
	}
	return nil
}

// GetNode gets a node by ID.
func (s *SimClient) GetNode(nodeID string) (*Node, error) {
	var result Node
	path := fmt.Sprintf("/v1/simulation/nodes/%s", nodeID)
	resp, err := s.client.Get(path, &result)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("get node failed: status %d", resp.StatusCode)
	}
	return &result, nil
}
