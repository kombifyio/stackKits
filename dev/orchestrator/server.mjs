import express from 'express';
import { WebSocketServer } from 'ws';
import Docker from 'dockerode';
import { exec } from 'child_process';
import { createServer } from 'http';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const app = express();
const server = createServer(app);
const docker = new Docker({ socketPath: '/var/run/docker.sock' });

app.use(express.static(join(__dirname, 'public')));
app.use(express.json());

const DEMOS = {
  'base-kit':        { prefix: 'demo-',    dir: 'demos/base-kit',        label: 'Base Kit',        port: 7880, apiPort: 7090 },
  'modern-homelab':  { prefix: 'modern-',  dir: 'demos/modern-homelab',  label: 'Modern Homelab',  port: 7980, apiPort: 7190 },
  'ha-kit':          { prefix: 'ha-',      dir: 'demos/ha-kit',          label: 'HA Kit',          port: 8180, apiPort: 8290 },
};

// GET /api/demos — status of all demos
app.get('/api/demos', async (_req, res) => {
  try {
    const containers = await docker.listContainers({ all: true });
    const result = Object.entries(DEMOS).map(([name, { prefix, label, port }]) => {
      const matched = containers
        .filter(c => c.Names.some(n => n.replace('/', '').startsWith(prefix)))
        .map(c => ({
          name: c.Names[0].replace('/', ''),
          state: c.State,
          status: c.Status,
          health: c.Status.includes('healthy') ? 'healthy' : c.Status.includes('starting') ? 'starting' : '',
        }));
      return { name, label, port, running: matched.some(c => c.state === 'running'), containers: matched };
    });
    res.json(result);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// GET /api/vm — VM container status
app.get('/api/vm', async (_req, res) => {
  try {
    const container = docker.getContainer('stackkits-vm');
    const info = await container.inspect();
    res.json({
      running: info.State.Running,
      status: info.State.Status,
      health: info.State.Health?.Status || 'unknown',
    });
  } catch (e) {
    res.json({ running: false, status: 'not found', health: 'unknown' });
  }
});

// POST /api/demos/:name/start
app.post('/api/demos/:name/start', (req, res) => {
  const demo = DEMOS[req.params.name];
  if (!demo) return res.status(400).json({ error: 'Unknown demo' });

  const cmd = `docker compose -f /workspace/${demo.dir}/docker-compose.yml up -d`;
  exec(cmd, { timeout: 180000 }, (err, stdout, stderr) => {
    if (err) return res.status(500).json({ error: stderr || err.message });
    res.json({ ok: true, output: stdout + stderr });
  });
});

// POST /api/demos/:name/stop
app.post('/api/demos/:name/stop', (req, res) => {
  const demo = DEMOS[req.params.name];
  if (!demo) return res.status(400).json({ error: 'Unknown demo' });

  const cmd = `docker compose -f /workspace/${demo.dir}/docker-compose.yml down -v`;
  exec(cmd, { timeout: 120000 }, (err, stdout, stderr) => {
    if (err) return res.status(500).json({ error: stderr || err.message });
    res.json({ ok: true, output: stdout + stderr });
  });
});

// POST /api/demos/:name/test — run integration test
app.post('/api/demos/:name/test', (req, res) => {
  const demo = DEMOS[req.params.name];
  if (!demo) return res.status(400).json({ error: 'Unknown demo' });

  const testScript = `/workspace/${demo.dir}/test.sh`;
  const cmd = `bash ${testScript}`;
  const portEnv = {
    'base-kit':       { BASE_KIT_PORT: String(demo.port), BASE_KIT_API_PORT: String(demo.apiPort) },
    'modern-homelab': { MODERN_KIT_PORT: String(demo.port), MODERN_KIT_API_PORT: String(demo.apiPort) },
    'ha-kit':         { HA_KIT_PORT: String(demo.port), HA_KIT_API_PORT: String(demo.apiPort) },
  };
  exec(cmd, { timeout: 60000, env: { ...process.env, ...portEnv[req.params.name] } }, (err, stdout, stderr) => {
    res.json({ ok: !err, output: stdout + stderr, exitCode: err?.code || 0 });
  });
});

// --- Portal API ---

// Service definitions for the Portal deployment view
const PORTAL_SERVICES = [
  { name: 'traefik',   layer: 'L2 Platform', role: 'Reverse Proxy',    subdomain: 'traefik', container: 'traefik',         description: 'Ingress controller with auto-HTTPS and service discovery' },
  { name: 'tinyauth',  layer: 'L2 Platform', role: 'Authentication',   subdomain: 'auth',    container: 'tinyauth',        description: 'ForwardAuth proxy with passkeys, passwords, and OAuth' },
  { name: 'pocketid',  layer: 'L2 Platform', role: 'Identity / OIDC',  subdomain: 'id',      container: 'pocketid',        description: 'Self-hosted OpenID Connect identity provider' },
  { name: 'dokploy',   layer: 'L2 Platform', role: 'App Deployment',   subdomain: 'dokploy', container: 'dokploy',         description: 'PaaS platform for deploying your applications' },
  { name: 'kuma',      layer: 'L3 Apps',     role: 'Monitoring',       subdomain: 'kuma',    container: 'uptime-kuma',     description: 'Uptime monitoring with notifications and status pages' },
  { name: 'dozzle',    layer: 'L3 Apps',     role: 'Log Viewer',       subdomain: 'logs',    container: 'dozzle',          description: 'Real-time Docker container log viewer' },
  { name: 'whoami',    layer: 'L3 Apps',     role: 'Network Test',     subdomain: 'whoami',  container: 'whoami',          description: 'HTTP echo service for network and routing diagnostics' },
];

// GET /api/portal/deployment — what was deployed
app.get('/api/portal/deployment', (_req, res) => {
  const domain = process.env.DOMAIN || 'stack.local';
  const kombifyBase = process.env.KOMBIFY_BASE_SUBDOMAIN || '';
  const serviceUrl = (subdomain) => kombifyBase
    ? `https://${kombifyBase}-${subdomain}.kombify.me`
    : `https://${subdomain}.${domain}`;
  res.json({
    kit: { name: 'Base Homelab Kit', version: '1.0.0' },
    domain: kombifyBase ? `${kombifyBase}.kombify.me` : domain,
    nodeCount: 1,
    services: PORTAL_SERVICES.map(s => ({ ...s, url: serviceUrl(s.subdomain) })),
    config: {
      auth: 'TinyAuth + PocketID',
      paas: 'Dokploy',
      monitoring: 'Uptime Kuma',
      ingress: 'Traefik v3.3',
      tls: kombifyBase ? 'kombify.me (managed)' : domain.endsWith('.local') ? 'Self-signed' : "Let's Encrypt",
    },
  });
});

// GET /api/portal/health — live container health from VM Docker daemon
app.get('/api/portal/health', async (_req, res) => {
  try {
    // Connect to VM Docker daemon for container status
    const vmDocker = new Docker({ host: 'vm', port: 2375 });
    const containers = await vmDocker.listContainers({ all: true });
    const health = {};
    for (const svc of PORTAL_SERVICES) {
      const match = containers.find(c =>
        c.Names.some(n => n.replace('/', '').includes(svc.container))
      );
      if (match) {
        health[svc.name] = {
          state: match.State,
          health: match.Status.includes('healthy') ? 'healthy'
                : match.Status.includes('starting') ? 'starting'
                : match.State === 'running' ? 'running' : 'stopped',
          status: match.Status,
        };
      } else {
        health[svc.name] = { state: 'not_found', health: 'unknown', status: 'Not deployed' };
      }
    }
    res.json({ connected: true, services: health });
  } catch (e) {
    res.json({ connected: false, services: {}, error: e.message });
  }
});

// WebSocket: terminal into VM via docker exec
const wss = new WebSocketServer({ noServer: true });

server.on('upgrade', (req, socket, head) => {
  if (req.url === '/ws/terminal') {
    wss.handleUpgrade(req, socket, head, ws => wss.emit('connection', ws));
  } else {
    socket.destroy();
  }
});

wss.on('connection', async (ws) => {
  try {
    const container = docker.getContainer('stackkits-vm');
    const execInstance = await container.exec({
      Cmd: ['/bin/bash'],
      AttachStdin: true,
      AttachStdout: true,
      AttachStderr: true,
      Tty: true,
    });

    const stream = await execInstance.start({ hijack: true, stdin: true, Tty: true });

    // VM stdout → browser
    stream.on('data', chunk => {
      if (ws.readyState === ws.OPEN) {
        ws.send(JSON.stringify({ type: 'output', data: chunk.toString('utf-8') }));
      }
    });
    stream.on('end', () => ws.close());

    // Browser → VM stdin
    ws.on('message', raw => {
      try {
        const msg = JSON.parse(raw.toString());
        if (msg.type === 'input') stream.write(msg.data);
        if (msg.type === 'resize') execInstance.resize({ h: msg.rows, w: msg.cols }).catch(() => {});
      } catch { /* ignore parse errors */ }
    });

    ws.on('close', () => stream.destroy());
  } catch (e) {
    ws.send(JSON.stringify({ type: 'error', data: `VM connection failed: ${e.message}` }));
    ws.close();
  }
});

const PORT = process.env.PORT || 9000;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`Orchestrator: http://localhost:${PORT}`);
});
