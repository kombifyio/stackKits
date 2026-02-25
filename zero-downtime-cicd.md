kombify Zero-Downtime CI/CD & Fallback-Architektur
Context
kombify.io hat wiederholt Downtime durch fehlerhafte AFD-Konfigurationen, veraltete ACR-Images und fehlende Fallbacks. AFD wurde als Notfall zurückgesetzt -- aktuell zeigt eine einzelne simple AFD-Regel auf einen Backup-Container. Ziel: ein robustes, einheitliches Deployment-System mit automatisierten Fallbacks auf jeder Ebene, das zu keinem Zeitpunkt Downtime verursacht.

IST-Zustand
AFD aktiv, aber simplifiziert: eine Regel zeigt auf einen Backup-Container
Vorherige komplexe AFD-Regeln wurden gelöscht
DNS bleibt bei Spaceship (Cloudflare langfristig geplant)
VPS (srv1161760) läuft mit Traefik, aber nicht als aktiver Standby synchronisiert
Azure PostgreSQL (psql-kombify-prod) als zentrale DB
Prioritäten
Prio	Services
P0 - Sofort	kombify.io, api.kombify.io, kombify-DB (Azure PostgreSQL)
P1 - Danach	techstack.kombify.io, stack.kombify.io, simulate.kombify.io, sim.kombify.io
P2 - Später	admin.kombify.io, stackkits.kombify.io, Blog, Docs
Architektur: 5-Schicht-Fallback

Schicht 1: DNS        *.kombify.io → AFD  (langfristig: Cloudflare mit Health-Failover)
Schicht 2: Routing    AFD Origin Group: ACA Primary (Prio 1) + VPS/Traefik (Prio 2)
Schicht 3: Container  Blue-Green Revisions + last-known-good Revision bleibt aktiv
Schicht 4: Registry   Jeder Build → ACR + GHCR parallel (SHA-tagged)
Schicht 5: Runner     Self-Hosted → GitHub-Hosted Fallback (Org-Variable)
Kernprinzip: Wenn eine Schicht versagt, fängt die nächste automatisch auf. Kein manuelles Eingreifen nötig.

Phase 0: Sofort-Stabilisierung (P0-Services, kein Prod-Risiko)
0.1 VPS als Hot-Standby verifizieren
SSH auf srv1161760, prüfen welche Services laufen
kombify.io und api.kombify.io müssen über VPS erreichbar sein
Fehlende Services deployen aus bestehenden deploy/docker-compose.prod.yml
Test: curl -H "Host: kombify.io" http://72.62.49.6 muss korrekten Content liefern
0.2 Health-Monitor Workflow
Neue Datei: .github/.github/workflows/health-monitor.yml
Cron */5 * * * *, prüft P0+P1 Subdomains
Checks: HTTP-Status, Content-Type, Body enthält "kombify"
Bei Ausfall: GitHub Issue mit health-alert Label
Kein automatischer Failover in Phase 0 -- nur Alerting
0.3 Version-Endpoint
Jeder Service bekommt DEPLOY_SHA als Env-Var (gesetzt bei Deploy)
Health-Endpoint gibt Version zurück: {"status":"healthy","version":"sha-abc1234"}
Ermöglicht: Verification prüft ob der RICHTIGE Code läuft, nicht ein gecachter/alter Container
Phase 1: AFD Dual-Origin (additiv, Failover zu VPS)
1.1 Bicep-Modul erweitern
Datei: kombify Core/infra/bicep/modules/afd-route.bicep

Neuer optionaler Parameter:


param fallbackOriginHostName string = ''
Neue Ressource (nur wenn fallbackOriginHostName gesetzt):


resource fallbackOrigin ... {
  parent: originGroup
  name: 'origin-${routeName}-fallback'
  properties: {
    hostName: fallbackOriginHostName
    originHostHeader: customDomainHostName  // SNI auf die richtige Domain
    priority: 2        // Nur wenn Primary (Prio 1) down ist
    weight: 1
    enabledState: 'Enabled'
  }
}
1.2 main.bicep: VPS für alle Routes
Datei: kombify Core/infra/bicep/main.bicep


var vpsOriginHost = '72.62.49.6'  // srv1161760

var routes = [
  { name: 'portal', hostname: 'kombify.io', ..., fallbackHost: vpsOriginHost }
  { name: 'api', hostname: 'api.kombify.io', ..., fallbackHost: vpsOriginHost }
  // ... alle Routes mit fallbackHost
]
1.3 AFD Drift-Detection
Neue Datei: kombify Core/.github/workflows/afd-drift-check.yml

Cron alle 6h
az afd origin list / az afd route list gegen erwarteten Bicep-Zustand prüfen
Bei Drift: Issue erstellen
1.4 Deployment & Validation

az deployment group create -g rg-kombify-prod -f infra/bicep/main.bicep \
  --parameters containerAppsEnvFqdn=<cae-fqdn>
Validierung: az afd origin list zeigt 2 Origins pro Gruppe
Test: Primary Origin manuell deaktivieren → Traffic geht zu VPS → keine Downtime
Phase 2: Dual-Registry (ACR + GHCR)
2.1 build-and-push.yml erweitern
Datei: .github/.github/workflows/build-and-push.yml

Neue Inputs:


push-to-acr:
  type: boolean
  default: true
acr-name:
  type: string
  default: 'acrkombifyprod'
Neue Secrets: ACR_USERNAME, ACR_PASSWORD

Nach dem GHCR-Push: ACR Login + Cross-Registry-Tag via docker buildx imagetools create

2.2 Image-Retention
docker image prune -f aus deploy-vps-ssh.yml (Zeile 147) entfernen
Stattdessen: letzte 5 Images behalten, ältere entfernen
ACR: Retention-Policy für untagged Manifests (30 Tage)
Nie :latest pushen ohne gleichzeitigen SHA-Tag
Phase 3: Blue-Green + Erweiterte Verification
3.1 deploy-azure.yml erweitern
Datei: .github/.github/workflows/deploy-azure.yml

Die bestehende Rollback-Logik (Zeile 98-106, 165-173) ist gut. Erweitern:

Verification statt nur HTTP-200:


# L1: HTTP erreichbar
STATUS=$(curl -sLf -o /dev/null -w "%{http_code}" "$URL" --max-time 10)
[ "$STATUS" -lt 400 ] || exit 1

# L2: Content-Type korrekt
CT=$(curl -sI "$URL" | grep -i content-type)
echo "$CT" | grep -qi "$EXPECTED_CT" || exit 1

# L3: Content enthält erwarteten String
BODY=$(curl -sLf "$URL" --max-time 10)
echo "$BODY" | grep -qi "$EXPECTED_CONTENT" || exit 1

# L4: Version-Endpoint gibt deployed SHA zurück
if [ -n "$VERSION_ENDPOINT" ]; then
  VER=$(curl -sf "${URL}${VERSION_ENDPOINT}" --max-time 10 | jq -r '.version // empty')
  [ "$VER" = "$DEPLOYED_SHA" ] || exit 1
fi
Neue Inputs: expected-content-type, expected-content, version-endpoint

3.2 Verification als Composite Action
Neue Datei: .github/actions/verify-deployment/action.yml

Wiederverwendbar in deploy-azure, deploy-vps, health-monitor
Inputs: url, expected-status, expected-content-type, expected-content, version-sha
Phase 4: Unified Pipeline
4.1 Neuer Reusable Workflow
Neue Datei: .github/.github/workflows/kombify-deploy.yml


Pipeline-Flow:
  1. CI Gate    → gh api: prüft ob CI-Checks auf dem Commit grün sind
  2. Build      → calls build-and-push.yml (→ GHCR + ACR)
  3. Deploy ACA → calls deploy-azure.yml (mit erweiterter Verification)
  4. Verify     → verify-deployment Action (L1-L4)
  5. Mirror VPS → calls deploy-vps-ssh.yml (gleicher SHA-Tag)
  6. Verify VPS → verify-deployment gegen VPS
  7. Summary    → GitHub Step Summary + Issue bei Failure
Inputs pro Repo:


service-name, container-app-name, acr-image,
health-endpoint, expected-content, version-endpoint,
vps-compose-file, doppler-project
4.2 Per-Repo: dünner Workflow-Call
Jedes Repo ersetzt deploy-production.yml durch:


name: Deploy
on:
  push: { branches: [main] }
  workflow_dispatch:
jobs:
  deploy:
    uses: KombiverseLabs/.github/.github/workflows/kombify-deploy.yml@main
    with:
      service-name: kombify-stack
      container-app-name: ca-kombify-stack-prod
      acr-image: kombistack
      health-endpoint: /api/v1/health
      expected-content: kombify
      vps-compose-file: deploy/docker-compose.prod.yml
      doppler-project: kombify-stack
    secrets: inherit
4.3 Migrations-Reihenfolge
P0 zuerst:

kombify Core (kombify.io)
kombify-API / Kong (api.kombify.io)
P1 danach:
3. kombify Stack (techstack.kombify.io + stack.kombify.io)
4. kombify Sim (simulate.kombify.io + sim.kombify.io)

P2 zuletzt:
5. kombify Administration, StackKits, Blog
6. kombify Cloud (app.kombify.io)

Jede Migration = 1 PR pro Repo (Workflow-Datei ersetzen). Kein Big-Bang.

Phase 5: Automatischer Failover & Cloudflare (langfristig)
5.1 AFD-basierter Auto-Failover (kurzfristig)
Health-Monitor nach 3x Failure (15 Min): az afd origin update → Primary deaktivieren
AFD routet automatisch zu VPS Fallback Origin
Recovery: Fix deployen → Verification grün → Primary reaktivieren
5.2 DNS zu Cloudflare migrieren (langfristig)
Cloudflare Load Balancing mit Health Checks
Pool 1: AFD Endpoint (Primary)
Pool 2: VPS IP (Fallback)
Automatischer DNS-Level-Failover in <30 Sekunden
Unabhängig von AFD-Health-Probes
5.3 Recovery Runbook
Neue Datei: kombify Core/docs/RECOVERY_RUNBOOK.md

Dateien-Übersicht
Datei	Aktion	Phase
.github/.github/workflows/health-monitor.yml	NEU	0
.github/.github/workflows/build-and-push.yml	ERWEITERN	2
.github/.github/workflows/deploy-azure.yml	ERWEITERN	3
.github/.github/workflows/deploy-vps-ssh.yml	FIX (kein prune)	2
.github/.github/workflows/kombify-deploy.yml	NEU	4
.github/actions/verify-deployment/action.yml	NEU	3
kombify Core/infra/bicep/modules/afd-route.bicep	ERWEITERN	1
kombify Core/infra/bicep/main.bicep	ERWEITERN	1
kombify Core/.github/workflows/afd-drift-check.yml	NEU	1
kombify Core/docs/RECOVERY_RUNBOOK.md	NEU	5
Pro Repo: deploy-production.yml	ERSETZEN	4
Pro Repo: Health-Endpoint	ERWEITERN	0
Verification pro Phase
Phase	Test
0	curl -H "Host: kombify.io" http://72.62.49.6 liefert korrekten Content
1	az afd origin list zeigt 2 Origins; Primary deaktivieren → VPS übernimmt
2	Nach Push: az acr repository show-tags + GHCR zeigen gleichen SHA
3	Kaputten Container deployen → auto-Rollback → Site bleibt erreichbar
4	Kompletter Deploy durch neue Pipeline → alle Steps grün
5	AFD Primary deaktivieren → Health-Monitor erkennt → auto-Failover → 0 Downtime
Chaos-Test (nach Phase 5):
ACR unzugänglich + ACA Container killen → AFD failovert zu VPS → VPS bedient aus GHCR → kein User merkt etwas.