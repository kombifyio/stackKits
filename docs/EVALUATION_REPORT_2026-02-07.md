# StackKits – Ehrliche Evaluierung & Priorisierte Handlungsempfehlungen

> **Datum:** 2026-02-07
> **Scope:** Vollständige Analyse aller CUE-Schemas, Go-CLI, StackKit-Implementierungen, Docs & Architektur
> **Methodik:** Deep-Code-Review aller `.cue`, `.go`, `.yaml`, `.md` Dateien

---

## 1. Gesamtbewertung: Struktur & Umsetzungsstatus

### 1.1 Ehrliches Fazit

**Das Projekt hat eine beeindruckend durchdachte CUE-Schema-Architektur, aber eine signifikante Lücke zwischen Schema-Design und tatsächlicher Umsetzung.** Die Base-Schemas (`base/*.cue`) sind produktionsreif modelliert. Die Go-CLI ist funktional. Aber die StackKits selbst (außer `base-homelab`) existieren nur als Scaffolding, und selbst `base-homelab` hat keine CUE→Terraform-Code-Generierung.

### 1.2 Umsetzungsstatus pro Komponente

| Komponente | Schema-Qualität | Implementierung | Realitäts-Check |
|------------|----------------|-----------------|-----------------|
| **base/ (CUE Core)** | ⭐ 95% | Schema only | Exzellente Schemas, aber keine Enforcement-Pipeline |
| **base-homelab/** | ⭐ 85% | 60% funktional | Bestes StackKit, aber `main.tf` ist statisch, nicht CUE-generiert |
| **dev-homelab/** | 🟢 70% | 40% funktional | Hat konkrete Werte, aber `exports.cue` erzeugt Paket-Konflikte |
| **modern-homelab/** | 🟡 50% | 0% funktional | Nur Schemas, alle Services `status: "planned"` |
| **ha-homelab/** | 🟡 45% | 0% funktional | 8 explizite TODOs, kein Service implementiert |
| **Go CLI** | ⭐ 90% | 85% funktional | 9 Commands real implementiert, gut strukturiert |
| **internal/ Packages** | ⭐ 90% | 85% funktional | SSH, Docker, Tofu, Terramate – echte Logik |
| **Templates (`.tf.tmpl`)** | 🟡 50% | Vorhanden | Templates existieren, werden aber nicht gerendert |
| **Tests** | 🟢 60% | Teilweise | CUE-Tests gut, Go-Unit-Tests minimal |
| **CI/CD** | 🟢 60% | Basispipeline | GitHub Actions vorhanden, kein E2E |

### 1.3 Strukturelle Stärken

1. **3-Layer-Architektur** (Foundation → Platform → Applications) ist sauber durchgedacht
2. **CUE-Schemas im `base/`** sind umfassend: Network, Security, Identity, Observability, Validation
3. **Variant-System** (service + compute + OS) ist elegant und erweiterbar
4. **Go-CLI** hat professionelle Fehlerbehandlung mit Auto-Fix-Mechanismus
5. **Settings-Klassifikation** (Perma vs. Flexible) ist ein guter Architektur-Ansatz
6. **Conditional CUE Logic** in `validation.cue` (TLS, Backup, Alerting Decision Trees) zeigt die richtige Richtung

### 1.4 Kritische Schwächen

1. **Kein CUE→Terraform Code-Generator** – Das Kernversprechen fehlt
2. **Schema-Duplikation** zwischen `base/layers.cue` und `base/platform/*.cue`
3. **Package-Deklarations-Fehler** in `base/platform/` und `base/schema/` (würden `cue vet` brechen)
4. **Zwei konkurrierende Haupt-Schemas** in base-homelab: `#BaseHomelabStack` vs. `#BaseHomelabKit`
5. **Template-Rendering wird umgangen** – `generate.go` kopiert verbatim statt zu rendern

---

## 2. Priorisierte Aufgabenliste

### P0 – Blocker / Sofort beheben

| # | Thema | Warum P0 | Aufwand |
|---|-------|----------|---------|
| 1 | **Package-Deklaration in `base/platform/*.cue` und `base/schema/*.cue` fixen** | `package base` in Subdirectories bricht CUE-Module-Resolution. Entweder Package umbenennen oder Dateien nach `base/` hoch verschieben | 2-4h |
| 2 | **Schema-Duplikation auflösen** | `#PAASConfig`, `#DokployConfig`, `#CoolifyConfig`, `#TinyAuthConfig` etc. existieren DOPPELT in `base/layers.cue` UND `base/platform/*.cue`. Single Source of Truth schaffen | 4-8h |
| 3 | **Compute-Tier Namens-Inkonsistenz** | Go models: `minimal/standard/performance` vs CUE: `low/standard/high` – Pick one | 1h |
| 4 | **Platform-Type Mismatch** | Go-Validator akzeptiert `kubernetes`, CUE-Schema nur `docker/docker-swarm/bare-metal`. Per ADR-0002 ist Kubernetes explizit ausgeschlossen | 1h |

### P1 – Fundament stärken (nächste 2 Wochen)

| # | Thema | Beschreibung | Aufwand |
|---|-------|-------------|---------|
| 5 | **Single Source Schema Architecture** | Entscheiden: Alles in `base/*.cue` oder Split in `base/platform/`, `base/identity/` etc. mit korrekten Package-Names. Empfehlung: Flat in `base/` belassen | 4-8h |
| 6 | **Haupt-Schema Konsolidierung** | `#BaseHomelabStack` vs `#BaseHomelabKit` in base-homelab – eines entfernen, das andere als kanonisch deklarieren | 2-4h |
| 7 | **Template-Rendering aktivieren** | `generate.go` muss `template.Renderer.Render()` nutzen statt `copyOrRenderTemplates()` | 4h |
| 8 | **dev-homelab `exports.cue` Konflikt-Fix** | Top-Level Values in `exports.cue` kollidieren mit `#Stack` in `stackfile.cue`. Restructurieren | 2-4h |
| 9 | **Whoami-Service Port-Fix** | `#WhoamiService` fehlt `host` Port in PortMapping – bricht `base.#PortMapping`-Constraint | 30min |
| 10 | **Coolify Image-Typo** | `"ghcr.io/coolabsio/coolify"` → `"ghcr.io/coollabsio/coolify"` (fehlendes 'l') | 5min |

### P2 – Feature-Completion (Monat 1)

| # | Thema | Beschreibung | Aufwand |
|---|-------|-------------|---------|
| 11 | **CUE→Terraform Bridge vollständig implementieren** | `bridge.go` existiert aber generiert nur `tfvars`. Muss `main.tf` aus CUE-Schemas generieren | 2-3 Wochen |
| 12 | **PAAS-Selection-Logic in CUE umsetzen** | Regel "kein Domain → Dokploy, Domain → Coolify" als CUE-Constraint, nicht nur Docs | 1 Tag |
| 13 | **OpenTofu-Validation wirklich ausführen** | `validate.go` gibt nur "valid" aus ohne `tofu validate` zu rufen | 2h |
| 14 | **Go-Unit-Tests schreiben** | `tests/unit/` ist quasi leer – mindestens `internal/config`, `internal/cue`, `internal/template` testen | 1 Woche |
| 15 | **CUE-Validation in CI erzwingen** | `cue vet ./base/... ./base-homelab/...` als CI-Step | 2h |

### P3 – Erweiterung (Monat 2-3)

| # | Thema | Beschreibung | Aufwand |
|---|-------|-------------|---------|
| 16 | **modern-homelab implementieren** | Alle Services von `status: "planned"` → implementiert bringen | 2-3 Wochen |
| 17 | **ha-homelab implementieren** | 8 TODOs abarbeiten (Swarm, Traefik HA, HAProxy, Prometheus HA, etc.) | 3-4 Wochen |
| 18 | **Terramate Advanced Mode verdrahten** | Go-Code existiert, aber nicht in Haupt-Workflow integriert | 1 Woche |
| 19 | **E2E-Tests CI-kompatibel** | `run_e2e.sh` braucht automatisierte VM-Provisionierung | 1 Woche |
| 20 | **marketing/ vs website-v2/ konsolidieren** | Zwei Web-Projekte ohne klare Abgrenzung | 1 Tag |

---

## 3. Fehlende CUE-Entscheidungslogiken

### 3.1 Bereits implementierte Decision Logic ✅

| Decision | Datei | Status |
|----------|-------|--------|
| TLS-Strategie (acme/self-signed/custom/none) | `base/validation.cue` `#TLSDecision` | ✅ Implementiert |
| Backup-Decision-Tree | `base/validation.cue` `#BackupDecision` | ✅ Implementiert |
| Alerting-Decision-Tree | `base/validation.cue` `#AlertingDecision` | ✅ Implementiert |
| Domain-Type-Detection (local vs public) | `base/validation.cue` `#DomainType` | ✅ Implementiert |
| Storage-Config (NFS-conditional) | `base/validation.cue` `#StorageConfig` | ✅ Implementiert |
| Compute-Tier Smart Defaults | `base-homelab/defaults.cue` `#SmartDefaults` | ✅ Implementiert |
| Deployment-Mode Selection (simple/advanced) | `base-homelab/stackfile.cue` | ✅ Implementiert |
| HA Quorum-Berechnung | `ha-homelab/stackfile.cue` | ✅ Implementiert |

### 3.2 Dokumentierte aber NICHT implementierte Decision Logic ❌

| Decision | Wo dokumentiert | Warum fehlt es | Priorität |
|----------|----------------|----------------|-----------|
| **PAAS-Auto-Selection** | `architecture.md`, `services.cue` Header | Nur als Kommentar dokumentiert. Muss als CUE-Constraint implementiert werden: `if network.domain =~ "\\.(local\|lan)$" { paas.type: "dokploy" }` else `{ paas.type: "coolify" }` | **Hoch** |
| **Platform-Identity Auto-Selection** | `architecture.md` | TinyAuth vs PocketID vs Authelia – kein automatischer Switch basierend auf Features. Muss: `if identity.sso == true { provider: "pocketid" }` else `{ provider: "tinyauth" }` | **Hoch** |
| **Network-Mode-driven Firewall Rules** | `NETWORKING_STANDARDS.md` | Local/Hybrid/Public Netzwerk-Modi sollen unterschiedliche Firewall-Regeln erzeugen. Kein CUE-Guard implementiert | **Mittel** |
| **GPU-Detection → AI-Service-Enablement** | `TARGET_STATE.md` | GPU-Spec existiert in `#GPUSpec`, aber kein Logic: `if nodes[0].resources.gpu != _|_ { services.ai.enabled: true }` | **Mittel** |
| **Cross-Node Service Placement** | `modern-homelab/stackkit.cue` | `#NodeType` hat cloud/local, aber keine Placement-Constraints: "private data on local, public services on cloud" | **Mittel** |
| **OS-Variant Package Selection** | OS-Variants in `base-homelab/variants/` | Varianten definieren Packages, aber CUE wählt nicht automatisch basierend auf `nodes[0].os` | **Mittel** |
| **Compute-Tier Auto-Detection** | `base-homelab/stackfile.cue` | `#ResourceRequirements` hat `if cpu >= 8 && memory >= 16` Logik, aber nicht in `#BaseHomelabStack` verdrahtet | **Mittel** |
| **Mutual Exclusivity Guards** | `decision_test.cue` testet es | Tests validieren "kein Dokploy + Coolify gleichzeitig", aber kein CUE-Constraint erzwingt es im Schema selbst | **Hoch** |
| **Variant→Domain Dependency** | `services.cue` Header | "Coolify requires domain" ist kommentiert aber nicht als CUE-Guard: `if variant == "coolify" { network.domain: !~"\\.(local\|lan)$" }` | **Hoch** |
| **Service-Dependency-Chain Validation** | `base/stackkit.cue` `needs` field | Services haben `needs: [...]` aber keine CUE-Logik prüft ob referenzierte Services auch enabled sind | **Mittel** |
| **Drift-Detection → Advanced Mode Auto-Switch** | `base-homelab/stackfile.cue` | `driftDetection.enabled: true` sollte automatisch `deploymentMode: "advanced"` erzwingen – Logik fehlt | **Niedrig** |
| **Multi-Node → Swarm Auto-Selection** | `ha-homelab` Konzept | >=3 Nodes sollte automatisch Docker Swarm als Platform wählen. Nicht als CUE-Guard implementiert | **Niedrig** |

### 3.3 Empfohlene neue Decision Logic

```cue
// 1. PAAS Auto-Selection (MUSS implementiert werden)
#PAASAutoSelect: {
    domain: string
    _isLocal: (domain =~ "\\.(local|lan|home|internal|test)$") | (domain == "local")
    
    if _isLocal == true {
        paas: type: "dokploy"
    }
    if _isLocal == false {
        paas: type: "coolify"
    }
}

// 2. Variant→Domain Guard (MUSS implementiert werden)
#VariantDomainGuard: {
    variant: string
    domain:  string
    
    if variant == "coolify" {
        domain: !~"\\.(local|lan|home|internal|test)$"
    }
}

// 3. Mutual Exclusivity (MUSS implementiert werden)
#PAASExclusivity: {
    services: {
        dokploy?: { enabled: bool }
        coolify?: { enabled: bool }
    }
    // CUE enforces: only one PAAS at a time
    if services.dokploy.enabled == true {
        services: coolify: enabled: false
    }
}

// 4. Service Dependency Validation
#ServiceDependencyCheck: {
    services: [...{
        name:    string
        enabled: bool
        needs:   [...string]
    }]
    // TODO: CUE comprehension to verify all 'needs' reference enabled services
}

// 5. Compute-Tier Auto-Detection
#ComputeTierAutoDetect: {
    nodes: [...{ compute: { cpuCores: int, ramGB: int } }]
    
    let cpu = nodes[0].compute.cpuCores
    let ram = nodes[0].compute.ramGB
    
    if cpu >= 8 && ram >= 16 { computeTier: "high" }
    if cpu >= 4 && cpu < 8 && ram >= 8 && ram < 16 { computeTier: "standard" }
    if cpu < 4 || ram < 8 { computeTier: "low" }
}
```

---

## 4. Widersprüche & Offene Architekturfragen

### 4.1 Konkrete Widersprüche

| # | Widerspruch | Quelle A | Quelle B | Auflösung nötig |
|---|------------|----------|----------|------------------|
| W1 | **Compute-Tier Benennung** | Go: `minimal/standard/performance` | CUE: `low/standard/high` | Ja – CUE ist kanonisch, Go anpassen |
| W2 | **Kubernetes-Support** | Go-Validator akzeptiert `"kubernetes"` | ADR-0002: "Docker-First v1", CUE: nur `docker/docker-swarm/bare-metal` | Ja – aus Go-Validator entfernen |
| W3 | **Layer-3 PAAS-Check** | Go `layer_validator.go`: sucht PAAS in Layer 3 | CUE `layers.cue`: PAAS ist Layer 2, Layer 3 darf KEINE PAAS-Services enthalten | Ja – Go-Code anpassen |
| W4 | **Zwei Haupt-Schemas** | `#BaseHomelabStack`: eigenständig, vereinfacht | `#BaseHomelabKit`: extends `base.#BaseStackKit` | Ja – eines als kanonisch wählen |
| W5 | **Health-Check Format** | `base.#HealthCheck`: `startPeriod` (camelCase) | `dev-homelab/services.cue`: `start_period` (snake_case) | Ja – camelCase ist kanonisch |
| W6 | **3-Layer vs README** | README: "Layer 2: STACKKIT" | architecture.md: "Layer 2: Platform" | Ja – architecture.md ist kanonisch, README aktualisieren |
| W7 | **Node-Count modern-homelab** | README: "2+ Nodes" | `stackkit.cue`: keine MinItems-Constraint | Ja – CUE-Constraint hinzufügen |
| W8 | **Services-Format** | `base.#BaseStackKit`: `services: [...#ServiceDefinition]` (Liste) | `base-homelab/stackfile.cue` `#ServiceSet`: `services: { traefik: ..., dokploy: ... }` (Struct) | Ja – Format vereinheitlichen |
| W9 | **Headscale Port-Konflikt** | `modern-homelab/services.cue`: Headscale binds Host-Port 443 | Traefik binds ebenfalls Host-Port 443 | Ja – Ports auflösen |
| W10 | **Domain-Validation HA vs Base** | `ha-homelab`: `domain: !~"\\.(local|lan)$"` (REJECTS local) | `base-homelab`: Lokale Domains erlaubt/erwartet | Klären: Warum muss HA public sein? |
| W11 | **Version metadata** | `base-homelab/stackkit.yaml`: `version: "2.0.0"` | `base-homelab/stackfile.cue` `#StackMeta`: `version: "3.0.0"` | Ja – Eine Single Source of Truth |
| W12 | **Dokploy/Coolify Eigenschaft** | `architecture.md`: Dokploy = "kein Domain", Coolify = "Domain" | Dokploy unterstützt sehr wohl Custom Domains | Klären: Ist das eine Vereinfachung oder ein Fehler? |

### 4.2 Offene Architekturfragen

| # | Frage | Kontext | Empfehlung |
|---|-------|---------|------------|
| A1 | **CUE-to-Terraform: Generiert oder statisch?** | Aktuell: statische `main.tf` (800 Zeilen). Ziel laut Roadmap: CUE-generiert. Aber `bridge.go` generiert nur `tfvars` | Entscheiden: Bleibt `main.tf` statisch mit variablen `tfvars`, oder wird `main.tf` komplett aus CUE erzeugt? |
| A2 | **Soll `#BaseStackKit` wirklich mandatory sein?** | `ha-homelab` und `modern-homelab` extending `#BaseStackKit` NICHT. Nur `dev-homelab` und `base-homelab/BaseHomelabKit` tun es | Entweder alle StackKits müssen `#BaseStackKit` extenden (strikt), oder `#BaseStackKit` wird optional (pragmatisch) |
| A3 | **Flat vs. Nested Package-Struktur für `base/`?** | `base/platform/identity.cue` deklariert `package base` – ein Anti-Pattern in CUE. Sub-Pakcages sollten eigene Package-Names haben | Empfehlung: Alles flat in `base/` belassen – die Dateien sind nicht zu groß dafür |
| A4 | **Services als Liste oder Map?** | `base.#BaseStackKit` definiert `services: [...#ServiceDefinition]` (geordnete Liste). `base-homelab` definiert `services: { traefik: ..., dokploy: ... }` (Named Map) | Empfehlung: Named Map (Struct) ist besser für CUE – ermöglicht `services.traefik.enabled` Zugriff |
| A5 | **Wo leben Platform-Identity-Schemas?** | Aktuell: `base/layers.cue` UND `base/platform/identity.cue` (doppelt) | Single Source in `base/layers.cue` – `base/platform/` auflösen |
| A6 | **Wie wird Variant-Selection user-facing?** | CUE/YAML hat Variants definiert. Aber wie wählt der User? Via `stack-spec.yaml`? Via CLI-Flag? Via Wizard? | Klären: CLI `--variant=coolify` sollte in `stack-spec.yaml` schreiben |
| A7 | **Ist Terramate wirklich nötig?** | Code existiert und funktioniert, aber Advanced Mode ist nirgends verdrahtet. Ist der Overhead gerechtfertigt? | Entweder in v1 konsequent einbauen oder auf v2 verschieben |
| A8 | **Wie verhält sich `base/` zu `platforms/docker/`?** | `base/` definiert `#ContainerRuntime`, `platforms/docker/` definiert `#DockerConfig`. Überlappung? | Klären: `base/` = abstrakt, `platforms/docker/` = Docker-spezifisch. Mapping dokumentieren |
| A9 | **Secrets-Management Strategie** | `#SecretsPolicy` unterstützt file/env/vault/sops. Aber kein konkreter Flow implementiert | Entscheiden: Was ist Standard für v1? Empfehlung: `env` für Simple, `sops` für Advanced |
| A10 | **Add-On-Konzept** | In `TARGET_STATE.md` definiert, aber keine CUE-Struktur dafür | Braucht eigenes `#AddOn` Schema mit Kompatibilitäts-Regeln |

---

## 5. Ideen & Empfehlungen zur Verbesserung

### 5.1 Quick Wins (< 1 Tag)

1. **`cue vet` als Pre-Commit-Hook** – Verhindert kaputte Schemas im Repo
2. **Coolify-Image-Typo fixen** – `coollabsio` statt `coolabsio`
3. **Compute-Tier-Namen in Go alignen** – `low/standard/high` überall
4. **`validate` Command mit echtem `tofu validate`** – Statt Dummy-Output
5. **Version-Metadata vereinheitlichen** – Eine Quelle: `stackkit.yaml`

### 5.2 Architektur-Empfehlungen

6. **"Schema-First, Template-Second"** Workflow klar dokumentieren:
   ```
   User → stack-spec.yaml → CUE validate → CUE resolve (defaults, variants)
   → Template render → main.tf + terraform.tfvars → tofu plan → tofu apply
   ```

7. **CUE-Constraint-Tests als First-Class CI** – Die Decision-Tests in `base-homelab/tests/` sind exzellent. Dieses Pattern auf alle StackKits ausrollen.

8. **Schema-Versionierung einführen** – CUE-Schemas brauchen `@version(v3)` Tags damit StackKits gegen spezifische Schema-Versionen validiert werden

9. **"Escape Hatch" Pattern** definieren – Was passiert wenn ein User etwas will das nicht im Schema ist? `_raw` Fields? Override-Dateien?

10. **Deployment-Contract als CUE-Schema** – `DEPLOYMENT_CONTRACT.md` in maschinenlesbares CUE umwandeln

### 5.3 Feature-Empfehlungen

11. **`stackkit doctor` Command** – Diagnostik-Tool das:
    - CUE-Validation ausführt
    - Schema-Konsistenz prüft
    - Duplikate findet
    - Go↔CUE Alignment checkt

12. **`stackkit diff` Command** – Zeigt Unterschiede zwischen Varianten an:
    ```bash
    stackkit diff default coolify
    # + coolify, - dokploy, + requiresDomain
    ```

13. **Interactive Variant-Wizard** – `stackkit init --interactive` fragt:
    - "Hast du eine eigene Domain?" → coolify/default
    - "Wie viel RAM hat dein Server?" → compute tier
    - "Welches OS?" → OS variant

14. **CUE-Playground** – Web-basierter CUE-Editor wo User ihre `stack-spec.yaml` gegen Live-Schemas validieren können

15. **Dependency Graph Visualization** – Service-Dependencies als Mermaid-Diagram generieren lassen

### 5.4 Technische Schulden die jetzt adressiert werden sollten

16. **`internal/cue/validator.go` ValidateSpec()** reimplementiert CUE-Constraints in Go – Stattdessen sollte CUE-Validation allein über `cue vet` laufen. Go-Duplikation entfernen.

17. **`generate.go` verbatim-copy** – Die Template-Engine existiert (`internal/template/renderer.go`), wird aber umgangen. Das ist ein Architecturally Significant Bug.

18. **OS-Variant-Schema-Inkonsistenz** – Ubuntu 24.04 nutzt `#OSVariant`, Ubuntu 22.04 nutzt `#Ubuntu22Variant`. Einheitliches Base-Schema schaffen.

19. **Test-Abdeckung `internal/`** – SSH-Client, Docker-Client, Config-Loader haben NULL Unit-Tests trotz produktionsreifer Implementierung.

---

## 6. Zusammenfassung: Die 10 wichtigsten nächsten Schritte

| Rang | Aktion | Impact | Aufwand |
|------|--------|--------|---------|
| 1 | CUE Package-Deklaration fixen (P0 #1) | Verhindert `cue vet` Breakage | 2-4h |
| 2 | Schema-Duplikation auflösen (P0 #2) | Single Source of Truth | 4-8h |
| 3 | Go↔CUE Inkonsistenzen fixen (P0 #3-4) | Korrekte Validation | 2h |
| 4 | Haupt-Schema konsolidieren (P1 #6) | Klarheit für Contributors | 2-4h |
| 5 | PAAS-Selection als CUE-Guard (§3.2) | Kern-Feature realisieren | 4h |
| 6 | Variant→Domain Guard + Exclusivity (§3.2) | Fehler verhindern | 4h |
| 7 | Template-Rendering aktivieren (P1 #7) | Kern-Feature | 4h |
| 8 | `cue vet` in CI erzwingen (P2 #15) | Qualitätssicherung | 2h |
| 9 | Go Unit-Tests für internal/ (P2 #14) | Regressionssicherheit | 1 Woche |
| 10 | CUE→Terraform Bridge erweitern (P2 #11) | Produktversprechen einlösen | 2-3 Wochen |

---

## Anhang: CUE Datei-Inventory

### base/ (Core-Schemas)

| Datei | Zeilen | Inhalt | Status |
|-------|--------|--------|--------|
| `stackkit.cue` | 401 | `#BaseStackKit`, `#ServiceDefinition`, `#NodeDefinition` | ⭐ Produktionsreif |
| `network.cue` | ~120 | `#NetworkDefaults`, `#DNSConfig`, `#VPNConfig` | ⭐ Produktionsreif |
| `security.cue` | 563 | SSH, Firewall, Container, Secrets, TLS, Zero-Trust, Audit | ⭐ Produktionsreif |
| `system.cue` | 158 | `#SystemConfig`, `#BasePackages`, `#SystemUsers`, `#ContainerRuntime` | ⭐ Produktionsreif |
| `identity.cue` | 484 | `#LLDAPConfig`, `#StepCAConfig`, PKI, SCEP, JWK | ⭐ Produktionsreif |
| `observability.cue` | 273 | Logging, HealthCheck, Metrics, Alerting, Backup | ⭐ Produktionsreif |
| `validation.cue` | 244 | Validators, Constraints, TLS/Backup/Alerting Decision Trees | ⭐ Produktionsreif |
| `layers.cue` | 568 | 3-Layer-Architektur, PAAS-Configs, `#ValidatedStackKit` | 🟢 Funktional (Duplikate) |
| `doc.cue` | 20 | Package-Dokumentation | ⭐ |

### base/platform/ (⚠️ Package-Probleme)

| Datei | Zeilen | Inhalt | Status |
|-------|--------|--------|--------|
| `identity.cue` | 598 | Platform Identity (TinyAuth, PocketID, Authelia, Authentik) | ⚠️ Package-Fehler + Duplikat |
| `paas.cue` | 440 | PAAS-Configs (Dokploy, Coolify, Portainer, Dockge) | ⚠️ Package-Fehler + Duplikat |

### base/schema/ (⚠️ Package-Probleme)

| Datei | Zeilen | Inhalt | Status |
|-------|--------|--------|--------|
| `iac_first.cue` | ~175 | `#UnifiedSpec`, `#BootstrapConfig`, `#AgentCommand` | ⚠️ Name-Collisions |

### StackKits

| StackKit | CUE Files | Gesamtzeilen | Implementierung |
|----------|-----------|-------------|-----------------|
| base-homelab | 3 + 7 variant + 3 test | ~3500 | 🟢 60% |
| dev-homelab | 4 | ~1200 | 🟡 40% |
| modern-homelab | 3 | ~1050 | 🔴 0% (planned) |
| ha-homelab | 3 | ~900 | 🔴 0% (planned) |

