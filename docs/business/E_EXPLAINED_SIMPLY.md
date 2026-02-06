# StackKits – Explained Simply

> **For Non-Technical Readers**  
> **Understanding StackKits without the jargon**

---

## The Building Analogy

When constructing a house, you have two approaches:

**Without a blueprint:** You buy materials and start building. When something doesn't fit, you tear it down and try again. This process repeats until the structure stands – hopefully correctly.

**With an architect's blueprint:** You receive a validated plan where measurements, structural requirements, and electrical codes have been verified. Construction follows the plan, and the result matches expectations.

StackKits provides blueprints for server infrastructure. Instead of assembling configurations through trial and error, you start with a validated plan.

---

## What is a Homelab?

A homelab is a personal server setup – either a computer at home or a rented server – that hosts your own services:

- Personal photo storage (instead of Google Photos)
- File synchronization (instead of Dropbox)
- Media streaming (your own content library)
- Smart home coordination
- Local AI assistants

People choose this approach for several reasons:
- **Privacy** – Your data stays under your control
- **Cost** – No ongoing subscription fees
- **Learning** – Understanding how internet services work
- **Customization** – Exactly the features you want

---

## The Problem StackKits Solves

Setting up a homelab typically involves:

1. Writing configuration files
2. Attempting to start services
3. Encountering errors
4. Searching online for solutions
5. Modifying configurations
6. Repeating steps 2-5 until it works

This cycle consumes hours or days because **errors are only discovered after you try to run something**. Configuration files have no built-in checking.

StackKits changes this by checking your configuration before anything runs. Errors are identified with specific explanations and suggested fixes – before you waste time on a broken setup.

---

## How It Works

### The Three Components

**CUE (Validation)**

Think of CUE as a spell-checker for configuration files. Just as a word processor highlights misspelled words before you print, CUE identifies configuration errors before deployment.

For example, if you specify an invalid port number, CUE reports:
- What's wrong: "Port number out of valid range"
- What you provided: "70000"
- What's expected: "A number between 1 and 65535"

**OpenTofu (Building)**

Once your configuration passes validation, OpenTofu creates the infrastructure. It reads the validated blueprint and sets up servers, networks, and services accordingly.

**Terramate (Management)**

For ongoing maintenance, Terramate tracks what should exist versus what actually exists. If someone manually changes something, Terramate identifies the discrepancy.

---

## The 3-Layer Structure

StackKits organizes infrastructure like a layer cake:

**Layer 1: Foundation**

The base layer that everything else depends on. This includes:
- Server security settings
- Network configuration
- Basic identity services

Think of this as the foundation and walls of a house – essential, rarely changed.

**Layer 2: Platform**

The middle layer providing common services:
- The system that runs applications (containers)
- Web traffic management
- An interface for deploying your applications

Think of this as plumbing and electrical – supporting infrastructure for what you actually use.

**Layer 3: Applications**

Your actual services:
- Photo management
- File storage
- Media servers
- Whatever you want to run

Think of this as furniture and appliances – the things you interact with daily.

The layered structure means you can change Layer 3 (your applications) without affecting Layers 1 and 2.

---

## What StackKits Includes

### base-homelab

A single-server setup providing:

- Automatic security configuration
- Web traffic handling with encryption
- A visual interface for managing applications
- Monitoring to ensure services are running

This is sufficient for most personal use cases.

### Future Additions

- **modern-homelab** – Multiple servers working together
- **ha-homelab** – Redundant setup where services continue if one server fails

---

## Common Questions

**Do I need programming skills?**

No. You edit simple configuration files (similar to filling out a form) and run a few commands. The validation system guides you through any issues.

**What equipment do I need?**

Minimum requirements:
- A computer with 4GB RAM and 50GB storage, OR
- A rented server (available from hosting providers)
- An internet connection

An old laptop or desktop often works fine.

**Is it free?**

Yes. StackKits is open-source software available at no cost. You only pay for any hardware or server rentals you choose to use.

**What if something goes wrong?**

The validation system prevents most problems by checking configurations before deployment. For other issues, documentation and community support are available.

**How does this compare to using a cloud service?**

| Aspect | Cloud Service | Self-Hosted with StackKits |
|--------|---------------|----------------------------|
| Monthly cost | Subscription fees | Hardware/hosting only |
| Storage limits | Plan-based | Your hardware capacity |
| Privacy | Provider has access | You control access |
| Customization | Limited | Full control |
| Setup effort | Minimal | One-time setup required |

---

## Getting Started

1. **Review the documentation** – Understand what's involved
2. **Prepare a server** – Physical machine or rented server
3. **Follow the setup guide** – Step-by-step instructions
4. **Validate and deploy** – Let StackKits check and create your infrastructure

The initial setup takes a few hours. Afterward, the system largely maintains itself with occasional updates.

---

## Summary

StackKits provides tested, validated blueprints for setting up your own servers. Instead of piecing together configurations from various sources and hoping they work, you start with a known-good setup that checks for errors before deployment.

The result: reliable infrastructure for hosting your own services, without requiring expertise in server administration.

---

*StackKits: Infrastructure blueprints that work the first time.*
