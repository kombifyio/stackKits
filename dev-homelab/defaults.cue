package devhomelab

// Dev Homelab Defaults
// Minimal defaults for development and testing

#Defaults: {
    // Infrastructure
    mode:     "simple"
    provider: "docker"
    
    // Network
    network: {
        name:       "dev_net"
        subnet:     "172.21.0.0/16"
        accessMode: "ports"
    }
    
    // Minimal services
    services: {
        whoami: {
            enabled:     true
            image:       "traefik/whoami:latest"
            port:        9080
            healthCheck: "/"
        }
    }
    
    // Testing
    testing: {
        enabled:        true
        validateHealth: true
        timeout:        "5m"
    }
}
