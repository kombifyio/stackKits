//go:build production

// Package production provides test utilities for production API testing
// through the Kong API Gateway.
package production

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"time"
)

// Config holds production test configuration loaded from env vars.
type Config struct {
	// APIURL is the base URL for Kong gateway (default: https://api.kombify.io)
	APIURL string

	// APIKey is the X-Api-Key for authentication (mutually exclusive with JWT)
	APIKey string

	// JWTToken is the Bearer token for JWT authentication
	JWTToken string
}

// LoadConfig loads production test configuration from environment variables.
// Required: KOMBIFY_API_KEY or KOMBIFY_JWT_TOKEN
// Optional: KOMBIFY_API_URL (defaults to https://api.kombify.io)
func LoadConfig() (*Config, error) {
	cfg := &Config{
		APIURL:   os.Getenv("KOMBIFY_API_URL"),
		APIKey:   os.Getenv("KOMBIFY_API_KEY"),
		JWTToken: os.Getenv("KOMBIFY_JWT_TOKEN"),
	}

	if cfg.APIURL == "" {
		cfg.APIURL = "https://api.kombify.io"
	}

	if cfg.APIKey == "" && cfg.JWTToken == "" {
		return nil, fmt.Errorf("either KOMBIFY_API_KEY or KOMBIFY_JWT_TOKEN must be set")
	}

	return cfg, nil
}

// Client wraps http.Client with automatic auth header injection.
type Client struct {
	http   *http.Client
	config *Config
}

// NewClient creates a new production test client with auth configured.
func NewClient(cfg *Config) *Client {
	return &Client{
		http: &http.Client{
			Timeout: 30 * time.Second,
		},
		config: cfg,
	}
}

// Request creates a new HTTP request with auth headers set.
func (c *Client) Request(method, path string, body any) (*http.Request, error) {
	url := c.config.APIURL + path

	var bodyReader io.Reader
	if body != nil {
		bodyBytes, err := json.Marshal(body)
		if err != nil {
			return nil, fmt.Errorf("marshal body: %w", err)
		}
		bodyReader = bytes.NewReader(bodyBytes)
	}

	req, err := http.NewRequest(method, url, bodyReader)
	if err != nil {
		return nil, err
	}

	// Set content type for JSON
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}

	// Set auth header
	if c.config.APIKey != "" {
		req.Header.Set("X-Api-Key", c.config.APIKey)
	} else if c.config.JWTToken != "" {
		req.Header.Set("Authorization", "Bearer "+c.config.JWTToken)
	}

	return req, nil
}

// Do executes an HTTP request and decodes the JSON response.
func (c *Client) Do(req *http.Request, result any) (*http.Response, error) {
	resp, err := c.http.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if result != nil {
		if err := json.NewDecoder(resp.Body).Decode(result); err != nil {
			return resp, fmt.Errorf("decode response: %w", err)
		}
	}

	return resp, nil
}

// Get performs a GET request and decodes JSON response.
func (c *Client) Get(path string, result any) (*http.Response, error) {
	req, err := c.Request(http.MethodGet, path, nil)
	if err != nil {
		return nil, err
	}
	return c.Do(req, result)
}

// Post performs a POST request with JSON body and decodes JSON response.
func (c *Client) Post(path string, body, result any) (*http.Response, error) {
	req, err := c.Request(http.MethodPost, path, body)
	if err != nil {
		return nil, err
	}
	return c.Do(req, result)
}

// Delete performs a DELETE request.
func (c *Client) Delete(path string) (*http.Response, error) {
	req, err := c.Request(http.MethodDelete, path, nil)
	if err != nil {
		return nil, err
	}
	return c.Do(req, nil)
}
