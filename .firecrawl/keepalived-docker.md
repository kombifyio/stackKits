[Skip to main content](https://oneuptime.com/blog/post/2026-02-08-how-to-run-keepalived-in-docker-for-virtual-ip-failover/view#main-content)

[OneUptime![OneUptime logo](https://oneuptime.com/img/3-transparent.svg)](https://oneuptime.com/)

Open menu

Products

### Essentials

[Monitoring\\
\\
Uptime & synthetic checks](https://oneuptime.com/product/monitoring) [Status Page\\
\\
Communicate incidents to users](https://oneuptime.com/product/status-page) [Incidents\\
\\
Detect, manage & resolve](https://oneuptime.com/product/incident-management) [On-Call & Alerts\\
\\
Smart routing & escalations](https://oneuptime.com/product/on-call)

### Observability

[Logs\\
\\
Fastest log ingest & search](https://oneuptime.com/product/logs-management) [Metrics\\
\\
Application & infra metrics](https://oneuptime.com/product/metrics) [Traces\\
\\
Distributed request tracing](https://oneuptime.com/product/traces) [Exceptions\\
\\
Error tracking & debugging](https://oneuptime.com/product/exceptions)

### Automation & Analytics

[Workflows\\
\\
No-code automation builder](https://oneuptime.com/product/workflows) [Dashboards\\
\\
Custom data visualizations](https://oneuptime.com/product/dashboards)

[AI Agent\\
\\
Auto-fix issues with AI-powered PRs. Let AI analyze incidents and automatically create pull requests to resolve them.](https://oneuptime.com/product/ai-agent)

### Resources

[Documentation](https://oneuptime.com/docs) [API Reference](https://oneuptime.com/reference) [GitHub](https://github.com/oneuptime/oneuptime) [Blog & Guides](https://oneuptime.com/blog)

### Get Started

[Start Free Trial](https://oneuptime.com/accounts/register) [Request Demo](https://oneuptime.com/enterprise/demo)

[sales@oneuptime.com](mailto:sales@oneuptime.com)

Open Source — Self-host or use our cloud. Your data, your choice.


[View Pricing](https://oneuptime.com/pricing) [Enterprise](https://oneuptime.com/enterprise/overview)

Enterprise

Enterprise

## Built for how you work

Scale your reliability operations with enterprise-grade tools.

[Enterprise Overview\\
\\
Scale with confidence](https://oneuptime.com/enterprise/overview) [Request Demo\\
\\
See it in action](https://oneuptime.com/enterprise/demo)

[Contact Sales](https://oneuptime.com/legal/contact)

Enterprise

[Enterprise Overview\\
\\
Solutions for large organizations](https://oneuptime.com/enterprise/overview) [Request Demo\\
\\
Schedule a personalized demo](https://oneuptime.com/enterprise/demo)

Teams

[DevOps](https://oneuptime.com/solutions/devops) [SRE](https://oneuptime.com/solutions/sre) [Platform](https://oneuptime.com/solutions/platform) [Developers](https://oneuptime.com/solutions/developers)

Industries

[FinTech](https://oneuptime.com/industries/fintech) [SaaS](https://oneuptime.com/industries/saas) [Healthcare](https://oneuptime.com/industries/healthcare) [E-Commerce](https://oneuptime.com/industries/ecommerce) [Media](https://oneuptime.com/industries/media) [Government](https://oneuptime.com/industries/government)

[Documentation](https://oneuptime.com/docs) [Pricing](https://oneuptime.com/pricing) [Blog](https://oneuptime.com/blog)

[Get Started Free](https://oneuptime.com/accounts/register)

[Pricing](https://oneuptime.com/pricing)

Resources

Resources

## Learn & Connect

Everything you need to get started and succeed.

[Documentation\\
\\
Guides & tutorials](https://oneuptime.com/docs) [API Reference\\
\\
REST API & SDKs](https://oneuptime.com/reference)

[Star on GitHub](https://github.com/oneuptime/oneuptime)

Learn

[Blog\\
\\
News & insights](https://oneuptime.com/blog) [Status\\
\\
System status](https://status.oneuptime.com/) [Changelog\\
\\
What's new](https://github.com/OneUptime/oneuptime/releases) [Videos\\
\\
Watch & learn](https://www.youtube.com/@OneUptimehq)

Support

[Help Center](https://oneuptime.com/support) [Contact Us](mailto:support@oneuptime.com)

Company

[About Us](https://oneuptime.com/about) [Merch Store](https://shop.oneuptime.com/)

[Legal](https://oneuptime.com/legal) [Privacy](https://oneuptime.com/legal/privacy) [Terms](https://oneuptime.com/legal/terms)

100% Open Source

[Sign\\
in](https://oneuptime.com/accounts) [Sign up](https://oneuptime.com/accounts/register)

![OneUptime](https://oneuptime.com/img/3-transparent.svg)

Close menu

[Status Page](https://oneuptime.com/product/status-page) [Incidents](https://oneuptime.com/product/incident-management) [Monitoring](https://oneuptime.com/product/monitoring) [On-Call](https://oneuptime.com/product/on-call) [Logs](https://oneuptime.com/product/logs-management) [Metrics](https://oneuptime.com/product/metrics) [Traces](https://oneuptime.com/product/traces) [Exceptions](https://oneuptime.com/product/exceptions) [Workflows](https://oneuptime.com/product/workflows) [Dashboards](https://oneuptime.com/product/dashboards) [AI Agent](https://oneuptime.com/product/ai-agent)

Enterprise

[DevOps](https://oneuptime.com/solutions/devops) [SRE](https://oneuptime.com/solutions/sre) [Platform](https://oneuptime.com/solutions/platform)

[Pricing](https://oneuptime.com/pricing) [Docs](https://oneuptime.com/docs) [Request Demo](https://oneuptime.com/enterprise/demo) [Support](https://oneuptime.com/support)

[Sign\\
up](https://oneuptime.com/accounts/register)

Existing customer?
[Sign in](https://oneuptime.com/accounts)

# How to Run Keepalived in Docker for Virtual IP Failover

Configure Keepalived in Docker to provide virtual IP failover using VRRP for high availability service deployments.


[![Nawaz Dhandala](https://avatars.githubusercontent.com/nawazdhandala)@nawazdhandala](https://github.com/nawazdhandala)•Feb 08, 2026•Reading time
7 min read

[Docker](https://oneuptime.com/blog/tag/docker) [Keepalived](https://oneuptime.com/blog/tag/keepalived) [VRRP](https://oneuptime.com/blog/tag/vrrp) [High Availability](https://oneuptime.com/blog/tag/high-availability) [Failover](https://oneuptime.com/blog/tag/failover) [Virtual IP](https://oneuptime.com/blog/tag/virtual-ip) [Networking](https://oneuptime.com/blog/tag/networking)

## On this page

[How VRRP Works](https://oneuptime.com/blog/post/2026-02-08-how-to-run-keepalived-in-docker-for-virtual-ip-failover/view#how-vrrp-works) [Prerequisites](https://oneuptime.com/blog/post/2026-02-08-how-to-run-keepalived-in-docker-for-virtual-ip-failover/view#prerequisites) [Basic Setup: Active-Passive Failover](https://oneuptime.com/blog/post/2026-02-08-how-to-run-keepalived-in-docker-for-virtual-ip-failover/view#basic-setup-active-passive-failover) [Docker Compose Setup](https://oneuptime.com/blog/post/2026-02-08-how-to-run-keepalived-in-docker-for-virtual-ip-failover/view#docker-compose-setup) [Building a Custom Keepalived Image](https://oneuptime.com/blog/post/2026-02-08-how-to-run-keepalived-in-docker-for-virtual-ip-failover/view#building-a-custom-keepalived-image) [Testing Failover](https://oneuptime.com/blog/post/2026-02-08-how-to-run-keepalived-in-docker-for-virtual-ip-failover/view#testing-failover) [Unicast VRRP (For Cloud Environments)](https://oneuptime.com/blog/post/2026-02-08-how-to-run-keepalived-in-docker-for-virtual-ip-failover/view#unicast-vrrp-for-cloud-environments) [Combining Keepalived with HAProxy](https://oneuptime.com/blog/post/2026-02-08-how-to-run-keepalived-in-docker-for-virtual-ip-failover/view#combining-keepalived-with-haproxy) [Monitoring VRRP State](https://oneuptime.com/blog/post/2026-02-08-how-to-run-keepalived-in-docker-for-virtual-ip-failover/view#monitoring-vrrp-state) [Production Considerations](https://oneuptime.com/blog/post/2026-02-08-how-to-run-keepalived-in-docker-for-virtual-ip-failover/view#production-considerations)

[Share on X](https://twitter.com/intent/tweet?text=%20How%20to%20Run%20Keepalived%20in%20Docker%20for%20Virtual%20IP%20Failover&url=https%3A%2F%2Foneuptime.com%2Fblog%2Fpost%2F2026-02-08-how-to-run-keepalived-in-docker-for-virtual-ip-failover%2Fview "Share on X")[Share on LinkedIn](https://www.linkedin.com/sharing/share-offsite/?url=https%3A%2F%2Foneuptime.com%2Fblog%2Fpost%2F2026-02-08-how-to-run-keepalived-in-docker-for-virtual-ip-failover%2Fview "Share on LinkedIn")[Discuss on Hacker News](https://news.ycombinator.com/submitlink?u=https%3A%2F%2Foneuptime.com%2Fblog%2Fpost%2F2026-02-08-how-to-run-keepalived-in-docker-for-virtual-ip-failover%2Fview&t=%20How%20to%20Run%20Keepalived%20in%20Docker%20for%20Virtual%20IP%20Failover "Discuss on Hacker News")

* * *

Keepalived provides high availability through the Virtual Router Redundancy Protocol (VRRP). It assigns a floating virtual IP address to a group of servers, ensuring that if the active server goes down, another one takes over the IP address seamlessly. Clients never need to know which physical server they are talking to - they just connect to the virtual IP.

Running Keepalived in Docker requires some special networking considerations because VRRP operates at the network layer. This guide covers how to set up Keepalived containers for virtual IP failover, including active-passive and active-active configurations.

## How VRRP Works

VRRP works by electing one server as the MASTER and the others as BACKUP. The MASTER holds the virtual IP and responds to traffic. BACKUP servers listen for VRRP advertisements from the MASTER. If they stop hearing advertisements, the highest-priority BACKUP promotes itself to MASTER and takes over the virtual IP.

Connects to VIP: 192.168.1.100

Normal Operation

Failover

VRRP Advertisements

Health Monitoring

Client

Virtual IP

Server 1 - MASTERPriority 101

Server 2 - BACKUPPriority 100

## Prerequisites

Keepalived in Docker requires elevated network privileges because it manipulates IP addresses and sends multicast VRRP packets. You need:

- Two or more Docker hosts on the same Layer 2 network
- The `NET_ADMIN` and `NET_BROADCAST` capabilities for the container
- Host networking mode (VRRP does not work with Docker bridge networks)
- A free IP address on the subnet to use as the virtual IP

## Basic Setup: Active-Passive Failover

### MASTER Node Configuration

Create the Keepalived configuration for the primary server.

```bash
# keepalived-master.conf - Primary server configuration
# This server has higher priority and will be the default MASTER

global_defs {
    # Unique identifier for this Keepalived instance
    router_id MASTER_NODE
    # Disable email notifications (configure SMTP for production)
    enable_script_security
}

# Health check script that verifies the target service is running
vrrp_script check_service {
    script "/usr/local/bin/check_service.sh"
    interval 2        # Run every 2 seconds
    weight -20        # Reduce priority by 20 if the check fails
    fall 3            # Mark as failed after 3 consecutive failures
    rise 2            # Mark as recovered after 2 consecutive successes
}

vrrp_instance VI_1 {
    state MASTER
    interface eth0                 # Network interface to bind to
    virtual_router_id 51          # Must be the same on all nodes in the group
    priority 101                  # Higher priority becomes MASTER
    advert_int 1                  # Send VRRP advertisements every 1 second

    # Authentication between VRRP peers
    authentication {
        auth_type PASS
        auth_pass secretkey123
    }

    # The virtual IP address that floats between nodes
    virtual_ipaddress {
        192.168.1.100/24
    }

    # Run the health check script defined above
    track_script {
        check_service
    }

    # Scripts to execute on state transitions
    notify_master "/usr/local/bin/notify.sh MASTER"
    notify_backup "/usr/local/bin/notify.sh BACKUP"
    notify_fault  "/usr/local/bin/notify.sh FAULT"
}
```

### BACKUP Node Configuration

The backup configuration is nearly identical but with a lower priority.

```bash
# keepalived-backup.conf - Backup server configuration
# Lower priority means this server only takes over when the MASTER fails

global_defs {
    router_id BACKUP_NODE
    enable_script_security
}

vrrp_script check_service {
    script "/usr/local/bin/check_service.sh"
    interval 2
    weight -20
    fall 3
    rise 2
}

vrrp_instance VI_1 {
    state BACKUP
    interface eth0
    virtual_router_id 51          # Must match the MASTER's router ID
    priority 100                  # Lower than MASTER's 101
    advert_int 1

    authentication {
        auth_type PASS
        auth_pass secretkey123    # Must match MASTER's password
    }

    virtual_ipaddress {
        192.168.1.100/24          # Same VIP as MASTER
    }

    track_script {
        check_service
    }

    notify_master "/usr/local/bin/notify.sh MASTER"
    notify_backup "/usr/local/bin/notify.sh BACKUP"
    notify_fault  "/usr/local/bin/notify.sh FAULT"
}
```

### Health Check Script

Create a script that verifies your actual service is healthy.

```bash
#!/bin/bash
# check_service.sh - Verify the target service is responding
# Exit code 0 = healthy, non-zero = unhealthy

# Check if Nginx is responding on port 80
curl -sf http://localhost:80/health > /dev/null 2>&1
exit $?
```

### Notification Script

This script runs whenever Keepalived transitions between states.

```bash
#!/bin/bash
# notify.sh - Log and alert on VRRP state changes
# Receives the new state as an argument

STATE=$1
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo "${TIMESTAMP} - VRRP state changed to: ${STATE}" >> /var/log/keepalived-notify.log

case $STATE in
    MASTER)
        echo "${TIMESTAMP} - This node is now MASTER. VIP is active here."
        # Optionally send an alert
        # curl -X POST https://alerts.example.com/webhook -d "Node became MASTER"
        ;;
    BACKUP)
        echo "${TIMESTAMP} - This node is now BACKUP. VIP has moved away."
        ;;
    FAULT)
        echo "${TIMESTAMP} - This node is in FAULT state. Service check failed."
        ;;
esac
```

## Docker Compose Setup

### MASTER Node docker-compose.yml

```yaml
# docker-compose.yml for the MASTER Keepalived node
# Host networking is required for VRRP to function properly
version: "3.8"

services:
  keepalived:
    image: osixia/keepalived:2.0.20
    container_name: keepalived-master
    restart: unless-stopped
    # Host network mode is mandatory for VRRP
    network_mode: host
    cap_add:
      - NET_ADMIN       # Required to manage IP addresses
      - NET_BROADCAST    # Required for VRRP multicast
    environment:
      - KEEPALIVED_VIRTUAL_IPS=192.168.1.100
      - KEEPALIVED_UNICAST_PEERS=
      - KEEPALIVED_PRIORITY=101
      - KEEPALIVED_INTERFACE=eth0
    volumes:
      - ./keepalived-master.conf:/container/service/keepalived/assets/keepalived.conf:ro
      - ./check_service.sh:/usr/local/bin/check_service.sh:ro
      - ./notify.sh:/usr/local/bin/notify.sh:ro

  # The actual service being protected by Keepalived
  nginx:
    image: nginx:alpine
    container_name: web-server
    restart: unless-stopped
    network_mode: host
    volumes:
      - ./html:/usr/share/nginx/html:ro
```

### BACKUP Node docker-compose.yml

```yaml
# docker-compose.yml for the BACKUP Keepalived node
# Deploy this on a second server on the same network
version: "3.8"

services:
  keepalived:
    image: osixia/keepalived:2.0.20
    container_name: keepalived-backup
    restart: unless-stopped
    network_mode: host
    cap_add:
      - NET_ADMIN
      - NET_BROADCAST
    environment:
      - KEEPALIVED_VIRTUAL_IPS=192.168.1.100
      - KEEPALIVED_PRIORITY=100
      - KEEPALIVED_INTERFACE=eth0
    volumes:
      - ./keepalived-backup.conf:/container/service/keepalived/assets/keepalived.conf:ro
      - ./check_service.sh:/usr/local/bin/check_service.sh:ro
      - ./notify.sh:/usr/local/bin/notify.sh:ro

  nginx:
    image: nginx:alpine
    container_name: web-server
    restart: unless-stopped
    network_mode: host
    volumes:
      - ./html:/usr/share/nginx/html:ro
```

## Building a Custom Keepalived Image

If the pre-built image does not meet your needs, build your own.

```dockerfile
# Dockerfile for a custom Keepalived image
# Includes additional tools for health checking
FROM alpine:3.19

RUN apk add --no-cache \
    keepalived \
    curl \
    bash \
    iputils \
    && rm -rf /var/cache/apk/*

# Copy configuration and scripts
COPY keepalived.conf /etc/keepalived/keepalived.conf
COPY check_service.sh /usr/local/bin/check_service.sh
COPY notify.sh /usr/local/bin/notify.sh

RUN chmod +x /usr/local/bin/check_service.sh /usr/local/bin/notify.sh

# Keepalived runs in the foreground
CMD ["keepalived", "--dont-fork", "--log-console", "-D"]
```

```bash
# Build and run the custom image
docker build -t keepalived-custom .
docker run -d \
  --name keepalived \
  --network host \
  --cap-add NET_ADMIN \
  --cap-add NET_BROADCAST \
  keepalived-custom
```

## Testing Failover

Verify that failover works correctly by simulating a failure on the MASTER node.

```bash
# On the MASTER node, check the current VRRP state
docker exec keepalived-master cat /tmp/keepalived.data

# Verify the VIP is assigned to the MASTER's interface
ip addr show eth0 | grep 192.168.1.100

# Simulate a failure by stopping the MASTER's Keepalived
docker stop keepalived-master

# On the BACKUP node, confirm it has taken over the VIP
ip addr show eth0 | grep 192.168.1.100

# Test that the service is still accessible through the VIP
curl http://192.168.1.100

# Restart the MASTER and verify it reclaims the VIP
docker start keepalived-master
# Wait a few seconds for VRRP re-election
sleep 5
ip addr show eth0 | grep 192.168.1.100
```

## Unicast VRRP (For Cloud Environments)

Cloud providers often block multicast traffic. Use unicast VRRP instead.

```bash
# Unicast VRRP configuration
# Replace multicast with direct peer communication

vrrp_instance VI_1 {
    state MASTER
    interface eth0
    virtual_router_id 51
    priority 101
    advert_int 1

    # Use unicast instead of multicast
    unicast_src_ip 192.168.1.10     # This node's real IP
    unicast_peer {
        192.168.1.11                 # The other node's real IP
    }

    authentication {
        auth_type PASS
        auth_pass secretkey123
    }

    virtual_ipaddress {
        192.168.1.100/24
    }
}
```

## Combining Keepalived with HAProxy

A common production pattern pairs Keepalived with HAProxy. Keepalived manages the floating VIP, and HAProxy handles the actual load balancing.

```yaml
# Combined Keepalived + HAProxy setup
version: "3.8"

services:
  keepalived:
    image: osixia/keepalived:2.0.20
    container_name: keepalived
    network_mode: host
    cap_add:
      - NET_ADMIN
      - NET_BROADCAST
    volumes:
      - ./keepalived.conf:/container/service/keepalived/assets/keepalived.conf:ro
      - ./check_haproxy.sh:/usr/local/bin/check_service.sh:ro

  haproxy:
    image: haproxy:2.9-alpine
    container_name: haproxy
    network_mode: host
    volumes:
      - ./haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro
```

Where check\_haproxy.sh verifies HAProxy is running:

```bash
#!/bin/bash
# check_haproxy.sh - Verify HAProxy is accepting connections
# Used by Keepalived to determine if this node should hold the VIP
killall -0 haproxy 2>/dev/null
exit $?
```

## Monitoring VRRP State

Track Keepalived state transitions to detect flapping or persistent failures.

```bash
# View Keepalived logs from the container
docker logs -f keepalived-master

# Check the current VRRP state
docker exec keepalived-master keepalived --dump-conf

# Monitor state changes in real time using the notification log
docker exec keepalived-master tail -f /var/log/keepalived-notify.log
```

Integrate these state changes with your monitoring system. OneUptime can alert your team when failover events occur, helping you investigate root causes before they become recurring problems.

## Production Considerations

Set the `advert_int` to 1 second for fast failover detection. Use authentication to prevent rogue VRRP instances from hijacking the VIP. Always test failover in a staging environment before deploying to production. Monitor both nodes to ensure the BACKUP is healthy and ready to take over. Keep the health check script simple and fast - a slow check delays failover detection. Use unicast mode in cloud environments where multicast is not supported.

Keepalived in Docker gives you automatic IP failover with sub-second detection times. Combined with a load balancer like HAProxy, it forms the foundation of a highly available service architecture.

Share this article

[Share on X](https://twitter.com/intent/tweet?text=%20How%20to%20Run%20Keepalived%20in%20Docker%20for%20Virtual%20IP%20Failover&url=https%3A%2F%2Foneuptime.com%2Fblog%2Fpost%2F2026-02-08-how-to-run-keepalived-in-docker-for-virtual-ip-failover%2Fview "Share on X")[Share on LinkedIn](https://www.linkedin.com/sharing/share-offsite/?url=https%3A%2F%2Foneuptime.com%2Fblog%2Fpost%2F2026-02-08-how-to-run-keepalived-in-docker-for-virtual-ip-failover%2Fview "Share on LinkedIn")[Discuss on Hacker News](https://news.ycombinator.com/submitlink?u=https%3A%2F%2Foneuptime.com%2Fblog%2Fpost%2F2026-02-08-how-to-run-keepalived-in-docker-for-virtual-ip-failover%2Fview&t=%20How%20to%20Run%20Keepalived%20in%20Docker%20for%20Virtual%20IP%20Failover "Discuss on Hacker News")

![Nawaz Dhandala](https://avatars.githubusercontent.com/nawazdhandala)

### Nawaz Dhandala

Author

@nawazdhandala • Feb 08, 2026 • 7 min read

Nawaz is building OneUptime with a passion for engineering reliable systems and improving observability.

[GitHub](https://github.com/nawazdhandala)

Our Commitment to Open Source

- Everything we do at OneUptime is 100% open-source. You can contribute by writing a post just like this.
Please check contributing guidelines [here.](https://github.com/oneuptime/blog)



If you wish to contribute to this post, you can make edits and improve it [here](https://github.com/oneuptime/blog/tree/master/posts/2026-02-08-how-to-run-keepalived-in-docker-for-virtual-ip-failover).


# OneUptime is an open-source observability platform.

Monitor, Observe, Debug, Resolve. Everything you need to build reliable software in one open-source platform. Get started today.

[Get started](https://oneuptime.com/accounts/register) [Request Demo →](https://oneuptime.com/enterprise/demo)

We use cookies to enhance your browsing experience and provide
personalized content. By clicking "Accept," you consent to the use of cookies.

Our product uses both first-party and third-party cookies for session storage and for various other purposes.

Please note that disabling certain cookies may affect the functionality and performance of our product.

For more information about how we handle your data and cookies, please read our Privacy Policy.

By continuing to use our site without changing your cookie settings, you agree to our use of cookies as
described above. See our [terms](https://oneuptime.com/legal/terms) and our [privacy policy](https://oneuptime.com/legal/privacy)

Accept
allReject all

## Footer

Open Source Observability

### Build reliable systems with confidence

Join thousands of developers using OneUptime to monitor, debug, and optimize their infrastructure, stack, and apps.

[Read Blog](https://oneuptime.com/blog) [Star on GitHub](https://github.com/oneuptime/oneuptime)

[![OneUptime](https://oneuptime.com/img/4-gray.svg)](https://oneuptime.com/)

The complete open-source observability platform. Monitor, debug, and improve your entire stack in one place.


[GitHub](https://github.com/oneuptime/oneuptime) [X](https://x.com/oneuptimehq) [YouTube](https://www.youtube.com/@OneUptimeHQ) [Reddit](https://www.reddit.com/r/oneuptimehq/) [LinkedIn](https://www.linkedin.com/company/oneuptime)

Trusted by thousands of teams worldwide - from Fortune 500 enterprises to fast-growing startups.


### Products

- [Status Page](https://oneuptime.com/product/status-page)
- [Incidents](https://oneuptime.com/product/incident-management)
- [Monitoring](https://oneuptime.com/product/monitoring)
- [On-Call](https://oneuptime.com/product/on-call)
- [Logs](https://oneuptime.com/product/logs-management)
- [Metrics](https://oneuptime.com/product/metrics)
- [Traces](https://oneuptime.com/product/traces)
- [Exceptions](https://oneuptime.com/product/exceptions)
- [Workflows](https://oneuptime.com/product/workflows)
- [Dashboards](https://oneuptime.com/product/dashboards)
- [AI Agent](https://oneuptime.com/product/ai-agent)

### Solutions

- [Enterprise](https://oneuptime.com/enterprise/overview)
- [Request Demo](https://oneuptime.com/enterprise/demo)
- [Pricing](https://oneuptime.com/pricing)
- [Data Residency](https://oneuptime.com/legal/data-residency)

### Teams

- [DevOps](https://oneuptime.com/solutions/devops)
- [SRE](https://oneuptime.com/solutions/sre)
- [Platform](https://oneuptime.com/solutions/platform)
- [Developers](https://oneuptime.com/solutions/developers)

### Resources

- [Documentation](https://oneuptime.com/docs)
- [API Reference](https://oneuptime.com/reference)
- [Blog](https://oneuptime.com/blog)
- [Help & Support](https://oneuptime.com/support)
- [GitHub](https://github.com/oneuptime/oneuptime)
- [Changelog](https://github.com/oneuptime/oneuptime/releases)
- [Open Source Friends](https://oneuptime.com/oss-friends)

### Industries

- [FinTech](https://oneuptime.com/industries/fintech)
- [SaaS](https://oneuptime.com/industries/saas)
- [Healthcare](https://oneuptime.com/industries/healthcare)
- [E-Commerce](https://oneuptime.com/industries/ecommerce)
- [Media](https://oneuptime.com/industries/media)
- [Government](https://oneuptime.com/industries/government)

### Company

- [About Us](https://oneuptime.com/about)
- [Careers](https://github.com/OneUptime/interview)
- [Merch Store](https://shop.oneuptime.com/)
- [Contact](https://oneuptime.com/legal/contact)

### Legal

- [Terms of Service](https://oneuptime.com/legal/terms)
- [Privacy Policy](https://oneuptime.com/legal/privacy)
- [SLA](https://oneuptime.com/legal/sla)
- [Legal Center](https://oneuptime.com/legal)

### Compare

- [vs PagerDuty](https://oneuptime.com/compare/pagerduty)
- [vs Statuspage](https://oneuptime.com/compare/statuspage.io)
- [vs Incident.io](https://oneuptime.com/compare/incident.io)
- [vs Pingdom](https://oneuptime.com/compare/pingdom)
- [vs Datadog](https://oneuptime.com/compare/datadog)
- [vs New Relic](https://oneuptime.com/compare/newrelic)
- [vs Better Stack](https://oneuptime.com/compare/better-uptime)
- [vs Uptime Robot](https://oneuptime.com/compare/uptime-robot)
- [vs Checkly](https://oneuptime.com/compare/checkly)
- [vs SigNoz](https://oneuptime.com/compare/signoz)

© 2026 HackerBay, Inc. All rights reserved.

[Open Source](https://github.com/oneuptime/oneuptime) \|Made with care for developers worldwide

[SOC 2](https://oneuptime.com/legal/soc-2) [HIPAA](https://oneuptime.com/legal/hipaa) [GDPR](https://oneuptime.com/legal/gdpr) [ISO 27001](https://oneuptime.com/legal/iso-27001)