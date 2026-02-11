[Skip to main content](https://oneuptime.com/blog/post/2026-02-08-how-to-set-up-active-passive-docker-container-failover/view#main-content)

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

# How to Set Up Active-Passive Docker Container Failover

Build an active-passive failover setup for Docker containers using Keepalived and health check scripts for automatic recovery.


[![Nawaz Dhandala](https://avatars.githubusercontent.com/nawazdhandala)@nawazdhandala](https://github.com/nawazdhandala)•Feb 08, 2026•Reading time
6 min read

[Docker](https://oneuptime.com/blog/tag/docker) [Failover](https://oneuptime.com/blog/tag/failover) [High Availability](https://oneuptime.com/blog/tag/high-availability) [Keepalived](https://oneuptime.com/blog/tag/keepalived) [Production](https://oneuptime.com/blog/tag/production) [DevOps](https://oneuptime.com/blog/tag/devops)

## On this page

[How Active-Passive Failover Works](https://oneuptime.com/blog/post/2026-02-08-how-to-set-up-active-passive-docker-container-failover/view#how-active-passive-failover-works) [Prerequisites](https://oneuptime.com/blog/post/2026-02-08-how-to-set-up-active-passive-docker-container-failover/view#prerequisites) [Installing Keepalived](https://oneuptime.com/blog/post/2026-02-08-how-to-set-up-active-passive-docker-container-failover/view#installing-keepalived) [Configuring the Primary Server](https://oneuptime.com/blog/post/2026-02-08-how-to-set-up-active-passive-docker-container-failover/view#configuring-the-primary-server) [Configuring the Secondary Server](https://oneuptime.com/blog/post/2026-02-08-how-to-set-up-active-passive-docker-container-failover/view#configuring-the-secondary-server) [Health Check Script](https://oneuptime.com/blog/post/2026-02-08-how-to-set-up-active-passive-docker-container-failover/view#health-check-script) [Notification Script](https://oneuptime.com/blog/post/2026-02-08-how-to-set-up-active-passive-docker-container-failover/view#notification-script) [Setting Up the Application Stack](https://oneuptime.com/blog/post/2026-02-08-how-to-set-up-active-passive-docker-container-failover/view#setting-up-the-application-stack) [Starting Keepalived](https://oneuptime.com/blog/post/2026-02-08-how-to-set-up-active-passive-docker-container-failover/view#starting-keepalived) [Testing the Failover](https://oneuptime.com/blog/post/2026-02-08-how-to-set-up-active-passive-docker-container-failover/view#testing-the-failover) [Data Synchronization](https://oneuptime.com/blog/post/2026-02-08-how-to-set-up-active-passive-docker-container-failover/view#data-synchronization) [Monitoring the Failover Setup](https://oneuptime.com/blog/post/2026-02-08-how-to-set-up-active-passive-docker-container-failover/view#monitoring-the-failover-setup)

[Share on X](https://twitter.com/intent/tweet?text=%20How%20to%20Set%20Up%20Active-Passive%20Docker%20Container%20Failover&url=https%3A%2F%2Foneuptime.com%2Fblog%2Fpost%2F2026-02-08-how-to-set-up-active-passive-docker-container-failover%2Fview "Share on X")[Share on LinkedIn](https://www.linkedin.com/sharing/share-offsite/?url=https%3A%2F%2Foneuptime.com%2Fblog%2Fpost%2F2026-02-08-how-to-set-up-active-passive-docker-container-failover%2Fview "Share on LinkedIn")[Discuss on Hacker News](https://news.ycombinator.com/submitlink?u=https%3A%2F%2Foneuptime.com%2Fblog%2Fpost%2F2026-02-08-how-to-set-up-active-passive-docker-container-failover%2Fview&t=%20How%20to%20Set%20Up%20Active-Passive%20Docker%20Container%20Failover "Discuss on Hacker News")

* * *

Active-passive failover is the simplest form of high availability. One server handles all the traffic while a second server sits idle, ready to take over if the primary fails. This pattern works well for stateful services like databases, message queues, and applications that cannot easily run as multiple instances.

This guide sets up active-passive failover between two Docker hosts using Keepalived, a battle-tested Linux tool for managing virtual IP addresses and failover.

## How Active-Passive Failover Works

The two servers share a virtual IP (VIP) address. Clients connect to the VIP. The active server owns the VIP and handles all requests. Keepalived monitors the active server's health. If the active server fails, Keepalived moves the VIP to the passive server, which then starts handling traffic.

Passive Host (192.168.1.11)

Active Host (192.168.1.10)

heartbeat

takes over on failure

Keepalived BACKUP

Docker Containers - standby

Keepalived MASTER

Docker Containers

Virtual IP: 192.168.1.100

## Prerequisites

You need two servers on the same network with Docker installed. Both servers must be able to communicate over VRRP (Virtual Router Redundancy Protocol) on the network.

For this guide, the servers are:

- Primary: 192.168.1.10
- Secondary: 192.168.1.11
- Virtual IP: 192.168.1.100

## Installing Keepalived

Install Keepalived on both servers:

```bash
# Install Keepalived on both primary and secondary servers
sudo apt-get update
sudo apt-get install -y keepalived
```

## Configuring the Primary Server

Create the Keepalived configuration on the primary server:

```bash
# /etc/keepalived/keepalived.conf on the PRIMARY server
vrrp_script check_docker {
    # Script that checks if the Docker container is healthy
    script "/usr/local/bin/check-docker-health.sh"
    interval 5          # Check every 5 seconds
    weight -20          # Reduce priority by 20 if the check fails
    fall 2              # Mark as failed after 2 consecutive failures
    rise 2              # Mark as recovered after 2 consecutive successes
}

vrrp_instance DOCKER_HA {
    state MASTER                # This is the primary server
    interface eth0              # Network interface to use
    virtual_router_id 51        # Must be the same on both servers
    priority 100                # Higher priority wins the VIP
    advert_int 1                # Send heartbeat every 1 second
    authentication {
        auth_type PASS
        auth_pass docker_ha_secret
    }
    virtual_ipaddress {
        192.168.1.100/24        # The virtual IP address
    }
    track_script {
        check_docker             # Use the health check script
    }
    notify /usr/local/bin/keepalived-notify.sh
}
```

## Configuring the Secondary Server

The secondary configuration is nearly identical, with two changes: the state is BACKUP and the priority is lower.

```bash
# /etc/keepalived/keepalived.conf on the SECONDARY server
vrrp_script check_docker {
    script "/usr/local/bin/check-docker-health.sh"
    interval 5
    weight -20
    fall 2
    rise 2
}

vrrp_instance DOCKER_HA {
    state BACKUP                # This is the backup server
    interface eth0
    virtual_router_id 51        # Same ID as the primary
    priority 90                 # Lower priority than the primary
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass docker_ha_secret
    }
    virtual_ipaddress {
        192.168.1.100/24
    }
    track_script {
        check_docker
    }
    notify /usr/local/bin/keepalived-notify.sh
}
```

## Health Check Script

This script checks that Docker is running and that key containers are healthy. Deploy it on both servers.

```bash
#!/bin/bash
# /usr/local/bin/check-docker-health.sh
# Returns 0 (success) if Docker and critical containers are healthy
# Returns 1 (failure) to trigger Keepalived failover

# Check if Docker daemon is responding
if ! docker info > /dev/null 2>&1; then
    echo "Docker daemon is not responding"
    exit 1
fi

# List of critical containers that must be running and healthy
CRITICAL_CONTAINERS=("app" "redis")

for CONTAINER in "${CRITICAL_CONTAINERS[@]}"; do
    # Check if container exists and is running
    STATE=$(docker inspect --format='{{.State.Running}}' "$CONTAINER" 2>/dev/null)
    if [ "$STATE" != "true" ]; then
        echo "Container $CONTAINER is not running"
        exit 1
    fi

    # Check health status if the container has a health check defined
    HEALTH=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$CONTAINER" 2>/dev/null)
    if [ "$HEALTH" != "healthy" ] && [ "$HEALTH" != "none" ]; then
        echo "Container $CONTAINER health status: $HEALTH"
        exit 1
    fi
done

# All checks passed
exit 0
```

Make it executable on both servers:

```bash
# Set the script as executable
sudo chmod +x /usr/local/bin/check-docker-health.sh
```

## Notification Script

This script runs when Keepalived changes state. Use it to start or stop containers and send alerts.

```bash
#!/bin/bash
# /usr/local/bin/keepalived-notify.sh
# Called by Keepalived on state changes
# Arguments: $1=group/instance, $2=name, $3=state (MASTER/BACKUP/FAULT)

TYPE=$1
NAME=$2
STATE=$3
LOGFILE="/var/log/keepalived-transitions.log"
WEBHOOK="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"

log_and_notify() {
    local MSG="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $MSG" >> "$LOGFILE"
    # Send notification
    curl -s -X POST "$WEBHOOK" \
      -H "Content-Type: application/json" \
      -d "{\"text\": \"$MSG\"}" > /dev/null 2>&1
}

case $STATE in
    "MASTER")
        log_and_notify "$(hostname) became MASTER - starting containers"
        # Start containers when becoming master
        cd /opt/app && docker compose up -d
        ;;
    "BACKUP")
        log_and_notify "$(hostname) became BACKUP - stopping containers"
        # Stop containers when becoming backup (optional)
        # Some setups keep containers running on both hosts
        cd /opt/app && docker compose stop
        ;;
    "FAULT")
        log_and_notify "$(hostname) entered FAULT state"
        ;;
esac
```

Make it executable:

```bash
sudo chmod +x /usr/local/bin/keepalived-notify.sh
```

## Setting Up the Application Stack

Create identical Docker Compose files on both servers:

```yaml
# /opt/app/docker-compose.yml - identical on both hosts
version: "3.9"

services:
  app:
    image: myapp:latest
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      DATABASE_URL: postgresql://db.external:5432/myapp
      REDIS_URL: redis://localhost:6379
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 10s
      timeout: 5s
      retries: 3
    depends_on:
      redis:
        condition: service_healthy

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    command: redis-server --appendonly yes
    volumes:
      - redis-data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 3

volumes:
  redis-data:
```

Pull images on both servers so failover is fast:

```bash
# Pre-pull images on both servers so failover does not wait for downloads
docker compose -f /opt/app/docker-compose.yml pull
```

Start the stack on the primary:

```bash
# Start the application stack on the primary server
cd /opt/app && docker compose up -d
```

## Starting Keepalived

Start Keepalived on both servers:

```bash
# Enable and start Keepalived
sudo systemctl enable keepalived
sudo systemctl start keepalived
```

Verify the VIP is assigned to the primary:

```bash
# Check that the VIP is on the primary server's network interface
ip addr show eth0 | grep 192.168.1.100
```

You should see the VIP listed on the primary server.

## Testing the Failover

Simulate a failure by stopping Docker on the primary:

```bash
# On the primary server, stop Docker to simulate a failure
sudo systemctl stop docker
```

Within a few seconds, Keepalived detects the failure through the health check script, lowers the primary's priority, and the secondary takes over the VIP. Check on the secondary:

```bash
# On the secondary, verify it now holds the VIP
ip addr show eth0 | grep 192.168.1.100
```

The secondary should now have the VIP, and its notification script should have started the containers.

Test that the service responds through the VIP:

```bash
# From any machine on the network, test the service
curl http://192.168.1.100:8080/health
```

Restore the primary:

```bash
# On the primary, restart Docker
sudo systemctl start docker
```

Because the primary has a higher priority (100 vs 90), Keepalived will move the VIP back to the primary automatically. This is called preemption. If you prefer the secondary to keep the VIP after a failover (non-preemptive), add `nopreempt` to the BACKUP server's configuration.

## Data Synchronization

The biggest challenge with active-passive failover is keeping data in sync. Several strategies work:

**External database.** Store all application state in a managed database or a database on separate servers. Both Docker hosts connect to the same external database. No data sync is needed.

**Shared storage.** Use a network filesystem like NFS or GlusterFS mounted on both hosts. The active host writes to it, and the passive host has immediate access if it takes over.

**DRBD (Distributed Replicated Block Device).** Replicate a block device between the two hosts. DRBD synchronously mirrors writes from the primary to the secondary.

For most applications, an external database is the simplest and most reliable approach. Keep your Docker containers stateless and push all state to the database.

## Monitoring the Failover Setup

Keep an eye on the Keepalived state and transition history:

```bash
# Check Keepalived status
sudo systemctl status keepalived

# Watch the transition log
tail -f /var/log/keepalived-transitions.log

# Check VRRP statistics
sudo journalctl -u keepalived --since "1 hour ago"
```

Active-passive failover with Keepalived is a proven pattern that has been used in production for decades. It trades some resource utilization (the passive server sits idle) for simplicity and predictability. When your container goes down, you get automatic recovery in seconds without any orchestration platform.

Share this article

[Share on X](https://twitter.com/intent/tweet?text=%20How%20to%20Set%20Up%20Active-Passive%20Docker%20Container%20Failover&url=https%3A%2F%2Foneuptime.com%2Fblog%2Fpost%2F2026-02-08-how-to-set-up-active-passive-docker-container-failover%2Fview "Share on X")[Share on LinkedIn](https://www.linkedin.com/sharing/share-offsite/?url=https%3A%2F%2Foneuptime.com%2Fblog%2Fpost%2F2026-02-08-how-to-set-up-active-passive-docker-container-failover%2Fview "Share on LinkedIn")[Discuss on Hacker News](https://news.ycombinator.com/submitlink?u=https%3A%2F%2Foneuptime.com%2Fblog%2Fpost%2F2026-02-08-how-to-set-up-active-passive-docker-container-failover%2Fview&t=%20How%20to%20Set%20Up%20Active-Passive%20Docker%20Container%20Failover "Discuss on Hacker News")

![Nawaz Dhandala](https://avatars.githubusercontent.com/nawazdhandala)

### Nawaz Dhandala

Author

@nawazdhandala • Feb 08, 2026 • 6 min read

Nawaz is building OneUptime with a passion for engineering reliable systems and improving observability.

[GitHub](https://github.com/nawazdhandala)

Our Commitment to Open Source

- Everything we do at OneUptime is 100% open-source. You can contribute by writing a post just like this.
Please check contributing guidelines [here.](https://github.com/oneuptime/blog)



If you wish to contribute to this post, you can make edits and improve it [here](https://github.com/oneuptime/blog/tree/master/posts/2026-02-08-how-to-set-up-active-passive-docker-container-failover).


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