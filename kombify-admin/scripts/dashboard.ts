/**
 * kombify-admin Dashboard Server
 *
 * Lightweight Express server for the tool evaluation admin UI.
 * Server-rendered HTML — no frontend build step needed.
 *
 * Usage:
 *   npx ts-node scripts/dashboard.ts
 *   # Open http://localhost:3400
 */

import { PrismaClient, LifecycleState, EvaluationState, LayerType } from '@prisma/client';
import * as http from 'http';
import * as url from 'url';

const prisma = new PrismaClient();
const PORT = parseInt(process.env.DASHBOARD_PORT || '3400');

// =============================================================================
// HTML HELPERS
// =============================================================================

function layout(title: string, content: string, nav?: string): string {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${title} — kombify Admin</title>
  <style>
    :root {
      --bg: #0f0f0f; --surface: #1a1a2e; --border: #2a2a3e;
      --text: #e0e0e0; --muted: #888; --accent: #7c3aed;
      --green: #22c55e; --yellow: #eab308; --red: #ef4444; --blue: #3b82f6;
    }
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: system-ui, -apple-system, sans-serif; background: var(--bg); color: var(--text); }
    a { color: var(--accent); text-decoration: none; }
    a:hover { text-decoration: underline; }

    .container { max-width: 1200px; margin: 0 auto; padding: 1rem; }
    header { background: var(--surface); border-bottom: 1px solid var(--border); padding: 0.75rem 0; margin-bottom: 1.5rem; }
    header .container { display: flex; align-items: center; gap: 2rem; }
    header h1 { font-size: 1.1rem; font-weight: 600; }
    nav { display: flex; gap: 1rem; }
    nav a { color: var(--muted); font-size: 0.9rem; padding: 0.25rem 0.5rem; border-radius: 4px; }
    nav a:hover, nav a.active { color: var(--text); background: var(--border); text-decoration: none; }

    .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 1rem; margin-bottom: 1.5rem; }
    .stat { background: var(--surface); border: 1px solid var(--border); border-radius: 8px; padding: 1rem; }
    .stat .label { font-size: 0.75rem; color: var(--muted); text-transform: uppercase; letter-spacing: 0.05em; }
    .stat .value { font-size: 1.5rem; font-weight: 700; margin-top: 0.25rem; }

    table { width: 100%; border-collapse: collapse; background: var(--surface); border-radius: 8px; overflow: hidden; }
    th { text-align: left; font-size: 0.75rem; color: var(--muted); text-transform: uppercase; letter-spacing: 0.05em; padding: 0.75rem 1rem; border-bottom: 1px solid var(--border); }
    td { padding: 0.75rem 1rem; border-bottom: 1px solid var(--border); font-size: 0.9rem; }
    tr:last-child td { border-bottom: none; }
    tr:hover { background: rgba(124, 58, 237, 0.05); }

    .badge { display: inline-block; padding: 0.15rem 0.5rem; border-radius: 9999px; font-size: 0.7rem; font-weight: 600; text-transform: uppercase; }
    .badge-green { background: rgba(34,197,94,0.15); color: var(--green); }
    .badge-yellow { background: rgba(234,179,8,0.15); color: var(--yellow); }
    .badge-red { background: rgba(239,68,68,0.15); color: var(--red); }
    .badge-blue { background: rgba(59,130,246,0.15); color: var(--blue); }
    .badge-muted { background: rgba(136,136,136,0.15); color: var(--muted); }

    .section { margin-bottom: 2rem; }
    .section h2 { font-size: 1rem; margin-bottom: 0.75rem; }

    .detail { background: var(--surface); border: 1px solid var(--border); border-radius: 8px; padding: 1.5rem; }
    .detail h2 { margin-bottom: 1rem; }
    .detail-grid { display: grid; grid-template-columns: 160px 1fr; gap: 0.5rem 1rem; }
    .detail-grid dt { color: var(--muted); font-size: 0.85rem; }
    .detail-grid dd { font-size: 0.9rem; }

    .empty { color: var(--muted); font-style: italic; padding: 2rem; text-align: center; }
  </style>
</head>
<body>
  <header>
    <div class="container">
      <h1>kombify Admin</h1>
      <nav>
        <a href="/" ${nav === 'home' ? 'class="active"' : ''}>Dashboard</a>
        <a href="/tools" ${nav === 'tools' ? 'class="active"' : ''}>Tools</a>
        <a href="/addons" ${nav === 'addons' ? 'class="active"' : ''}>Add-Ons</a>
        <a href="/contexts" ${nav === 'contexts' ? 'class="active"' : ''}>Contexts</a>
        <a href="/evaluations" ${nav === 'evaluations' ? 'class="active"' : ''}>Evaluations</a>
      </nav>
    </div>
  </header>
  <main class="container">
    ${content}
  </main>
</body>
</html>`;
}

function badge(state: string): string {
  const map: Record<string, string> = {
    APPROVED: 'badge-green', ACTIVE: 'badge-green', COMPLETED: 'badge-green',
    DRAFT: 'badge-yellow', PENDING: 'badge-yellow', IN_PROGRESS: 'badge-yellow', NEEDS_REVIEW: 'badge-yellow',
    DEPRECATED: 'badge-red', REJECTED: 'badge-red', NEEDS_REVISION: 'badge-red',
    CANDIDATE: 'badge-blue', DISCOVERED: 'badge-blue',
    ARCHIVED: 'badge-muted',
  };
  return `<span class="badge ${map[state] || 'badge-muted'}">${state}</span>`;
}

function esc(s: string | null | undefined): string {
  if (!s) return '';
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

// =============================================================================
// ROUTES
// =============================================================================

async function dashboardPage(): Promise<string> {
  const [toolCount, addOnCount, contextCount, evalCount] = await Promise.all([
    prisma.tool.count(),
    prisma.addOn.count(),
    prisma.contextDefaults.count(),
    prisma.toolEvaluation.count(),
  ]);

  const byState = await prisma.tool.groupBy({ by: ['lifecycleState'], _count: true });
  const byLayer = await prisma.stackKitTool.groupBy({ by: ['layer'], _count: true });

  const pendingEvals = await prisma.toolEvaluation.count({
    where: { state: { in: ['PENDING', 'IN_PROGRESS', 'NEEDS_REVIEW'] } },
  });

  const recentTools = await prisma.tool.findMany({
    orderBy: { updatedAt: 'desc' },
    take: 10,
    include: { stackKitTool: true },
  });

  const stateStats = byState.map(s =>
    `<div class="stat"><div class="label">${s.lifecycleState}</div><div class="value">${s._count}</div></div>`
  ).join('');

  const layerStats = byLayer.map(l =>
    `<div class="stat"><div class="label">${l.layer}</div><div class="value">${l._count}</div></div>`
  ).join('');

  const toolRows = recentTools.map(t => `
    <tr>
      <td><a href="/tools/${esc(t.id)}">${esc(t.displayName || t.name)}</a></td>
      <td>${esc(t.category)}</td>
      <td>${badge(t.lifecycleState)}</td>
      <td>${t.stackKitTool?.layer || '—'}</td>
      <td>${t.updatedAt.toISOString().split('T')[0]}</td>
    </tr>
  `).join('');

  return layout('Dashboard', `
    <div class="stats">
      <div class="stat"><div class="label">Total Tools</div><div class="value">${toolCount}</div></div>
      <div class="stat"><div class="label">Add-Ons</div><div class="value">${addOnCount}</div></div>
      <div class="stat"><div class="label">Contexts</div><div class="value">${contextCount}</div></div>
      <div class="stat"><div class="label">Pending Evaluations</div><div class="value">${pendingEvals}</div></div>
    </div>

    <div class="section">
      <h2>Tools by Lifecycle State</h2>
      <div class="stats">${stateStats}</div>
    </div>

    <div class="section">
      <h2>Tools by Layer</h2>
      <div class="stats">${layerStats}</div>
    </div>

    <div class="section">
      <h2>Recently Updated Tools</h2>
      <table>
        <thead><tr><th>Name</th><th>Category</th><th>State</th><th>Layer</th><th>Updated</th></tr></thead>
        <tbody>${toolRows || '<tr><td colspan="5" class="empty">No tools found. Run npm run db:seed first.</td></tr>'}</tbody>
      </table>
    </div>
  `, 'home');
}

async function toolsPage(query: Record<string, string>): Promise<string> {
  const where: any = {};
  if (query.state) where.lifecycleState = query.state as LifecycleState;
  if (query.category) where.category = query.category;
  if (query.search) where.OR = [
    { name: { contains: query.search, mode: 'insensitive' } },
    { displayName: { contains: query.search, mode: 'insensitive' } },
  ];

  const tools = await prisma.tool.findMany({
    where,
    orderBy: { displayName: 'asc' },
    include: { stackKitTool: true },
    take: 100,
  });

  const categories = await prisma.tool.groupBy({ by: ['category'], _count: true, orderBy: { category: 'asc' } });

  const filterLinks = ['ALL', 'DISCOVERED', 'CANDIDATE', 'APPROVED', 'DEPRECATED'].map(s =>
    `<a href="/tools${s === 'ALL' ? '' : '?state=' + s}" ${query.state === s ? 'class="active"' : ''}>${s}</a>`
  ).join(' ');

  const categoryLinks = categories.map(c =>
    `<a href="/tools?category=${esc(c.category)}" ${query.category === c.category ? 'class="active"' : ''}>${esc(c.category)} (${c._count})</a>`
  ).join(' ');

  const rows = tools.map(t => `
    <tr>
      <td><a href="/tools/${esc(t.id)}">${esc(t.displayName || t.name)}</a></td>
      <td>${esc(t.category)}</td>
      <td>${badge(t.lifecycleState)}</td>
      <td>${t.stackKitTool?.layer || '—'}</td>
      <td>${t.versions?.[0] || '—'}</td>
      <td>${t.dockerImage || '—'}</td>
    </tr>
  `).join('');

  return layout('Tools', `
    <div class="section">
      <h2>Filter by State</h2>
      <nav>${filterLinks}</nav>
    </div>
    <div class="section">
      <h2>Filter by Category</h2>
      <nav style="flex-wrap: wrap;">${categoryLinks}</nav>
    </div>
    <div class="section">
      <h2>Tools (${tools.length})</h2>
      <table>
        <thead><tr><th>Name</th><th>Category</th><th>State</th><th>Layer</th><th>Version</th><th>Image</th></tr></thead>
        <tbody>${rows || '<tr><td colspan="6" class="empty">No tools match filters.</td></tr>'}</tbody>
      </table>
    </div>
  `, 'tools');
}

async function toolDetailPage(id: string): Promise<string> {
  const tool = await prisma.tool.findUnique({
    where: { id },
    include: {
      stackKitTool: true,
      evaluations: { orderBy: { createdAt: 'desc' }, take: 5 },
    },
  });

  if (!tool) return layout('Not Found', '<p class="empty">Tool not found.</p>');

  const evalRows = tool.evaluations.map((e: any) => `
    <tr>
      <td>${badge(e.state)}</td>
      <td>${e.verdict || '—'}</td>
      <td>${e.evaluatedBy || '—'}</td>
      <td>${e.createdAt.toISOString().split('T')[0]}</td>
    </tr>
  `).join('');

  const tags = (tool.tags as string[] || []).map((t: string) => `<span class="badge badge-muted">${esc(t)}</span>`).join(' ');
  const altTools = (tool.alternativeTools as string[] || []).join(', ') || '—';

  return layout(tool.displayName || tool.name, `
    <div class="detail">
      <h2>${esc(tool.displayName || tool.name)} ${badge(tool.lifecycleState)}</h2>
      <dl class="detail-grid">
        <dt>Name</dt><dd>${esc(tool.name)}</dd>
        <dt>Category</dt><dd>${esc(tool.category)}</dd>
        <dt>Layer</dt><dd>${tool.stackKitTool?.layer || '—'}</dd>
        <dt>Docker Image</dt><dd>${esc(tool.dockerImage) || '—'}</dd>
        <dt>Versions</dt><dd>${(tool.versions as string[] || []).join(', ') || '—'}</dd>
        <dt>Website</dt><dd>${tool.websiteUrl ? `<a href="${esc(tool.websiteUrl)}" target="_blank">${esc(tool.websiteUrl)}</a>` : '—'}</dd>
        <dt>GitHub</dt><dd>${tool.githubUrl ? `<a href="${esc(tool.githubUrl)}" target="_blank">${esc(tool.githubUrl)}</a>` : '—'}</dd>
        <dt>Tags</dt><dd>${tags || '—'}</dd>
        <dt>Alternatives</dt><dd>${esc(altTools)}</dd>
        <dt>Description</dt><dd>${esc(tool.description)}</dd>
      </dl>
    </div>

    <div class="section" style="margin-top: 1.5rem;">
      <h2>Evaluations</h2>
      <table>
        <thead><tr><th>State</th><th>Verdict</th><th>Evaluator</th><th>Date</th></tr></thead>
        <tbody>${evalRows || '<tr><td colspan="4" class="empty">No evaluations yet.</td></tr>'}</tbody>
      </table>
    </div>

    <p style="margin-top: 1rem;"><a href="/tools">&larr; Back to tools</a></p>
  `, 'tools');
}

async function addonsPage(): Promise<string> {
  const addons = await prisma.addOn.findMany({ orderBy: { displayName: 'asc' } });

  const rows = addons.map(a => `
    <tr>
      <td>${esc(a.displayName)}</td>
      <td>${esc(a.name)}</td>
      <td>${esc(a.category)}</td>
      <td>${badge(a.lifecycleState)}</td>
      <td>${a.autoActivate ? '<span class="badge badge-green">Auto</span>' : '<span class="badge badge-muted">Manual</span>'}</td>
      <td>${(a.compatibleKits as string[] || []).join(', ')}</td>
    </tr>
  `).join('');

  return layout('Add-Ons', `
    <div class="section">
      <h2>Add-Ons (${addons.length})</h2>
      <table>
        <thead><tr><th>Name</th><th>Slug</th><th>Category</th><th>State</th><th>Activation</th><th>Compatible Kits</th></tr></thead>
        <tbody>${rows || '<tr><td colspan="6" class="empty">No add-ons found.</td></tr>'}</tbody>
      </table>
    </div>
  `, 'addons');
}

async function contextsPage(): Promise<string> {
  const contexts = await prisma.contextDefaults.findMany({ orderBy: { name: 'asc' } });

  const rows = contexts.map(c => `
    <tr>
      <td>${esc(c.displayName)}</td>
      <td>${esc(c.name)}</td>
      <td>${esc(c.nodeContext)}</td>
      <td>${(c.targetKits as string[] || []).join(', ')}</td>
      <td>${c.minMemoryMB ? c.minMemoryMB + ' MB' : '—'}</td>
    </tr>
  `).join('');

  return layout('Contexts', `
    <div class="section">
      <h2>Context Defaults (${contexts.length})</h2>
      <table>
        <thead><tr><th>Name</th><th>Slug</th><th>Node Context</th><th>Target Kits</th><th>Min Memory</th></tr></thead>
        <tbody>${rows || '<tr><td colspan="5" class="empty">No contexts found.</td></tr>'}</tbody>
      </table>
    </div>
  `, 'contexts');
}

async function evaluationsPage(): Promise<string> {
  const evals = await prisma.toolEvaluation.findMany({
    orderBy: { createdAt: 'desc' },
    take: 50,
    include: { tool: true },
  });

  const byState = await prisma.toolEvaluation.groupBy({ by: ['state'], _count: true });
  const stateStats = byState.map(s =>
    `<div class="stat"><div class="label">${s.state}</div><div class="value">${s._count}</div></div>`
  ).join('');

  const rows = evals.map(e => `
    <tr>
      <td><a href="/tools/${esc(e.toolId)}">${esc(e.tool.displayName || e.tool.name)}</a></td>
      <td>${badge(e.state)}</td>
      <td>${e.verdict ? badge(e.verdict) : '—'}</td>
      <td>${e.evaluatedBy || '—'}</td>
      <td>${e.createdAt.toISOString().split('T')[0]}</td>
    </tr>
  `).join('');

  return layout('Evaluations', `
    <div class="stats">${stateStats}</div>
    <div class="section">
      <h2>Recent Evaluations (${evals.length})</h2>
      <table>
        <thead><tr><th>Tool</th><th>State</th><th>Verdict</th><th>Evaluator</th><th>Date</th></tr></thead>
        <tbody>${rows || '<tr><td colspan="5" class="empty">No evaluations found.</td></tr>'}</tbody>
      </table>
    </div>
  `, 'evaluations');
}

// =============================================================================
// HTTP SERVER
// =============================================================================

const server = http.createServer(async (req, res) => {
  const parsed = url.parse(req.url || '/', true);
  const path = parsed.pathname || '/';
  const query = parsed.query as Record<string, string>;

  try {
    let html: string;

    if (path === '/') {
      html = await dashboardPage();
    } else if (path === '/tools' && !path.includes('/tools/')) {
      html = await toolsPage(query);
    } else if (path.startsWith('/tools/')) {
      const id = path.replace('/tools/', '');
      html = await toolDetailPage(id);
    } else if (path === '/addons') {
      html = await addonsPage();
    } else if (path === '/contexts') {
      html = await contextsPage();
    } else if (path === '/evaluations') {
      html = await evaluationsPage();
    } else {
      res.writeHead(404);
      res.end('Not found');
      return;
    }

    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    res.end(html);
  } catch (err: any) {
    console.error('Dashboard error:', err);
    res.writeHead(500);
    res.end(`<pre>Error: ${err.message}</pre>`);
  }
});

server.listen(PORT, () => {
  console.log(`\n  kombify Admin Dashboard`);
  console.log(`  http://localhost:${PORT}\n`);
  console.log(`  Pages:`);
  console.log(`    /           Dashboard overview`);
  console.log(`    /tools      Tool catalog (filter by state, category)`);
  console.log(`    /tools/:id  Tool detail view`);
  console.log(`    /addons     Add-on registry`);
  console.log(`    /contexts   Context defaults`);
  console.log(`    /evaluations  Evaluation queue\n`);
});

process.on('SIGINT', async () => {
  await prisma.$disconnect();
  process.exit(0);
});
