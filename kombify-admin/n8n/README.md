# n8n Workflows for kombify-admin

This folder contains n8n workflow templates for automating tool management in kombify-admin.

## Prerequisites

1. **n8n instance** - Self-hosted or cloud
2. **kombify-admin accessible** - n8n must be able to execute commands in the kombify-admin container/environment
3. **Environment variables** set in the execution environment:
   - `DATABASE_URL` - PostgreSQL connection string
   - `FIRECRAWL_API_KEY` - API key for Firecrawl
   - `OPENAI_API_KEY` - For tool enrichment (optional)

## Workflows

### 1. Scheduled Tool Discovery

**File:** `scheduled-discovery-workflow.json`

Runs automated discovery to find new self-hosted tools from configured CrawlSources.

**Features:**
- Runs every 6 hours (configurable)
- Processes all active CrawlSources in the database
- Deduplicates against existing tools
- Notifies via Slack on completion/failure

**Setup:**
1. Import the workflow into n8n
2. Configure Slack credentials (or replace with your notification method)
3. Adjust the schedule interval if needed
4. Ensure the execution environment has access to kombify-admin scripts

### 2. Tool Enrichment Pipeline

**File:** `tool-enrichment-workflow.json`

Enriches discovered tools with AI-generated descriptions, metadata, and recommendations.

**Features:**
- Processes unenriched tools in batches
- Uses OpenAI to generate descriptions and layer assignments
- Updates tool metadata in the database
- Can be triggered manually or on schedule

### 3. Tool Evaluation Workflow

**File:** `tool-evaluation-workflow.json`

Triggers the AI evaluation state machine for tools.

**Features:**
- Manually trigger evaluation for specific tools
- Progress through evaluation states (PENDING → EVALUATING → REVIEWED → APPROVED/REJECTED)
- Supports human-in-the-loop review

## Deployment Options

### Option A: Docker Compose with n8n

Add n8n to your docker-compose.yml:

```yaml
services:
  n8n:
    image: n8nio/n8n
    restart: unless-stopped
    environment:
      - N8N_HOST=n8n.yourdomain.com
      - N8N_PROTOCOL=https
      - WEBHOOK_URL=https://n8n.yourdomain.com/
      - DATABASE_URL=${DATABASE_URL}
      - FIRECRAWL_API_KEY=${FIRECRAWL_API_KEY}
      - OPENAI_API_KEY=${OPENAI_API_KEY}
    ports:
      - "5678:5678"
    volumes:
      - n8n_data:/home/node/.n8n
      - ./:/app/kombify-admin:ro
    networks:
      - kombify-network
```

### Option B: External n8n with HTTP Triggers

If n8n runs externally, modify workflows to use HTTP requests instead of executeCommand:

1. Create HTTP endpoints in kombify-admin
2. Replace executeCommand nodes with HTTP Request nodes
3. Configure authentication

## Manual Script Execution

You can run discovery scripts manually:

```bash
# Run scheduled discovery
cd kombify-admin
npx ts-node scripts/scheduled-discover.ts

# Dry run (doesn't save to database)
npx ts-node scripts/scheduled-discover.ts --dry-run

# Manual discovery for a category
npx ts-node scripts/tool-discover.ts paas
npx ts-node scripts/tool-discover.ts monitoring

# Enrich a specific tool
npx ts-node scripts/tool-enrich.ts coolify
```

## CrawlSource Configuration

CrawlSources define what to search for. Manage them via:

```bash
# List crawl sources in database
npx ts-node scripts/admin-cli.ts context list

# Or use Prisma Studio
npx prisma studio
```

Default sources (from seed.ts):
- `paas-firecrawl` - Platform-as-a-Service tools
- `monitoring-firecrawl` - Monitoring and observability
- `reverse-proxy-firecrawl` - Reverse proxies and ingress
- `identity-firecrawl` - Identity and authentication
- `awesome-selfhosted` - Awesome Self-Hosted lists

## Troubleshooting

### "Command not found" in n8n
Ensure the kombify-admin directory is mounted and ts-node is installed:
```bash
docker exec n8n which ts-node
```

### Firecrawl API errors
Check your API key and rate limits:
```bash
curl -H "Authorization: Bearer $FIRECRAWL_API_KEY" \
  https://api.firecrawl.dev/v1/search -d '{"query":"test"}'
```

### Database connection issues
Verify DATABASE_URL is accessible from the n8n container:
```bash
docker exec n8n npx prisma db pull
```

## Customization

### Change Schedule Interval
In the workflow JSON, modify the `scheduleTrigger` node:
```json
{
  "parameters": {
    "rule": {
      "interval": [{ "field": "hours", "hoursInterval": 12 }]
    }
  }
}
```

### Add Notification Channels
Replace Slack nodes with:
- Discord webhooks
- Email (SMTP)
- Telegram bots
- Custom HTTP endpoints

### Filter Tool Categories
Modify the discovery script or add code nodes to filter by category/layer.
