### Identity Plan: Zero-Trust Homelab & SaaS

This plan defines the identity and trust architecture for the kombify ecosystem, especially for StackKits.

### 1\. Strategic Goals & Core Principles

Establish a hybrid identity infrastructure that combines strong defaults (passkeys, mTLS, zero-trust) with **intentionally unrestricted capabilities** for advanced users.  
**Core principles:**

* **Strong defaults, not hard limitations**  
* kombify ships with **secure-by-default presets** (passkeys only, mTLS, no password login, no open ports).  
* These are recommendations and starting points, **not hard constraints**.  
* **User sovereignty over security posture**  
* Advanced users and operators can **intentionally downgrade** security if their use case requires it.  
* This includes allowing **user+password only** authentication, disabling MFA, or exposing services more offenly – as long as this is an explicit, conscious choice in configuration.  
* **Passkey-first for humans**  
* Recommended default: passwordless login via **Passkeys (WebAuthn)**.  
* **Secret-free for agents**  
* Recommended default: workloads authenticate via certificates (mTLS / SPIFFE), not static passwords or API keys.  
* **Hybrid model (Cloud \+ Local)**  
* Combination of cloud IdP (Zitadel) and local identity services for homelab sovereignty.

The documentation and StackKits will always:

* Provide **opinionated secure defaults**, and  
* Expose **all underlying options without restriction**, so that power users retain full control over their risk decisions.

### 2\. Component Stack

Component | Role | Technology / Protocol  
Zitadel Cloud | Global IdP (SaaS) | OIDC, FIDO2, Multi-Tenancy  
tinyauth | Identity Broker & Proxy | OIDC Federation, mTLS Enforcement  
pocketid | Local Passkey IdP | WebAuthn / Passkeys  
lldap | Directory Service | LDAP (source of truth for groups)  
step-ca | PKI & Certificate Authority | SCEP, ACME, x509  
PocketBase | App backend | OIDC Consumer, RBAC via groups

### 3\. Identity Types & Flows

#### A. Human identities (Owners & Members)

* **Primary login (recommended default)**: Passkeys (WebAuthn).  
* **Login flow**:  
* User → **tinyauth** → (Zitadel *or* pocketid) → Passkey validation → OIDC token.  
* **Recovery strategy** (recommended):  
* At least two registered passkeys (for example smartphone \+ hardware key), **or**  
* Encrypted recovery codes stored outside the homelab.

#### B. Agent identities (workloads & M2M)

* **Standard model (recommended)**: SPIFFE-based trust.  
* **Flow**:  
* Agent requests a certificate from **step-ca**.  
* Access to target service is performed via **mTLS** using this certificate.  
* **Benefits**:  
* No static passwords or API keys in configuration files.  
* Short-lived certificates enable automated, rotating security.

### 4\. Security Architecture (Zero-Trust)

* **Device trust (mTLS)**  
* External access to the homelab (recommended default) requires a certificate issued via **SCEP** (step-ca).  
* Without a valid certificate, the reverse proxy silently drops the connection.  
* **Identity trust (OIDC)**  
* After successful device validation, the user authenticates via passkey.  
* OIDC tokens contain roles and group information for downstream services.  
* **RBAC via groups**  
* Permissions are modeled as **lldap groups**.  
* lldap is the source of truth for roles and groups.  
* Groups are propagated as a groups claim in OIDC tokens to **PocketBase** and other services.

### 5\. SaaS vs. Self-Hosted Logic

* **SaaS coupling (kombifySphere / cloud layer)**  
* **tinyauth** is registered as an OIDC client with **Zitadel**.  
* SaaS owners and users log in with their central kombify account.  
* **Local sovereignty (homelab layer)**  
* Local members are created in **lldap** and use **pocketid** as a local passkey provider.  
* Biometric data and passkey keys never leave the local network.  
* **Automatic provisioning (recommended flow)**  
* During initial installation, the SaaS tool generates:  
* OIDC configuration for **tinyauth** (client IDs, redirect URIs, scopes).  
* Root and intermediate certificates for **step-ca**.  
* These artifacts are distributed to local components (reverse proxy, agents, kombifyStack).

### 6\. Disaster Recovery & Emergency Plan

* **Emergency admin**  
* Dedicated local admin account in **tinyauth**.  
* Access restricted to a local management VLAN (IP allow-listing / firewall rules).  
* **Offline mode**  
* If the internet is down (Zitadel unreachable), **tinyauth** can fail over to local **lldap accounts**.  
* Critical infrastructure maintenance (workers, network, storage) remains possible.  
* **Backups & key management**  
* Daily automated backups of:  
* **lldap** database (for example SQLite or PostgreSQL).  
* **step-ca** keys and relevant PKI metadata.  
* Stored in an **encrypted vault** (offline backup or dedicated backup server).  
* Regular restore tests to ensure the emergency path actually works.

### 7\. Additional Identity Concepts Across the kombify Ecosystem

This chapter complements the above plan with concepts that apply across all kombify tools, based on the overview in [kombify-All](https://www.notion.so/kombify-All-2f2b1291ecd9808b9044d679308db038?pvs=21).

#### 7.1 Global identities, tenants & domains

* **Central identity layer (kombifySphere \+ Zitadel)**  
* Users, organizations, and subscriptions are managed centrally.  
* Each organization receives one or more **tenants / projects**, which include homelab instances (kombifyStack), simulations (kombifySim), and StackKits catalogs.  
* **Local identity layer (homelab / on-prem)**  
* Local accounts and groups live in **lldap**, optionally mirrored or mapped from the cloud.  
* Clear separation between **cloud identity** (account in kombifySphere) and **local operational role** (for example homelab operator).  
* **Trust domains**  
* Defined trust domains for:  
* [cloud.kombify.io](http://cloud.kombify.io) (SaaS / kombifySphere / kombifyAPI).  
* homelab.local or customer-specific domains for local kombifyStack instances.  
* Optional additional domains per environment (dev / stage / prod) in larger setups.

#### 7.2 Role model across all tools

* **SaaS roles (kombifySphere)**  
* USER: Regular use of tools, access to own homelabs / projects.  
* MANAGER: Manages billing, team members, and plans.  
* (Exact naming still flexible, concept is the important part.)  
* ADMIN: Full access at the organization level.  
* **Homelab roles (kombifyStack, kombifySim, StackKits)**  
* OWNER: Full access to a specific kombifyStack instance (homelab ownership).  
* OPERATOR: Technical operations (rollouts, updates, worker management).  
* DEVELOPER: Creates and modifies StackKits / specs.  
* VIEWER: Read-only access to dashboards and logs.  
* **Internal operations roles (kombifyAdmin)**  
* Support and operations roles with fleet- and tenant-wide visibility.  
* Strict separation between customer identities and internal operator identities (separate IdP groups and rights).

All roles should appear as **standardized claims** (for example role, org\_role, lab\_role) in OIDC/JWT tokens so that every service can interpret them consistently.

#### 7.3 Service accounts, API clients & automation

* **Service accounts per tool**  
* Dedicated identities for:  
* kombifyStack workers.  
* kombifySim orchestrator.  
* CI/CD pipelines (for example automated StackKit validation).  
* Preferred authentication via **mTLS** (SPIFFE IDs) or OAuth2 client credentials against **kombifyAPI**.  
* **Scopes & least privilege**  
* Fine-grained scopes (for example stackkits:read, stackkits:write, labs:operate, simulations:run).  
* Each automation gets only the minimal required scopes.  
* **Token lifetime & rotation**  
* Short-lived access tokens, long-lived refresh or certificate-based mechanisms.  
* Policy for regular rotation of client secrets and certificates.

#### 7.4 Environments & instance mapping

* **Environments**  
* At least dev, stage, and prod on the SaaS side.  
* Optionally separate kombifyStack instances per environment.  
* **Instance binding to identities**  
* Each kombifyStack instance, larger kombifySim cluster, and relevant StackKits catalogs are tied to a specific **tenant** and optionally an **environment**.  
* **kombifyAPI** enforces this via tenant and environment headers and claim checks.

#### 7.5 Secret & key management

* **Secrets for applications (StackKits / kombifyStack)**  
* Recommended: integrate a secret store (for example Vault, SOPS+Git, cloud secret managers) that works with the PKI (step-ca).  
* Operators should see as few plain-text secrets as possible, ideally only encrypted values.  
* **Key hierarchies**  
* Separate keys for:  
* Infrastructure (PKI root / intermediates).  
* Service identities (workers, orchestrators, API clients).  
* User-side passkeys (which stay on the FIDO device anyway).

#### 7.6 Audit, logging & compliance

* **Central audit logs**  
* Log security-relevant events:  
* Logins, token issuance, mTLS handshakes.  
* Rollout actions, configuration changes, permission changes.  
* Aggregation in kombifyAdmin for fleet-wide analysis.  
* **Technical traceability**  
* Correlation IDs and user/service IDs in all logs (propagated by kombifyAPI).  
* Ability to reconstruct a tenant’s complete "change history" for a homelab.

#### 7.7 Identity lifecycle & offboarding

* **Provisioning**  
* Automated user and role creation during onboarding (for example invite flows from kombifySphere).  
* **Changes & reassignment**  
* Role changes and team moves are managed in the cloud layer and mirrored into local roles/groups.  
* **Offboarding**  
* Clear processes for locking / removing accounts:  
* Immediate token invalidation at the IdP.  
* Removal of roles and group memberships.  
* Optional archival of relevant activity for compliance.

These concepts ensure that identity, roles, and trust are handled consistently across all kombify components and scale from small homelabs to complex multi-instance setups.

### 8\. Edge Cases & Individual Access Paths (Cloudflare Tunnels & VPN)

This chapter describes optional and advanced access scenarios that can be used **in addition** to the standard access model (mTLS \+ OIDC).

#### 8.1 Cloudflare Tunnels as "secure edge"

**Goal:** Make homelab services (for example kombifyStack UI, admin panels, API endpoints) reachable from the internet without router port forwarding and without exposing the internal network structure.

* **Architecture variant A: Tunnel in front of the reverse proxy**  
* A Cloudflare Tunnel connects an internal HTTP(S) endpoint to a public hostname (\*.\[kombify-demo.net\](http://kombify-demo.net)).  
* The tunnel does **not** terminate identity; it forwards traffic to the existing reverse proxy.  
* **Device and user trust** remain in the homelab (mTLS \+ OIDC). Cloudflare is just the pipe.  
* **Architecture variant B: Tunnel to single services**  
* Dedicated tunnel endpoints for specific services (for example PocketBase admin, monitoring).  
* Useful for demo or support scenarios where only a limited subset of the homelab should be visible.

**Security guardrails (recommended):**

* Cloudflare authenticates HTTP traffic, but **not automatically the end-user identity**.  
* Combined flow should therefore always be:  
1. Cloudflare Tunnel → forward to homelab reverse proxy.  
2. mTLS validation (device certificate via step-ca).  
3. OIDC login (passkeys) via tinyauth / Zitadel / pocketid.  
* For sensitive admin surfaces (for example kombifyAdmin), Cloudflare Access can be added as a front IdP, but should **not** replace internal RBAC.

#### 8.2 VPN access (classic vs. identity-aware)

VPN remains an important tool, especially for complex homelabs, but is **no longer the only security layer**.

* **Variant A: Classic VPN**  
* WireGuard / OpenVPN with static keys or basic accounts.  
* Provides IP-level access to internal networks but **does not automatically** grant access to kombify services.  
* Recommended: use VPN only as an additional network path; keep identity checks with mTLS \+ OIDC.  
* **Variant B: Identity-aware VPN / ZTNA-like access**  
* Use VPN solutions that support OIDC / SAML and plug them into the **same IdP landscape** (Zitadel / tinyauth).  
* Example flow:  
1. User starts VPN client.  
2. Logs in via passkey (OIDC).  
3. VPN server maps claims (groups, role) to network policies (which subnets/ports are reachable).  
* Benefit: consistent identity from SaaS all the way down to the lowest homelab layer.

#### 8.3 Combining tunnel \+ VPN \+ mTLS

Real-world setups often combine these techniques:

* **"Fat client" users** (admins, operators)  
* Use VPN for low-level access (SSH, storage backends, monitoring agents).  
* For web UIs and APIs, access still requires valid device certificate (mTLS) \+ OIDC login.  
* **"Light client" users** (viewers, end users)  
* Access only through Cloudflare Tunnels / SaaS surfaces for dashboards and UIs.  
* No full VPN needed as long as all sensitive actions are protected via kombifyAPI \+ RBAC.  
* **Automation & third-party integrations**  
* CI/CD, monitoring, or external tools prefer mTLS (SPIFFE) and talk directly to kombifyAPI.  
* VPN is only used when raw network paths are needed that the API does not cover.

#### 8.4 Individual policies & tenant specifics

* Each tenant can define its own **access profile**:  
* VPN-only (for very isolated labs).  
* Tunnel-only (demo/test environments, read-only dashboards).  
* Combination of VPN \+ tunnel \+ mTLS (production homelabs, multi-user setups).  
* kombify should offer these profiles as **configurable presets** that:  
* Prepare the required components (step-ca, reverse proxy, tunnel client, VPN server).  
* Enforce clear security defaults (for example no admin UIs without mTLS, no anonymous tunnels on production data).

Edge cases and individual access paths (especially Cloudflare Tunnels and VPN) are thus explicitly modeled without weakening the core zero-trust idea (device \+ identity trust) – while still allowing tenants to intentionally choose looser setups if they accept the risk.

### 9\. Public Services & Web Presence from the Homelab

This chapter explains how **publicly reachable services** (websites, APIs, demo instances) fit into the identity and security model, and what the **standard for local vs. cloud servers** looks like.

#### 9.1 Service types and protection levels

* **Public, anonymous content**  
* Examples: marketing website, purely informational pages, landing pages.  
* No login required, but protection against abuse (rate limits, bot protection).  
* **Public but authenticated content**  
* Examples: SaaS UI (kombifySphere), customer dashboards, self-service portals.  
* Login via central IdP landscape (Zitadel / tinyauth), sometimes without mTLS on the client side but with strong passkeys.  
* **Non-public admin or operator services**  
* Examples: kombifyStack UI in the homelab, PocketBase admin, monitoring.  
* Only reachable via mTLS \+ OIDC (and optionally VPN), not openly on the internet.

#### 9.2 Standard architecture for publicly hosted homelab services

**Goal:** Public endpoints are reachable without directly exposing the internal homelab structure.

* **Edge layer (internet-facing)**  
* Cloudflare (or similar CDN/reverse proxy) as first layer: DDoS protection, TLS termination, WAF, caching.  
* Public DNS zones (for example [kombify.io](http://kombify.io) and customer domains) point to this edge layer.  
* **Service layer (homelab or cloud)**  
* Public web app or API runs on an application server (local homelab or cloud).  
* Communication from edge to service is **encrypted** (TLS) and ideally **identity-bound** (mTLS / tunnel).  
* **Identity layer**  
* Anonymous endpoints (pure websites) only need edge protection (WAF, rate limits).  
* Authenticated endpoints use **OIDC** against Zitadel / tinyauth and reuse the global role model.

#### 9.3 Standards for local servers (homelab)

**Principle:** Local servers are **not** automatically "trusted" just because they live in the homelab.

* **L2/L3 segmentation**  
* Zones such as mgmt, apps, db, lab, and optionally dmz.  
* Public services live in a dedicated zone (for example dmz) with restricted access to the rest of the homelab.  
* **mTLS & PKI integration**  
* All internal service-to-service calls use certificates from **step-ca**.  
* Public web servers in the homelab have **two certificate layers**:  
* Public certificate for edge traffic (for example Let’s Encrypt via ACME or Cloudflare cert).  
* Internal mTLS certificate from step-ca for backend communication (DB, kombifyAPI, workers).  
* **Standard policy for local public services (recommended)**  
* No direct router port forwards to individual hosts.  
* Exposure only via:  
* Edge proxy (Cloudflare / reverse proxy in DMZ), **or**  
* VPN / tunnel solutions with a reverse proxy in front.  
* Admin UIs and sensitive access **never** protected by password-only; always OIDC \+ RBAC.

#### 9.4 Standards for cloud servers (public cloud / VPS)

Cloud servers (for example kombifySphere or hosted homelab offerings) follow the same principles but are wired differently.

* **Network & access model**  
* Cloud instances live in private subnets, exposed via managed load balancers / API gateways.  
* Direct SSH from the internet is avoided; administration via bastion, VPN, or SSM-like solutions.  
* **Identity & trust**  
* Cloud servers and services also receive step-ca or cloud PKI certificates so that **homelab and cloud can mutually trust each other via mTLS**.  
* For multi-tenant SaaS, tenant isolation is enforced via IdP (claims), kombifyAPI (tenant headers/claims), and database-level isolation.  
* **Standard policy for cloud services**  
* All public endpoints are fronted by an API/ingress layer (for example kombifyAPI \+ gateway), not exposed as naked services.  
* Authentication exclusively via OIDC/OAuth2 (passkeys, optionally with device binding for critical actions).

#### 9.5 Homelab ↔ cloud reference paths

* **Use case: homelab-hosted website with central login**  
* Website runs locally in the homelab.  
* Public traffic: user → Cloudflare edge → tunnel / reverse proxy → web server in homelab.  
* Login flow: web server → tinyauth (local or cloud) → Zitadel → OIDC token.  
* Roles/claims are handled like any other kombify service.  
* **Use case: SaaS UI in cloud with homelab backend**  
* UI runs in the cloud (kombifySphere), homelab provides data (telemetry, status, events).  
* Homelab agents talk **outbound** over mTLS/HTTPS to the cloud (no inbound ports needed).  
* Identity: agents use SPIFFE/mTLS identities; tenants and labs are mapped via claims and certificate SANs.

#### 9.6 Configurable presets for public hosting

Based on this model, kombify can offer **pre-defined hosting profiles**:

* **"Public Website (Local)"**  
* Static or light dynamic frontend in the homelab.  
* Default: Cloudflare Tunnel \+ reverse proxy \+ optional OIDC login for protected sections.  
* **"Public API (Local)"**  
* API server in the homelab, exposed via kombifyAPI/gateway.  
* Default: mTLS from edge to homelab \+ OIDC for end-user identity.  
* **"Managed Cloud Service"**  
* Service runs fully in the cloud, homelab is a data source only.  
* Default: access via kombifySphere UI \+ kombifyAPI; homelab usually not directly reachable from the internet.

Public websites and services from the homelab, as well as standards for local and cloud servers, are thus aligned with the same zero-trust and RBAC principles – while still allowing tenants to intentionally choose weaker setups if they understand and accept the risk.

### 10\. Classic MFA & User+Password as Optional (and Fully Supported) Mode

While the recommended standard is **passkeys \+ mTLS**, real-world scenarios sometimes require classic logins (user+password) with or without additional MFA. This chapter describes how these variants are integrated – and clarifies that kombify **does not technically restrict them**.

#### 10.1 Principles for legacy-style auth

* **Default: disabled (recommended)**  
* In all kombify StackKits, user+password login is **disabled by default**.  
* Passkeys (WebAuthn) remain the recommended way for human identities.  
* **Opt-in via StackKit variants**  
* Classic auth flows are provided as **optional profiles/variants** in StackKits, e.g.:  
* auth\_mode=passkeys\_only (default)  
* auth\_mode=passkeys\_plus\_legacy  
* auth\_mode=password\_only  
* Enabling these modes is a **conscious operator decision** during install or upgrade.  
* **Security downgrade is allowed by design**  
* Tenants can intentionally configure:  
* **Password-only** login (no MFA).  
* Password \+ MFA (TOTP or FIDO2 as second factor).  
* Mixed setups across roles and environments.  
* kombify will always **highlight the risks** and recommend stronger modes, but will **not block** these configurations.

#### 10.2 Supported auth flows

* **A. User+password \+ TOTP (classic MFA)**  
* Username \+ password as primary factor.  
* TOTP app (authenticator) or equivalent as second factor.  
* Implemented at the IdP level (Zitadel/pocketid) or via tinyauth.  
* **B. User+password \+ FIDO2 (passkey as second factor)**  
* Password remains, but a FIDO2 device is required as a second factor.  
* Smooth migration path from password-based to passkey-only environments.  
* **C. Password-only login**  
* Fully supported as a **conscious downgrade option** (for legacy, labs, or constrained environments).  
* Clearly marked in UI and docs as **not recommended** for production or sensitive tenants.  
* **D. Passkey-only (recommended default)**  
* No password, only FIDO2/passkey.  
* Remains the reference and default model in all kombify StackKits.

#### 10.3 Implementation in StackKits (variants & policies)

* **Configuration parameters per StackKit**  
* Example parameters:  
* auth\_mode: passkeys\_only (default), passkeys\_plus\_legacy, password\_only.  
* allow\_password\_login: false (default), true.  
* require\_mfa\_for\_password\_login: true or false (recommended: true, but can be set to false in explicit downgrade scenarios).  
* These parameters control which IdP features and flows are enabled in Zitadel/pocketid/tinyauth.  
* **Policy defaults (recommendations, not hard limits)**  
* Password policies (length, rotation, lockout) come with opinionated defaults.  
* Tenants can override them if they deliberately accept weaker security (for example for internal test labs).  
* **Migration paths**  
* StackKits should offer guided migrations, e.g.:  
* From password\_only → passkeys\_plus\_legacy → passkeys\_only.  
* Steps may include:  
* Enabling passkey registration alongside existing passwords.  
* Gradually enforcing MFA.  
* Eventually disabling new password registrations.

#### 10.4 Scope and role-based restrictions (recommended, but overridable)

* **Recommended scoping**  
* Password-only or weak setups are **recommended** only for:  
* Low-sensitivity areas (for example read-only dashboards).  
* Temporary migration phases.  
* For highly sensitive functions (for example PKI management, homelab-wide administration), documentation will recommend **passkey-only or at least strong MFA**.  
* **Role-based guidance**  
* For roles like ADMIN or OPERATOR, kombify will ship with presets that *suggest*:  
* "Do not allow password-only for this role"  
* But the system will still allow an operator to override this if they explicitly choose to.

#### 10.5 Monitoring, auditing & hardening recommendations

* **Audit & telemetry**  
* Login attempts with passwords (successful/failed) are tagged separately in logs.  
* Patterns like brute-force attempts or logins from unusual regions can trigger additional safeguards (captcha, temporary lockout, enforced passkey registration).  
* **Hardening guidance**  
* UI and documentation consistently:  
* Promote passkeys \+ mTLS as the target architecture.  
* Classify password-only modes as **legacy / high-risk**.  
* Encourage time-boxed use of weak modes (for example during migration or incident response).

Classic MFA and user+password flows are thus:

* **Fully supported** as first-class options,  
* **Disabled by default** in secure presets, and  
* Framed by clear documentation so that tenants understand when they are explicitly downgrading their security posture.

