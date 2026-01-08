# Schema Definitions

> Teil der **IaC-First Architektur** von KombiStack

## Zweck

Dieses Verzeichnis enthält CUE-Schemas für die Validierung der OpenTofu-Templates und der generierten Konfigurationen. Die Schemas stellen sicher, dass alle Templates konsistent und korrekt sind.

## Was gehört hierher?

- **Template-Schemas**: Validierung der `.tf.tmpl`-Dateien
- **Variable-Schemas**: Definition erlaubter Template-Variablen
- **Output-Schemas**: Validierung der erwarteten Outputs
- **Constraint-Definitions**: Business-Regeln und Constraints
- **Type-Definitions**: Wiederverwendbare Typen für StackKits

## IaC-First Prinzip

Der KombiStack-Agent führt **keine Shell-Commands direkt** aus. Die Schemas hier:

1. Validieren die Template-Struktur vor der Generierung
2. Stellen sicher, dass generierte TF-Dateien gültig sind
3. Definieren die Schnittstelle zwischen Core und Templates
4. Ermöglichen frühzeitige Fehlererkennung

## Erwartete Schema-Files

```
schema/
├── template.cue           # Schema für Template-Struktur
├── variables.cue          # Schema für Template-Variablen
├── outputs.cue            # Schema für Template-Outputs
├── providers.cue          # Erlaubte Provider-Definitionen
├── resources.cue          # Ressource-Typ-Definitionen
├── constraints.cue        # Business-Constraints
└── types.cue              # Gemeinsame Typ-Definitionen
```

## Schema-Beispiel

```cue
// template.cue
package schema

#TemplateFile: {
    // Pfad relativ zum StackKit-Root
    path: =~"^[a-z_]+\\.tf\\.tmpl$"
    
    // Welche Phase nutzt dieses Template
    phase: "bootstrap" | "network" | "lifecycle"
    
    // Benötigte Variablen
    requires: [...#VariableRef]
    
    // Produzierte Outputs
    outputs: [...#OutputDef]
}

#VariableRef: {
    name: string
    type: "string" | "number" | "bool" | "list" | "map"
    source: "kombination" | "node" | "computed"
}

#OutputDef: {
    name: string
    type: "string" | "number" | "bool" | "list" | "map"
    sensitive: bool | *false
}
```

## Validierung

Die Schemas werden verwendet in:

1. **StackKit-Entwicklung**: `cue vet` prüft Templates gegen Schemas
2. **Core-Generierung**: Unifier validiert vor Template-Rendering
3. **CI/CD**: Automatische Validierung bei StackKit-Änderungen

## Constraints-Beispiel

```cue
// constraints.cue
package schema

#NetworkConstraints: {
    // Subnetz muss private IP sein
    subnet: =~"^(10\\.|172\\.(1[6-9]|2[0-9]|3[01])\\.|192\\.168\\.)"
    
    // Gateway muss im Subnetz sein
    gateway: string
    
    // Mindestens ein DNS-Server
    dns: [string, ...string]
}

#SecurityConstraints: {
    // SSH-Port darf nicht 22 sein in Production
    ssh_port: uint16 & (!=22 | *22)
    
    // Root-Login muss deaktiviert sein
    permit_root_login: false
}
```

## Integration mit Unifier

Der Unifier Engine (`pkg/unifier/`) nutzt diese Schemas:

1. Lädt StackKit-Schemas aus diesem Verzeichnis
2. Validiert `kombination.yaml` gegen Schemas
3. Prüft generierte TF-Dateien vor dem Schreiben
4. Meldet Constraint-Verletzungen an den User

## Abhängigkeiten

- CUE v0.6+ erforderlich
- Schemas werden von allen Phasen referenziert
- Änderungen hier erfordern Kompatibilitätsprüfung
