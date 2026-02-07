# kombify StackKits — Roadmap

**Stand**: 2026-02-07  
**Version**: v1.0  
**Scope**: StackKits + Cross-Repo Konsistenz + Docs + Beyond-IaC

---

## Konsistenz-Audit (Cross-Repo Befunde)

Vor der Roadmap-Planung wurde ein vollstandiges Konsistenz-Audit uber alle 4 Repositories durchgefuhrt (StackKits, kombify Stack, kombify Core, docs). Die folgenden Befunde fliessen direkt in die Meilensteine ein.

### Kritische Inkonsistenzen

| # | Befund | Betroffene Repos | Schwere |
|---|--------|-------------------|---------|
| K1 | **Kubernetes-Referenzen in Docs** — concepts/stackkits.mdx, stackkits-system.mdx, stackkits/overview.mdx, stackkits/kits/modern-homelab.mdx beschreiben K8s/k3s obwohl K8s aus dem Code entfernt wurde | docs | Hoch |
| K2 | **Lizenz-Chaos** — ecosystem.mdx sagt "Apache 2.0 + GPLv3", introduction.mdx sagt "MIT + AGPL-3.0", README-Badges sagen verschiedenes, Code sagt jetzt Apache 2.0 | docs, StackKits, Stack | Hoch |
| K3 | **Naming-Inkonsistenz** — "kombifyStack", "KombiStack", "kombify Stack", "kombifySim", "KombiSim", "kombify Sim", "KombiSphere", "kombify Cloud" — 4+ Varianten pro Tool | alle | Hoch |
| K4 | **Doppelte Concept-Pages** — stackkits.mdx + stackkits-system.mdx + stackkits-explained.mdx (3x gleicher Inhalt), spec-driven.mdx + spec-driven-architecture.mdx (2x) | docs | Mittel |
| K5 | **ha-homelab Beschreibung** — Docs sagen "Kubernetes (k3s)", Code ist Docker Swarm | docs | Hoch |
| K6 | **modern-homelab.mdx** — 591 Zeilen komplett uber K8s/k3s/FluxCD/Longhorn, alles veraltet | docs | Hoch |
| K7 | **GitHub Org-Referenzen** — kombify, kombifyLabs, Soulcreek, kombihq — 4 verschiedene Orgs | docs, Stack | Mittel |
| K8 | **URL-Casing** — /Cloud/overview (gross) vs /cloud/overview (klein) gemischt | docs | Niedrig |
| K9 | **Veraltete Service-Referenzen** — "Authelia", "Portainer" als Defaults statt "TinyAuth", "Dokploy" | docs | Mittel |
| K10 | **"Terraform" statt "OpenTofu"** in Marketing-Seite | StackKits | Mittel |
| K11 | **Leere Core README** — kombify Core README.md hat keinen Inhalt | Core | Niedrig |
| K12 | **Beyond-IaC nicht in Docs** — Kernkonzept (gRPC Agents, AI Self-Healing, Integration Paths) fehlt komplett in der oeffentlichen Doku | docs | Hoch |
| K13 | **Add-On-System nicht in Docs** — Weder Konzept noch Schema beschrieben | docs | Mittel |
| K14 | **Persona-System nicht in Docs** — Wizard-Entscheidungsbaum fehlt | docs | Mittel |
| K15 | **Local/Cloud-Split nicht in Docs** — Backend-Differenzierung nicht dokumentiert | docs | Mittel |

---

## Meilensteine

### M0: Hygiene & Konsistenz (Sofort — 1-2 Wochen)

**Ziel**: Saubere Ausgangsbasis schaffen. Alle Repos sprechen die gleiche Sprache.

**StackKits-Repo**:
- [ ] Package-Naming vereinheitlichen: `devhomelab` -> `dev_homelab`
- [ ] `modern-homelab/stackkit.cue` -> `stackfile.cue` umbenennen
- [ ] `default-spec.yaml` Labels von `kombistack` auf `stackkit` aktualisieren
- [ ] `stack-spec.yaml` Schema-Referenz aktualisieren
- [ ] Doppelte Schema-Definitionen bereinigen (`base/layers.cue` vs `base/platform/identity.cue`)
- [ ] dev-homelab `platforms/docker` Import-Problem beheben

**Docs-Repo**:
- [ ] Alle Kubernetes-Referenzen aus Docs entfernen (K1, K5, K6)
- [ ] Lizenz uberall auf Apache 2.0 vereinheitlichen (K2)
- [ ] Naming-Standard durchsetzen: "kombify Stack", "kombify Sim", "kombify StackKits", "kombify Cloud" (K3)
- [ ] Doppelte Concept-Pages konsolidieren (K4): stackkits-system.mdx + stackkits-explained.mdx entfernen, nur stackkits.mdx behalten; spec-driven-architecture.mdx entfernen
- [ ] URL-Casing fixen: /Cloud/ -> /cloud/ uberall (K8)
- [ ] Veraltete Service-Namen ersetzen: Authelia -> TinyAuth/PocketID, Portainer -> Dokploy (K9)
- [ ] GitHub-Org-Referenzen vereinheitlichen auf "kombify" (K7)
- [ ] modern-homelab.mdx komplett umschreiben (Multi-Node Docker, nicht K8s)
- [ ] ha-homelab.mdx aktualisieren (Docker Swarm statt K8s)

**Alle Repos**:
- [ ] README-Badges auf Apache 2.0 aktualisieren
- [ ] GitHub-Referenzen auf einheitliche Org normalisieren

**Fertig-Kriterium**: `mintlify dev` zeigt keine toten Links, keine K8s-Referenzen, konsistente Naming.

---

### M1: Core IaC Pipeline (2-4 Wochen)

**Ziel**: CUE-Schemas werden tatsachlich ausfuhrbar. base-homelab ist end-to-end deploybar.

- [ ] CUE-als-SSoT implementieren: CUE validiert + exportiert `tfvars.json` (statt Template-Rendering)
- [ ] OpenTofu-Module statt Monolith-Templates: `main.tf` (1130 Zeilen) in Module aufteilen (traefik, dokploy, monitoring, identity)
- [ ] `bridge.go` Rewrite: CUE-Export -> tfvars.json Pipeline sauber implementieren
- [ ] base-homelab default-Variante end-to-end testbar machen (validate -> generate -> plan -> apply)
- [ ] CI/CD Pipeline aufsetzen (GitHub Actions): `cue vet ./...`, Go-Tests, Lint bei jedem Push
- [ ] JSON-Schema-Export fur IDE-Support (`cue export --schema`)
- [ ] `base.#Layer3Applications.services` Constraint fixen (Array vs Map Widerspruch W2)
- [ ] Port-Kollisions-Erkennung als CUE-Constraint implementieren (D8)
- [ ] Service-Dependency-Validation implementieren (D6)

**Fertig-Kriterium**: `stackkit validate && stackkit generate && stackkit plan` funktioniert fur base-homelab default-Variante.

---

### M2: Backend-Split & Varianten (2-3 Wochen)

**Ziel**: base-homelab unterscheidet sauber zwischen Local und Cloud. Alle 4 Service-Varianten funktionieren.

- [ ] Backend-Split implementieren: `base-homelab-local` vs `base-homelab-cloud` CUE-Schemas
- [ ] `#NodeDefinition.type` Erweiterung: `"local" | "cloud"` mit unterschiedlichen SSH-Defaults
- [ ] Cloud-Provider-Abstraktion: Hetzner-Modul als erstes Cloud-Backend
- [ ] VPN-Bridging Schema fur Hybrid-Setups (Local + Cloud Nodes via Headscale/WireGuard)
- [ ] Alle 4 Varianten (default, beszel, minimal, coolify) ausfuhrbar machen
- [ ] PAAS-Layer-Zuordnung klaren (W3): Explizite CUE-Constraints statt Label-basiert
- [ ] Label-Naming vereinheitlichen (W4): `stackkit.layer` als Standard
- [ ] Compute-Tier-basierte Service-Auswahl testen und dokumentieren

**Fertig-Kriterium**: `stackkit apply` funktioniert mit `--backend local` und `--backend cloud` fur alle Varianten.

---

### M3: StackKit-Reife (3-4 Wochen)

**Ziel**: Alle 4 StackKits sind mindestens Schema-komplett. ha-homelab und dev-homelab produktionsreif.

**dev-homelab**:
- [ ] Import-Problem mit `platforms/docker` beheben
- [ ] Schema-Tests schreiben (analog zu base-homelab)
- [ ] Templates erstellen (Docker Compose + OpenTofu)
- [ ] E2E-Test ausfuhrbar machen

**ha-homelab** (Docker Swarm):
- [ ] Schema vervollstandigen: `#DockerSwarmService`, `#TraefikHA`, `#GlusterFS`, `#Restic` fertigstellen
- [ ] Quorum-Validation (Ungerade Manager-Anzahl) ausfuhrbar testen
- [ ] OpenTofu-Templates fur Multi-Node Swarm erstellen
- [ ] Failover-Mechanismus definieren (Keepalived/VRRP)

**modern-homelab** (Neukonzeption — KEIN Kubernetes):
- [ ] Konzept neu definieren: Multi-Node Docker + Coolify/Headscale + Full Observability (PLG-Stack)
- [ ] CUE-Schema umschreiben (K8s raus, Docker multi-node rein)
- [ ] VPN-Overlay (Headscale) als Kern-Feature integrieren
- [ ] Differenzierung zu ha-homelab klar definieren

**Ubergreifend**:
- [ ] Maturity-Badges pro StackKit einfuhren (stable / beta / planned)
- [ ] Beispiel-`kombination.yaml` pro Variante bereitstellen
- [ ] Unit-Tests fur `internal/`-Packages (cue, tofu, ssh)

**Fertig-Kriterium**: Jeder StackKit hat mindestens 80% Schema-Coverage und mindestens 1 deploybare Variante.

---

### M4: CUE-Entscheidungslogiken (2-3 Wochen)

**Ziel**: Die 14 fehlenden CUE-Entscheidungslogiken (D1-D14) sind implementiert.

**Prio A (Blockieren korrekte Deployments)**:
- [ ] D1: Network-Mode-Decision (local -> Bridge, public -> Traefik+ACME, hybrid -> VPN+Split-DNS)
- [ ] D2: PAAS-Auto-Selection (lokale Domain -> Dokploy, public -> Coolify)
- [ ] D4: Firewall-Port-Auto-Generation (aus services[*].network.ports)
- [ ] D9: TLS-ACME-Domain-Constraint (acme + .local = Fehler)
- [ ] D14: Container-Image-Version-Policy (kein "latest" in Production)

**Prio B (Verbessern Sicherheit/Stabilitat)**:
- [ ] D3: Identity-Provider-Cascade (zeroTrust -> TinyAuth ODER PocketID muss aktiv sein)
- [ ] D5: Volume-Backup-Filter (automatisch aus volumes[backup==true])
- [ ] D7: Resource-Budget-Validation (Summe services RAM <= Node RAM)
- [ ] D8: Port-Collision-Detection (doppelte Host-Ports erkennen)
- [ ] D10: Node-Count-Platform-Constraint (docker-swarm -> min. 3 Nodes)

**Prio C (Erweiterte Logik)**:
- [ ] D6: Service-Dependency-Validation (needs[] referenziert existierenden Service)
- [ ] D11: Variant-Feature-Matrix (CUE-Logik statt manuelle Tests)
- [ ] D12: Upgrade-Path-Validation (erlaubte Varianten-Wechsel)
- [ ] D13: mTLS-Service-Policy (StepCAMTLSPolicy enforced)

**Fertig-Kriterium**: `cue vet ./...` pruft alle Constraints. Fehlerhafte Konfigurationen werden mit klaren Meldungen abgelehnt.

---

### M5: Terramate & Day-2 Ops (2-3 Wochen)

**Ziel**: Terramate ist in die CLI integriert. Drift Detection funktioniert.

- [ ] Terramate-Integration in `cmd/stackkit/` CLI: `stackkit drift` Command
- [ ] Terramate Change-Detection: `terramate run --changed` Workflow
- [ ] Terramate Stack-Tags fur Layer-Zuordnung (`stack.tags = ["layer:1", "identity"]`)
- [ ] Drift-Detection als Scheduled Run (Terramate + CUE-Health-Check-Vergleich)
- [ ] OpenTofu State-Backend-Strategie: S3 fur Prod, lokal fur Dev, per Variant wahlbar
- [ ] OpenTofu Provider-Locking (`.terraform.lock.hcl` committen)
- [ ] CUE-Schema-Versionierung einfuhren (Schema-Kompatibilitat sichern)

**Fertig-Kriterium**: `stackkit drift --check` erkennt Abweichungen zwischen gewunschtem und tatsachlichem State.

---

### M6: Add-On-System v1 (2-3 Wochen)

**Ziel**: Add-Ons konnen definiert, validiert und deployit werden.

- [ ] CUE-Schema fur `#AddOn` definieren (Name, Typ, Abhangigkeiten, Varianten-Kompatibilitat)
- [ ] Add-On-Typen implementieren: Hardware (gpu, arm, low-memory), Tool (custom services), Multi-Server
- [ ] Auto-Detection Add-Ons: `cloud-integration`, `arm-support`, `gpu-workloads`, `low-memory`
- [ ] Add-On-Interaktion mit Varianten spezifizieren (Welche Add-Ons mit welchen Varianten?)
- [ ] Add-On-Runtime-Schema: `#AddOnRuntime` mit Lifecycle-Hooks (preInstall, postInstall, healthCheck)
- [ ] Add-On Registry Konzept (lokale Add-Ons vs Community-Add-Ons)
- [ ] Docs: Add-On-System in Mintlify dokumentieren

**Fertig-Kriterium**: Mindestens 3 Add-Ons (arm-support, multi-server, gpu-workloads) sind als CUE-Schema definiert und konnen uber CLI aktiviert werden.

---

### M7: Beyond-IaC Foundation (3-4 Wochen)

**Ziel**: Der Runtime Intelligence Layer hat eine funktionierende Grundlage.

**gRPC Agent Integration**:
- [ ] StackKits CUE-Outputs mussen fur den gRPC-Agent konsumierbar sein
- [ ] `kombination.yaml`-Struktur mit StackKit-Schemas harmonisieren
- [ ] Agent-Capabilities als CUE-Schema definieren (`#NodeCapabilities`)
- [ ] Service-Placement-Algorithmus (Filter -> Score -> Platzierung) als CUE-Constraint

**Integration Paths v1**:
- [ ] CUE-Schema fur `#IntegrationPath` definieren (Typ, Richtung, Auth, Events)
- [ ] Erste Implementierung: Cloudflare DNS (outbound), Slack/Discord Webhooks (outbound)
- [ ] Integration-Events definieren: service.deployed, health.degraded, backup.completed

**Persona-System**:
- [ ] Persona-Entscheidungsbaum als CUE-Schema (`_personaDefaults`)
- [ ] Wizard-Integration spezifizieren (kombify Stack UI)
- [ ] Persona-basierte Defaults generieren

**Fertig-Kriterium**: Ein base-homelab Deployment kann uber gRPC-Agent Status-Updates senden und bei Cloudflare einen DNS-Record anlegen.

---

### M8: AI Self-Healing & Intelligence (4-6 Wochen)

**Ziel**: AI-basierte Features sind als Prototyp verfugbar.

- [ ] AI Self-Healing Pipeline definieren: Detect -> Diagnose -> Heal
- [ ] Eskalationsmodell implementieren: Low (auto-restart), Medium (rollback), High (rebalance), Critical (notify)
- [ ] AI-Assisted Node Workers: Health Score Berechnung (0-100)
- [ ] Resource Prediction: Historische Daten -> CPU/RAM-Vorhersage
- [ ] Anomaly Detection: Baseline-Erstellung + Abweichungserkennung
- [ ] Log Intelligence: Automatische Kategorisierung und Priorisierung
- [ ] Smart Scheduling: Maintenance-Fenster-Empfehlung

**Fertig-Kriterium**: Ein Agent kann einen Container-Crash erkennen, automatisch neu starten, und bei wiederholtem Fehler den User benachrichtigen.

---

### M9: Dokumentation & Public Readiness (2-3 Wochen, parallel zu M6-M8)

**Ziel**: Die offentliche Dokumentation ist aktuell, konsistent und vollstandig.

**Mintlify Docs**:
- [ ] Beyond-IaC Konzeptseite erstellen (K12)
- [ ] Add-On-System Konzeptseite erstellen (K13)
- [ ] Persona-System Konzeptseite erstellen (K14)
- [ ] Local/Cloud-Split dokumentieren (K15)
- [ ] Alle StackKit-Seiten auf aktuellen Stand bringen
- [ ] Migration Guides erstellen (base -> ha, base -> modern)
- [ ] Visual Decision Tree (Mermaid): Welcher StackKit fur welchen Use Case
- [ ] Interactive CLI Wizard Dokumentation

**Marketing/Website**:
- [ ] "Terraform" -> "OpenTofu" auf Marketing-Seite korrigieren (K10)
- [ ] K8s-Referenzen aus Marketing-Seite entfernen
- [ ] website-v2 Content auf aktuelle Architektur anpassen

**kombify Core**:
- [ ] README.md mit Inhalt fullen (K11)
- [ ] ARCHITECTURE_REVIEW_OPUS.md aktualisieren (StackKits-Referenzen korrigieren)

**Fertig-Kriterium**: Jede Seite in `mintlify dev` zeigt akuellen, konsistenten Inhalt. Keine toten Links.

---

## Zeitplan-Ubersicht

```
2026 Q1 (Feb-Marz)
  |-- M0: Hygiene & Konsistenz --------|  (Woche 1-2)
  |-- M1: Core IaC Pipeline -----------|  (Woche 2-5)
  |-- M2: Backend-Split & Varianten ---|  (Woche 4-7)

2026 Q2 (April-Mai)
  |-- M3: StackKit-Reife --------------|  (Woche 8-11)
  |-- M4: CUE-Entscheidungslogiken ---|  (Woche 10-12)
  |-- M5: Terramate & Day-2 Ops ------|  (Woche 12-14)

2026 Q2-Q3 (Mai-Juli)
  |-- M6: Add-On-System v1 -----------|  (Woche 14-16)
  |-- M7: Beyond-IaC Foundation ------|  (Woche 16-20)
  |-- M8: AI Self-Healing & Intel.----|  (Woche 18-24)
  |-- M9: Docs & Public Readiness ----|  (parallel, Woche 14-24)
```

**Uberlappungen sind beabsichtigt**: M9 (Docs) lauft parallel zu M6-M8. M1-M2 uberlappen bei CUE/OpenTofu-Themen.

---

## Priorisierung & Abhangigkeiten

```
M0 (Hygiene)
 |
 +--+-- M1 (IaC Pipeline) ---- M2 (Backend-Split) ---- M3 (StackKit-Reife)
 |                                                            |
 +-- M9 (Docs) [parallel ab M0] -----------------------------|
                                                              |
                                         M4 (CUE-Logiken) ---|
                                         M5 (Terramate) ------|
                                                              |
                                         M6 (Add-Ons) --------|
                                         M7 (Beyond-IaC) -----|
                                                              |
                                         M8 (AI) -------------|
```

**Blockierende Abhangigkeiten**:
- M1 blockiert M2 (braucht funktionierende CUE-Pipeline)
- M2 blockiert M3 (StackKits brauchen Backend-Split-Verstandnis)
- M3 blockiert M4 (Entscheidungslogiken brauchen stabile Schemas)
- M1 blockiert M5 (Terramate braucht OpenTofu-Integration)
- M3 blockiert M6 (Add-Ons brauchen stabile StackKit-Schemas)
- M7 blockiert M8 (AI braucht Agent-Foundation)

**Nicht-blockierende Arbeit**:
- M0 kann sofort starten
- M9 kann jederzeit parallel laufen
- M4 und M5 konnen parallel zu M3 beginnen (aber testen erst nach M3)

---

## Risiken

| Risiko | Wahrscheinlichkeit | Impact | Mitigation |
|--------|:---:|:---:|-------------|
| CUE-Export-Komplexitat unterschatzt | Mittel | Hoch | Fruh Prototyp mit 1 Service testen, nicht alle auf einmal |
| modern-homelab Neukonzeption unklar | Mittel | Mittel | Klare Abgrenzung zu ha-homelab in M3 definieren |
| AI-Features zu ambitioniert | Hoch | Niedrig | M8 ist bewusst als Prototyp geplant, nicht als Produktion |
| Cross-Repo-Synchronisation | Mittel | Mittel | M0 schafft die Basis, M9 halt die Docs aktuell |
| Einzelentwickler-Bottleneck | Hoch | Hoch | Meilensteine klein halten, Feedback-Loops einbauen |

---

*Dieses Dokument wird bei jedem Meilenstein-Abschluss aktualisiert. Naechste Review: nach M0.*
