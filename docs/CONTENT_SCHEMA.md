# Content-Schema-Referenz

Diese Datei beschreibt das vollständige JSON-Schema für Lektionen (`Lesson`) und Prüfungsfragen (`Question`) in FiSi-Trainer, damit Beiträge geschrieben werden können, ohne den Swift-Quellcode lesen zu müssen. Die Modelle selbst liegen unter `Sources/LearnCore/Models/` (`Lesson.swift`, `Question.swift`, `Curriculum.swift`), das Schema wird zur Laufzeit über `Codable` gelesen und über `Sources/LearnCore/Content/ContentValidator.swift` geprüft.

`schemaVersion` ist aktuell immer `1` (`ContentSchema.current`). Weicht der Wert ab, meldet der Validator eine Warnung — gedacht für künftige, migrierbare Formatänderungen.

## Gemeinsame Wertebereiche

Diese Enums werden sowohl in `Lesson` als auch in `Question` verwendet.

### `track` (nur `Lesson`)

| Wert | Bedeutung |
|---|---|
| `web` | Webserver & Proxies |
| `database` | Datenbanken |
| `network` | Netzwerk & Sicherheit |
| `virtualization` | Virtualisierung |

### `lernfelder`

Array von Ganzzahlen `1`–`12`, entsprechend den Lernfeldern des Ausbildungsrahmenplans Fachinformatiker/-in Systemintegration (LF1–LF12). Ein Inhalt kann mehreren Lernfeldern zugeordnet sein. Leeres Array ist erlaubt, erzeugt aber eine Validierungs-Warnung.

| Nr. | Lernfeld |
|---|---|
| 1 | Das Unternehmen und die eigene Rolle |
| 2 | Arbeitsplätze nach Kundenwunsch ausstatten |
| 3 | Clients in Netzwerke einbinden |
| 4 | Schutzbedarfsanalyse im eigenen Arbeitsbereich |
| 5 | Software zur Verwaltung von Daten anpassen |
| 6 | Serviceanfragen bearbeiten |
| 7 | Cyber-physische Systeme ergänzen |
| 8 | Daten systemübergreifend bereitstellen |
| 9 | Netzwerke und Dienste bereitstellen |
| 10 | Kunden bei der Systemintegration unterstützen |
| 11 | Betrieb und Sicherheit vernetzter Systeme |
| 12 | Kundenspezifische Systemintegration |

### `examPart`

| Wert | Bedeutung |
|---|---|
| `ap1` | Relevant für die gestreckte Abschlussprüfung Teil 1 |
| `ap2` | Relevant für die gestreckte Abschlussprüfung Teil 2 |
| `both` | Relevant für beide Prüfungsteile |

### `difficulty`

| Wert | Bedeutung |
|---|---|
| `beginner` | Einsteiger |
| `intermediate` | Fortgeschritten |
| `advanced` | Profi |

### `origin`

```json
{ "kind": "ownWork" }
```

Im öffentlichen Repository ist **ausschließlich** `ownWork` zulässig — das erzwingt `ContentValidator` als Fehler (`error`), nicht nur als Warnung. Siehe [CONTRIBUTING.md](../CONTRIBUTING.md#wichtigste-regel-nur-selbst-formulierter-content) für die Begründung.

Das Modell kennt zusätzlich `publicSource`:

```json
{ "kind": "publicSource", "url": "https://beispiel.tld/quelle" }
```

Diese Variante ist im Code vorgesehen, wird von der aktuellen Repository-Policy aber nicht akzeptiert — Beiträge damit schlagen bei der Validierung fehl.

---

## Lesson (Hands-on-Lektion)

Dateiort: `Sources/LearnCore/Content/Resources/lessons/<id>.json` — eine JSON-Datei pro Lektion, Wurzelobjekt ist das `Lesson`-Objekt selbst (kein umschließendes Array).

| Feld | Typ | Pflicht | Beschreibung |
|---|---|---|---|
| `schemaVersion` | Int | ja | Aktuell `1`. |
| `id` | String | ja | Eindeutig über alle Lektionen. Konvention: `<track>-<thema>`, z. B. `web-nginx-basics`. |
| `title` | String | ja | Anzeigetitel. |
| `summary` | String | ja | Kurzbeschreibung (1–2 Sätze), erscheint in Listen. |
| `track` | String (Enum) | ja | Siehe [`track`](#track-nur-lesson) oben. |
| `lernfelder` | [Int] | ja (kann leer sein) | Siehe [`lernfelder`](#lernfelder) oben. |
| `examPart` | String (Enum) | ja | Siehe [`examPart`](#exampart) oben. |
| `difficulty` | String (Enum) | ja | Siehe [`difficulty`](#difficulty) oben. |
| `prerequisites` | [String] | nein (Default `[]`) | IDs anderer Lektionen. Müssen existieren und dürfen nicht die eigene ID enthalten. |
| `origin` | Objekt | nein (Default `ownWork`) | Siehe [`origin`](#origin) oben — im Repository stets `ownWork` angeben. |
| `steps` | [Step] | ja, mind. 1 Eintrag | Die Lernschritte, siehe unten. |

### Step

| Feld | Typ | Pflicht | Beschreibung |
|---|---|---|---|
| `teaching` | String | ja | Erklärung/Theorie, die vor der Aufgabe angezeigt wird. |
| `prompt` | String | ja, nicht leer | Die Aufgabenstellung. |
| `expectation` | Objekt | ja | Erwartete Lösung, siehe [Expectation](#expectation) unten. |
| `hints` | [String] | nein (kann leer sein, erzeugt aber eine Warnung) | Gestaffelte Hinweise; jeder `hint`-Aufruf in der Shell zeigt den nächsten Eintrag. |
| `explanation` | String | ja, nicht leer | Wird nach korrekter Lösung gezeigt: das *Warum*. |

### Expectation

Unterschieden über das Feld `kind`.

**`command`** — ein Kommandozeilenbefehl, geprüft per Regex:

```json
{
  "kind": "command",
  "pattern": "^(sudo )?apt(-get)? update$",
  "canonical": "sudo apt update",
  "nearMisses": [
    {
      "pattern": "^(sudo )?apt(-get)? upgrade$",
      "feedback": "upgrade installiert neuere Versionen bereits vorhandener Pakete. Gesucht ist der Schritt davor: die Paketliste neu einlesen."
    }
  ]
}
```

| Feld | Typ | Pflicht | Beschreibung |
|---|---|---|---|
| `pattern` | String (Regex) | ja | Muss ein gültiger Regulärer Ausdruck sein (case-insensitive geprüft). Gegen dieses Muster wird die Eingabe des Lernenden gematcht. |
| `canonical` | String | ja | Die Musterlösung. **Muss selbst gegen `pattern` matchen** — sonst schlägt die Validierung fehl. |
| `nearMisses` | [NearMiss] | nein (Default `[]`) | Typische Fehleingaben mit eigenem `pattern` und gezieltem `feedback`-Text. |

`NearMiss`:

| Feld | Typ | Pflicht | Beschreibung |
|---|---|---|---|
| `pattern` | String (Regex) | ja | Muster, das den typischen Fehler erkennt. |
| `feedback` | String | ja | Gezielte Rückmeldung, warum das nicht die gesuchte Lösung ist. |

**`multipleChoice`** — Auswahlfrage:

```json
{
  "kind": "multipleChoice",
  "options": [
    "/etc/nginx/conf.d",
    "/etc/nginx/sites-available",
    "/etc/nginx/sites-enabled",
    "/var/www/html"
  ],
  "correct": 1
}
```

| Feld | Typ | Pflicht | Beschreibung |
|---|---|---|---|
| `options` | [String] | ja, mind. 2 | Antwortoptionen. |
| `correct` | Int | ja | 0-basierter Index der richtigen Option; muss innerhalb von `options` liegen. |

**`freeText`** — Freitext mit Stichwortprüfung:

```json
{
  "kind": "freeText",
  "keywords": ["reload", "worker"]
}
```

| Feld | Typ | Pflicht | Beschreibung |
|---|---|---|---|
| `keywords` | [String] | ja, mind. 1 | Alle Stichwörter müssen (unabhängig von Groß-/Kleinschreibung) in der Eingabe vorkommen, damit sie als richtig gilt. |

### Vollständiges Lesson-Beispiel

Siehe `Sources/LearnCore/Content/Resources/lessons/web-nginx-basics.json` im Repository für ein reales, vollständiges Beispiel mit sechs Schritten (alle drei Expectation-Varianten kommen dort vor).

Minimal-Beispiel mit einem Schritt:

```json
{
  "schemaVersion": 1,
  "id": "network-check-interface",
  "title": "Netzwerkschnittstellen unter Linux prüfen",
  "summary": "Den Status und die IP-Konfiguration der Netzwerkschnittstellen eines Linux-Systems anzeigen.",
  "track": "network",
  "lernfelder": [3, 9],
  "examPart": "ap1",
  "difficulty": "beginner",
  "prerequisites": [],
  "origin": { "kind": "ownWork" },
  "steps": [
    {
      "teaching": "Unter modernen Linux-Distributionen ersetzt das ip-Tool aus dem iproute2-Paket die älteren net-tools-Befehle wie ifconfig.",
      "prompt": "Zeige alle Netzwerkschnittstellen mit ihrer aktuellen IP-Konfiguration an.",
      "expectation": {
        "kind": "command",
        "pattern": "^ip a(ddr(ess)?)?( show)?$",
        "canonical": "ip a",
        "nearMisses": [
          {
            "pattern": "^ifconfig( -a)?$",
            "feedback": "Funktioniert auf vielen Systemen noch, gilt aber als veraltet. Das moderne Werkzeug aus iproute2 heißt anders."
          }
        ]
      },
      "hints": [
        "Das moderne Werkzeug aus dem iproute2-Paket heißt schlicht 'ip'.",
        "Das Unterkommando für Adressen ist eine Abkürzung von 'address'."
      ],
      "explanation": "ip a (Kurzform von ip address show) listet alle Interfaces mit Status, MAC- und IP-Adressen. Es ersetzt das ältere ifconfig, das in vielen Distributionen nicht mehr standardmäßig installiert ist."
    }
  ]
}
```

---

## Question (Prüfungsfrage)

Dateiort: `Sources/LearnCore/Content/Resources/questions/<thema>.json` — eine JSON-Datei enthält ein **Array** von `Question`-Objekten (mehrere Fragen pro Datei, thematisch gruppiert, z. B. `ap1-grundlagen.json`).

| Feld | Typ | Pflicht | Beschreibung |
|---|---|---|---|
| `schemaVersion` | Int | ja | Aktuell `1`. |
| `id` | String | ja | Eindeutig über alle Fragen. Konvention: `q-<thema>-<kurzbeschreibung>`, z. B. `q-net-subnet-hosts-26`. |
| `prompt` | String | ja, nicht leer | Die Fragestellung. |
| `lernfelder` | [Int] | ja (kann leer sein) | Siehe [`lernfelder`](#lernfelder) oben. |
| `examPart` | String (Enum) | ja | Siehe [`examPart`](#exampart) oben. |
| `difficulty` | String (Enum) | ja | Siehe [`difficulty`](#difficulty) oben. |
| `answer` | Objekt | ja | Antwortform, siehe [Answer](#answer) unten. |
| `explanation` | String | ja, nicht leer | Begründung der Lösung. |
| `origin` | Objekt | nein (Default `ownWork`) | Siehe [`origin`](#origin) oben — im Repository stets `ownWork` angeben. |

### Answer

Unterschieden über das Feld `kind`.

**`multipleChoice`**:

```json
{
  "kind": "multipleChoice",
  "options": [
    "Vertraulichkeit, Integrität, Verfügbarkeit",
    "Verschlüsselung, Sicherung, Protokollierung",
    "Authentifizierung, Autorisierung, Abrechnung",
    "Vertraulichkeit, Wirtschaftlichkeit, Verfügbarkeit"
  ],
  "correct": 0
}
```

| Feld | Typ | Pflicht | Beschreibung |
|---|---|---|---|
| `options` | [String] | ja, mind. 2 | Antwortoptionen. |
| `correct` | Int | ja | 0-basierter Index der richtigen Option. |

**`shortAnswer`**:

```json
{
  "kind": "shortAnswer",
  "accepted": ["MX", "MX-Record", "MX Record", "Mail Exchange"]
}
```

| Feld | Typ | Pflicht | Beschreibung |
|---|---|---|---|
| `accepted` | [String] | ja, mind. 1 | Alle akzeptierten Schreibweisen der richtigen Antwort. Mehrere gängige Varianten aufnehmen (Groß-/Kleinschreibung, Bindestrich, Abkürzung vs. ausgeschrieben). |

**`calculation`**:

```json
{
  "kind": "calculation",
  "expected": "16",
  "unit": "TB"
}
```

| Feld | Typ | Pflicht | Beschreibung |
|---|---|---|---|
| `expected` | String | ja, nicht leer | Exaktes Ergebnis, z. B. bei Subnetting- oder RAID-Kapazitätsaufgaben. |
| `unit` | String? | nein | Optionale Einheit (z. B. `"TB"`). Weglassen, wenn die Frage einheitenlos ist (z. B. reine Portnummer). |

### Vollständiges Question-Beispiel

Aus `Sources/LearnCore/Content/Resources/questions/ap1-grundlagen.json`:

```json
{
  "schemaVersion": 1,
  "id": "q-net-subnet-hosts-26",
  "prompt": "Wie viele nutzbare Hostadressen bietet das Netz 192.168.10.0/26?",
  "lernfelder": [3, 9],
  "examPart": "ap1",
  "difficulty": "beginner",
  "answer": { "kind": "calculation", "expected": "62" },
  "explanation": "Bei /26 bleiben 32 - 26 = 6 Hostbits, also 2^6 = 64 Adressen. Netz- und Broadcastadresse sind nicht an Hosts vergebbar: 64 - 2 = 62.",
  "origin": { "kind": "ownWork" }
}
```

Ein Beispiel je Antwortform (`multipleChoice`, `shortAnswer`, `calculation`) findet sich außerdem direkt im Repository unter `Sources/LearnCore/Content/Resources/questions/`.

---

## Validierungsregeln im Überblick

Der `ContentValidator` (`Sources/LearnCore/Content/ContentValidator.swift`) prüft beim `validate`-Kommando und in den Tests automatisch:

- IDs sind eindeutig (über alle Lektionen bzw. über alle Fragen hinweg).
- `origin` ist `ownWork` (sonst Fehler).
- `schemaVersion` entspricht der aktuellen Version (sonst Warnung).
- Lektionen haben mindestens einen Schritt; Schritte haben nicht-leere `prompt` und `explanation`.
- Fehlende `hints` erzeugen eine Warnung, keinen Fehler.
- `prerequisites` verweisen auf existierende IDs und enthalten nicht die eigene ID.
- Bei `command`-Schritten: `pattern` (und jedes `nearMiss.pattern`) sind gültige Regulären Ausdrücke; `canonical` matcht `pattern`.
- Bei `multipleChoice`: mindestens zwei Optionen, `correct` ist ein gültiger Index.
- Bei `freeText`: mindestens ein Stichwort.
- Bei Fragen mit `shortAnswer`: mindestens eine akzeptierte Antwort.
- Bei Fragen mit `calculation`: `expected` ist nicht leer.
- Fehlende `lernfelder` erzeugen eine Warnung, keinen Fehler.

Ein Beitrag ohne `[ERROR]`-Meldungen aus `swift test` bzw. dem `validate`-Kommando ist grundsätzlich mergefähig; `[WARNING]`-Meldungen sollten möglichst behoben werden.
