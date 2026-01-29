package devhomelab

// Dev Homelab Service Definitions
// Minimal service for e2e testing

import "github.com/kombihq/stackkits/base"

// Single test service
#WhoamiService: base.#Service & {
    name:        "whoami"
    image:       "traefik/whoami:latest"
    description: "Simple HTTP service for deployment testing"
    role:        "test-endpoint"
    
    ports: [{
        container: 80
        host:      9080
        protocol:  "tcp"
    }]
    
    healthCheck: {
        endpoint: "/"
        interval: "30s"
        timeout:  "5s"
        retries:  3
    }
    
    resources: {
        memory: "64m"
        cpu:    0.1
    }
}

// Service registry for dev-homelab
#Services: {
    whoami: #WhoamiService
}
