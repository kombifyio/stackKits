// Package kombifyme provides an HTTP client for the kombify.me subdomain registration API.
package kombifyme

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

const (
	defaultBaseURL = "https://kombify.me/_kombify/api"
	apiKeyHeader   = "X-Kombify-API-Key"
)

// Client is an HTTP client for the kombify.me subdomain API.
type Client struct {
	baseURL    string
	apiKey     string
	httpClient *http.Client
}

// NewClient creates a new kombify.me API client.
func NewClient(apiKey string) *Client {
	return &Client{
		baseURL: defaultBaseURL,
		apiKey:  apiKey,
		httpClient: &http.Client{
			Timeout: 15 * time.Second,
		},
	}
}

// Subdomain represents a subdomain returned by the API.
type Subdomain struct {
	ID            string `json:"id"`
	Name          string `json:"name"`
	FQDN          string `json:"fqdn"`
	SubdomainKind string `json:"subdomain_kind"`
	ParentID      string `json:"parent_id"`
	Exposed       bool   `json:"exposed"`
}

// AutoRegister registers a base subdomain using the naming convention.
func (c *Client) AutoRegister(homelabName, deviceFingerprint, description string) (*Subdomain, error) {
	body := map[string]string{
		"homelab_name":       homelabName,
		"kind":               "self-hosted",
		"device_fingerprint": deviceFingerprint,
		"description":        description,
	}
	var sub Subdomain
	if err := c.post("/auto-register", body, &sub); err != nil {
		return nil, fmt.Errorf("auto-register base subdomain: %w", err)
	}
	return &sub, nil
}

// RegisterService registers a service subdomain under a base subdomain.
func (c *Client) RegisterService(baseSubdomainName, serviceName, localAddr, description string) (*Subdomain, error) {
	body := map[string]string{
		"base_subdomain_name": baseSubdomainName,
		"service_name":        serviceName,
		"local_addr":          localAddr,
		"description":         description,
	}
	var sub Subdomain
	if err := c.post("/auto-register/service", body, &sub); err != nil {
		return nil, fmt.Errorf("register service %s: %w", serviceName, err)
	}
	return &sub, nil
}

// ExposeService toggles a service subdomain's public exposure.
func (c *Client) ExposeService(baseID, serviceID string, exposed bool) error {
	body := map[string]bool{"exposed": exposed}
	path := fmt.Sprintf("/subdomains/%s/services/%s/expose", baseID, serviceID)
	return c.put(path, body)
}

// ListServices lists all service subdomains under a base subdomain.
func (c *Client) ListServices(baseID string) ([]Subdomain, error) {
	path := fmt.Sprintf("/subdomains/%s/services", baseID)
	var subs []Subdomain
	if err := c.get(path, &subs); err != nil {
		return nil, fmt.Errorf("list services: %w", err)
	}
	return subs, nil
}

// maxResponseSize limits API response bodies to 1 MB to prevent OOM from malicious servers.
const maxResponseSize = 1 << 20

func (c *Client) post(path string, body interface{}, result interface{}) error {
	data, err := json.Marshal(body)
	if err != nil {
		return err
	}
	req, err := http.NewRequest("POST", c.baseURL+path, bytes.NewReader(data))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set(apiKeyHeader, c.apiKey)

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	respBody, _ := io.ReadAll(io.LimitReader(resp.Body, maxResponseSize))

	if resp.StatusCode >= 400 {
		return fmt.Errorf("API error %d: %s", resp.StatusCode, string(respBody))
	}

	if result != nil {
		return json.Unmarshal(respBody, result)
	}
	return nil
}

func (c *Client) put(path string, body interface{}) error {
	data, err := json.Marshal(body)
	if err != nil {
		return err
	}
	req, err := http.NewRequest("PUT", c.baseURL+path, bytes.NewReader(data))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set(apiKeyHeader, c.apiKey)

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 400 {
		respBody, _ := io.ReadAll(io.LimitReader(resp.Body, maxResponseSize))
		return fmt.Errorf("API error %d: %s", resp.StatusCode, string(respBody))
	}
	return nil
}

func (c *Client) delete(path string) error {
	req, err := http.NewRequest("DELETE", c.baseURL+path, nil)
	if err != nil {
		return err
	}
	req.Header.Set(apiKeyHeader, c.apiKey)

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 400 {
		respBody, _ := io.ReadAll(io.LimitReader(resp.Body, maxResponseSize))
		return fmt.Errorf("API error %d: %s", resp.StatusCode, string(respBody))
	}
	return nil
}

func (c *Client) get(path string, result interface{}) error {
	req, err := http.NewRequest("GET", c.baseURL+path, nil)
	if err != nil {
		return err
	}
	req.Header.Set(apiKeyHeader, c.apiKey)

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	respBody, _ := io.ReadAll(io.LimitReader(resp.Body, maxResponseSize))

	if resp.StatusCode >= 400 {
		return fmt.Errorf("API error %d: %s", resp.StatusCode, string(respBody))
	}

	if result != nil {
		return json.Unmarshal(respBody, result)
	}
	return nil
}
