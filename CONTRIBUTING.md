# Beitragen zu FiSi-Trainer

Danke für dein Interesse, FiSi-Trainer mit Inhalten oder Code weiterzuentwickeln. Dieses Dokument beschreibt, wie neue Lektionen und Prüfungsfragen aufgebaut sind, welche Regeln dabei gelten und wie Code-Beiträge aussehen sollen.

## Inhaltsverzeichnis

- [Wichtigste Regel: nur selbst formulierter Content](#wichtigste-regel-nur-selbst-formulierter-content)
- [Eine neue Lektion beitragen](#eine-neue-lektion-beitragen)
- [Eine neue Prüfungsfrage beitragen](#eine-neue-prüfungsfrage-beitragen)
- [Lokal validieren](#lokal-validieren)
- [Code-Beiträge](#code-beiträge)
- [Pull-Request-Ablauf](#pull-request-ablauf)

## Wichtigste Regel: nur selbst formulierter Content

FiSi-Trainer orientiert sich thematisch an den Schwerpunkten der gestreckten Abschlussprüfung (AP1/AP2) und am Ausbildungsrahmenplan (Lernfelder 1–12). **Original-IHK-Prüfungsaufgaben sind urheberrechtlich geschützt** (u. a. durch den U-Form-Verlag, der die IHK-Prüfungen im Auftrag herausgibt) und dürfen **unter keinen Umständen** — auch nicht in umformulierter oder gekürzter Form — in dieses öffentliche Repository übernommen werden.

Das bedeutet konkret:

- Jede Lektion und jede Frage muss **komplett selbst formuliert** sein.
- Das Feld `origin` muss `{ "kind": "ownWork" }` sein. Der `ContentValidator` prüft das automatisch und lehnt jeden Beitrag mit einer anderen Origin als Fehler ab.
- Es ist ausdrücklich erwünscht, sich an *Themen* und *Schwierigkeitsgraden* realer Prüfungen zu orientieren (z. B. "Subnetting-Aufgabe auf /26-Niveau", "typischer Nginx-Setup-Ablauf"). Nicht erlaubt ist die wörtliche oder nahezu wörtliche Übernahme von Aufgabenstellungen, Antwortoptionen oder Fallbeschreibungen aus einer echten IHK-Prüfung oder einem Prüfungsvorbereitungsbuch.
- Im Zweifel: umformulieren, eigenes Beispiel-Szenario bauen, eigene Zahlenwerte wählen. Ein Pull Request, bei dem der Verdacht auf eine Übernahme besteht, wird abgelehnt.

`origin.publicSource(url:)` existiert im Datenmodell für den theoretischen Fall frei lizenzierter Fremdquellen mit Nachweis, ist im öffentlichen Repository aber aktuell **nicht** zugelassen — auch dafür würde der Validator einen Fehler werfen. Content-Beiträge müssen `ownWork` sein.

## Eine neue Lektion beitragen

Lektionen liegen als JSON-Dateien unter `Sources/LearnCore/Content/Resources/lessons/`. Schau dir als Vorlage `web-nginx-basics.json` im selben Verzeichnis an — dieselben Feldnamen und Konventionen gelten für jede neue Datei.

Kurzüberblick über die Pflichtfelder (die vollständige Referenz mit allen Typen und gültigen Werten steht in [docs/CONTENT_SCHEMA.md](docs/CONTENT_SCHEMA.md)):

- `schemaVersion`: aktuell immer `1`.
- `id`: eindeutiger, sprechender Bezeichner, z. B. `web-nginx-basics` (Track-Präfix + Kurzthema).
- `title`, `summary`: Titel und Kurzbeschreibung.
- `track`: einer von `web`, `database`, `network`, `virtualization`.
- `lernfelder`: Array von Lernfeld-Nummern (1–12), die zur Lektion passen.
- `examPart`: `ap1`, `ap2` oder `both`.
- `difficulty`: `beginner`, `intermediate` oder `advanced`.
- `prerequisites`: IDs anderer Lektionen, die inhaltlich sinnvoll vorher kommen (kann leer sein).
- `origin`: immer `{ "kind": "ownWork" }`.
- `steps`: Array von Lernschritten, mindestens einer.

Jeder Schritt (`Step`) besteht aus:

- `teaching`: die Erklärung, die vor der Aufgabe angezeigt wird.
- `prompt`: die eigentliche Aufgabenstellung.
- `expectation`: was als Lösung erwartet wird — eine von drei Varianten:
  - **`command`**: ein Kommandozeilenbefehl. `pattern` ist ein Regex (case-insensitive geprüft), gegen den die Eingabe des Lernenden geprüft wird. `canonical` ist die Musterlösung — sie muss selbst gegen `pattern` matchen, sonst schlägt die Validierung fehl. `nearMisses` ist eine Liste typischer Fehleingaben mit jeweils eigenem `pattern` und gezieltem `feedback` (z. B. "richtiges Werkzeug, falsche Option" statt nur "falsch").
  - **`multipleChoice`**: `options` (mindestens zwei) und `correct` als 0-basierter Index der richtigen Option.
  - **`freeText`**: `keywords`, eine Liste von Stichwörtern, die (unabhängig von Groß-/Kleinschreibung) alle in der Antwort vorkommen müssen.
- `hints`: gestaffelte Hinweise; jeder Aufruf von `hint` in der Shell zeigt den nächsten.
- `explanation`: wird nach einer korrekten Antwort gezeigt — das *Warum* hinter der Lösung. Darf nicht leer sein.

Praktische Hinweise:

- Formuliere `pattern` so tolerant wie sinnvoll (optionales `sudo`, alternative Schreibweisen), aber so eng, dass offensichtlich falsche Kommandos nicht durchrutschen.
- Baue mindestens einen `nearMiss` pro Kommando-Schritt ein, wenn ein naheliegender Fehler denkbar ist — das ist der eigentliche didaktische Mehrwert gegenüber einer reinen Richtig/Falsch-Prüfung.
- `explanation` sollte erklären, warum die Lösung funktioniert, nicht nur was sie tut.

## Eine neue Prüfungsfrage beitragen

Fragen liegen als JSON-Arrays unter `Sources/LearnCore/Content/Resources/questions/` (z. B. `ap1-grundlagen.json`, `ap2-systemintegration.json`), gruppiert nach Thema oder Prüfungsteil. Eine neue Frage kann an eine bestehende Datei angehängt oder in einer neuen Datei im selben Verzeichnis abgelegt werden — jede `.json`-Datei dort wird beim Start eingelesen.

Pflichtfelder einer `Question`:

- `schemaVersion`: aktuell `1`.
- `id`: eindeutig, sprechend, z. B. `q-net-subnet-hosts-26`.
- `prompt`: die Frage.
- `lernfelder`: betroffene Lernfelder.
- `examPart`: `ap1`, `ap2` oder `both`.
- `difficulty`: `beginner`, `intermediate` oder `advanced`.
- `answer`: eine von drei Varianten:
  - **`multipleChoice`**: `options` (mindestens zwei) und `correct` als 0-basierter Index.
  - **`shortAnswer`**: `accepted`, eine Liste akzeptierter Schreibweisen der richtigen Antwort (mindestens eine).
  - **`calculation`**: `expected` als exaktes Ergebnis (String) und optional `unit` (z. B. `"TB"`).
- `explanation`: die Begründung der Lösung. Darf nicht leer sein.
- `origin`: immer `{ "kind": "ownWork" }`.

Die vollständigen Beispiele stehen in [docs/CONTENT_SCHEMA.md](docs/CONTENT_SCHEMA.md).

## Lokal validieren

Bevor du einen Pull Request öffnest, prüfe deinen Beitrag lokal:

```bash
swift test
```

Die Tests in `Tests/LearnCoreTests` laden die gesamte Content-Bibliothek und lassen sie durch den `ContentValidator` laufen — unter anderem wird geprüft:

- Eindeutigkeit aller Lektions- und Fragen-IDs.
- `origin` ist überall `ownWork`.
- Keine leeren Aufgabenstellungen/Erklärungen.
- Gültige Regex-Muster bei `command`-Schritten, und dass die `canonical`-Lösung ihr eigenes Muster erfüllt.
- Gültige Indizes bei `multipleChoice`.
- Nicht-leere Stichwort-/Antwortlisten.
- Existierende, nicht-zirkuläre `prerequisites`.

Alternativ liefert das `validate`-Kommando in der laufenden Shell (`swift run`, dann `validate`) denselben Bericht interaktiv. Ein sauberer Beitrag erzeugt keine `[ERROR]`-Zeilen; `[WARNING]`-Zeilen (z. B. fehlende Lernfeld-Zuordnung) sollten nach Möglichkeit ebenfalls behoben werden.

## Code-Beiträge

Für Änderungen an der App-Logik (nicht nur an Content-JSONs) gelten die Vorgaben aus [CLAUDE.md](CLAUDE.md):

- **Sprache:** Swift 6.x mit striktem Concurrency-Checking — Warnungen dazu sind ernst zu nehmen, nicht zu unterdrücken.
- **Architektur:** klare Trennung zwischen Lerninhalt (`LearnCore`, datengetrieben über JSON) und der interaktiven CLI-Shell (`SysAdminLearn`). Neue Logik gehört in das passende Target; UI-/Terminal-Code hat in `LearnCore` nichts verloren.
- **Fehlerbehandlung:** `Result` oder `throws` für alles, was fehlschlagen kann (insbesondere Systemzugriffe). **Keine Force-Unwraps (`!`)**.
- **Abhängigkeiten:** keine neuen externen SPM-Pakete ohne triftigen Grund — bevorzugt werden native `Foundation`-APIs. Wenn eine Dependency wirklich nötig scheint, das im PR begründen.

Build- und Testbefehle:

```bash
swift build
swift run
swift test
```

## Pull-Request-Ablauf

1. Fork erstellen, Branch von `main` abzweigen.
2. Änderung vornehmen (Content und/oder Code).
3. Lokal `swift test` ausführen — muss ohne `[ERROR]`-Meldungen und ohne fehlgeschlagene Tests durchlaufen.
4. Pull Request öffnen mit kurzer Beschreibung, was hinzugefügt/geändert wurde und warum.
5. Die CI (`.github/workflows/ci.yml`) baut das Projekt und führt die Tests automatisch aus — ein grüner Check ist Voraussetzung für den Merge.

Bei Fragen: ein Issue im Repository öffnen.
