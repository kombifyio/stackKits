package devhomelab

// Dev Homelab Stackfile
// Complete stack definition for development testing

import "github.com/kombihq/stackkits/base"

// Stack definition
#Stack: base.#StackKit & {
    metadata: {
        name:        "dev-homelab"
        version:     "1.0.0"
        description: "Minimal development StackKit for testing"
        category:    "development"
    }
    
    infrastructure: {
        mode:     #Defaults.mode
        provider: #Defaults.provider
    }
    
    network: #Defaults.network
    
    services: {
        whoami: #Services.whoami & {
            enabled: true
        }
    }
    
    testing: #Defaults.testing
}

// Export the stack
stack: #Stack
