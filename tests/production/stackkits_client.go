//go:build production

package production

import (
	"fmt"
	"net/http"
)

// StackKit represents a StackKit definition from the API.
type StackKit struct {
	ID          string                 `json:"id"`
	Name        string                 `json:"name"`
	Description string                 `json:"description,omitempty"`
	Version     string                 `json:"version,omitempty"`
	Layers      []string               `json:"layers,omitempty"`
	Services    map[string]interface{} `json:"services,omitempty"`
}

// ValidationResult from validating a stack spec.
type ValidationResult struct {
	Valid    bool     `json:"valid"`
	Errors   []string `json:"errors,omitempty"`
	Warnings []string `json:"warnings,omitempty"`
}

// StackKitsHealthResponse from the StackKits API health endpoint.
type StackKitsHealthResponse struct {
	Status  string `json:"status"`
	Version string `json:"version,omitempty"`
}

// StackKitsClient provides typed access to the StackKits API through Kong gateway.
type StackKitsClient struct {
	client *Client
}

// NewStackKitsClient creates a StackKits API client.
func NewStackKitsClient(c *Client) *StackKitsClient {
	return &StackKitsClient{client: c}
}

// Health checks the StackKits API health endpoint.
func (s *StackKitsClient) Health() (*StackKitsHealthResponse, error) {
	var result StackKitsHealthResponse
	resp, err := s.client.Get("/v1/stackkits/health", &result)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("health check failed: status %d", resp.StatusCode)
	}
	return &result, nil
}

// ListStackKits returns all available StackKits.
func (s *StackKitsClient) ListStackKits() ([]StackKit, error) {
	var result []StackKit
	resp, err := s.client.Get("/v1/stackkits/stackkits", &result)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("list stackkits failed: status %d", resp.StatusCode)
	}
	return result, nil
}

// GetStackKit returns a specific StackKit by ID.
func (s *StackKitsClient) GetStackKit(id string) (*StackKit, error) {
	var result StackKit
	path := fmt.Sprintf("/v1/stackkits/stackkits/%s", id)
	resp, err := s.client.Get(path, &result)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("get stackkit failed: status %d", resp.StatusCode)
	}
	return &result, nil
}

// ValidateSpecRequest is the body for validating a stack spec.
type ValidateSpecRequest struct {
	Spec map[string]interface{} `json:"spec"`
}

// ValidateSpec validates a stack specification against CUE schemas.
func (s *StackKitsClient) ValidateSpec(spec map[string]interface{}) (*ValidationResult, error) {
	var result ValidationResult
	resp, err := s.client.Post("/v1/stackkits/validate", ValidateSpecRequest{Spec: spec}, &result)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("validate spec failed: status %d", resp.StatusCode)
	}
	return &result, nil
}
