# FiSi-Trainer

![CI](https://github.com/M3ttixx/FiSi-Trainer/actions/workflows/ci.yml/badge.svg)
![Swift 6](https://img.shields.io/badge/Swift-6.x-orange)
![Plattform](https://img.shields.io/badge/platform-macOS%2014%2B-blue)
![Lizenz](https://img.shields.io/badge/license-MIT-green)

Eine interaktive Swift-CLI-Lernanwendung für angehende **Fachinformatiker/-innen Systemintegration (FiSi)** — von der ersten Woche der Ausbildung bis zur gestreckten Abschlussprüfung (AP1/AP2).

## Worum geht es

Die Ausbildung zum FiSi zieht sich über drei bis dreieinhalb Jahre und deckt ein breites Spektrum ab: Netzwerke, Server, Datenbanken, Virtualisierung, Sicherheit. FiSi-Trainer begleitet diesen Weg als ständiger Trainingspartner im Terminal:

- **Hands-on-Lektionen** simulieren echte Systemadministrations-Aufgaben (Nginx installieren, einen Dienst prüfen, eine Firewall-Regel setzen, eine Datenbank absichern, einen Docker-Container bauen …) und geben direktes Feedback auf eingegebene Kommandos — inklusive gezieltem Feedback bei typischen Fehlern ("Near-Miss"-Erkennung: falsches Werkzeug, falsche Option, fehlende Rechte).
- **Prüfungsfragen-Bank** im Stil der gestreckten Abschlussprüfung, orientiert an den Lernfeldern (LF1–LF12) und AP1/AP2-Schwerpunkten — Multiple Choice, Kurzantwort und Rechenaufgaben (Subnetting, RAID, Wirtschaftlichkeit).
- **Spaced Repetition** (SM-2-Algorithmus): fällige Wiederholungen werden automatisch vorgeschlagen, statt alles gleich oft abzufragen.
- **Prüfungssimulation** (`exam ap1`/`exam ap2`): zufällig zusammengestellter Fragensatz mit gemessenem Zeitbudget und Auswertung je Lernfeld.
- **Statistik** (`stats`): Trefferquote je Lernfeld, damit klar ist, wo als Nächstes geübt werden sollte.
- **Fortschrittstracking** pro Lektion und Frage (abgeschlossene Schritte, genutzte Hinweise, Versuche, Wiederholungsintervalle) — versioniert und migrierbar über die gesamte Ausbildungszeit.
- **Content-Validierung** eingebaut in die App (`validate`-Kommando, `--validate`-Flag) und die Tests, damit fehlerhafte Lektionen/Fragen gar nicht erst live gehen.

Der Anspruch: Wissen nicht nur lesen, sondern in einer sicheren, simulierten Umgebung tatsächlich tippen und anwenden — ohne einen echten Server zu riskieren.

## Features im Detail

- Lernpfade ("Tracks") nach Themenbereich: Webserver & Proxies, Datenbanken, Netzwerk & Sicherheit, Virtualisierung.
- Jede Lektion ist einem oder mehreren Lernfeldern des Ausbildungsrahmenplans zugeordnet und markiert, ob sie für AP1, AP2 oder beide relevant ist.
- Drei Aufgabentypen: Kommandoeingabe mit Regex-Prüfung und Near-Miss-Feedback, Multiple-Choice, Freitext mit Stichwortprüfung.
- Gestaffelte Hinweise statt sofortiger Lösung — man kann sich Schritt für Schritt herantasten.
- Nach jeder richtigen Antwort eine Erklärung des *Warum*, nicht nur ein "richtig".
- Sämtlicher Lerninhalt liegt als reines JSON vor (kein Code) und lässt sich unabhängig von der App-Logik erweitern.

## Installation & Ausführung

Voraussetzungen: macOS 14 (Sonoma) oder neuer, Swift 6.x (z. B. über Xcode 16).

```bash
git clone https://github.com/M3ttixx/FiSi-Trainer.git
cd FiSi-Trainer

# Bauen
swift build

# Starten
swift run

# Tests ausführen (inkl. Content-Validierung)
swift test
```

Kommandozeilen-Flags (ohne interaktive Shell): `SysAdminLearn --help`, `--version`, `--validate` (prüft alle Inhalte und beendet sich mit Exit-Code 0/1 — nutzt das auch die CI).

## Kommandoübersicht

Innerhalb der interaktiven Shell (`swift run`) stehen folgende Kommandos zur Verfügung:

| Kommando | Beschreibung |
|---|---|
| `help` | Zeigt alle verfügbaren Kommandos. |
| `tracks` | Listet die vorhandenen Lernpfade (Tracks). |
| `list [track]` | Listet alle Lektionen, optional gefiltert nach Track (z. B. `list web`). |
| `start <lesson-id>` | Startet eine Lektion anhand ihrer ID. |
| `hint` | Zeigt den nächsten Hinweis zum aktuellen Schritt (nur während einer laufenden Lektion). |
| `skip` | Überspringt den aktuellen Schritt/die aktuelle Frage. |
| `review` | Startet eine Wiederholungsrunde mit den fälligen Prüfungsfragen (Spaced Repetition, SM-2). |
| `exam <ap1\|ap2>` | Simuliert eine Prüfung: zufälliger Fragensatz, gemessenes Zeitbudget, Auswertung je Lernfeld. |
| `stats` | Zeigt die Trefferquote je Lernfeld. |
| `status` | Zeigt den Lektions-Fortschritt. |
| `validate` | Prüft die geladene Content-Bibliothek auf Schema- und Konsistenzfehler. |
| `reset` | Setzt den gespeicherten Fortschritt zurück. |
| `quit` / `exit` | Beendet die Anwendung. |

Ist eine Lektion oder Frage aktiv, wird jede sonstige Eingabe als Lösungsversuch gewertet.

## Projektstruktur

Das Projekt ist als Swift-Package mit zwei Targets plus Tests aufgebaut ([`Package.swift`](Package.swift)):

```
Sources/
  LearnCore/            Bibliothek: Datenmodell, Content-Ladung, Verifikation, Lernlogik — kein UI-Code
    Models/               Lesson, Question, Curriculum (Track, Lernfeld, ExamPart, Difficulty, Origin)
    Content/              ContentLoader, ContentValidator, Resources/lessons/*.json, Resources/questions/*.json
    Verification/         PatternVerifier (Lektions-Schritte), AnswerChecker (Prüfungsfragen)
    Study/                SpacedRepetition (SM-2), ExamSimulator, Statistics
    Progress/             ProgressStore (versioniert, migrierbar)
  SysAdminLearn/        Ausführbares Target: die interaktive CLI-Shell
    Components/            Shell (REPL-Schleife, Kommando-Routing), Renderer
    Utils/                 Terminal (Ein-/Ausgabe, Farberkennung)
Tests/
  LearnCoreTests/        Tests gegen die gesamte Content-Bibliothek und alle LearnCore-Module
```

**LearnCore** kennt keine Terminal-Ein-/Ausgabe — es ist reine Modell- und Prüflogik und ließe sich auch von einer anderen Oberfläche (z. B. später einer GUI) wiederverwenden. **SysAdminLearn** ist die dünne CLI-Schicht darüber.

## Eigene Lektionen und Fragen beitragen

FiSi-Trainer lebt von Content, der über die gesamte Ausbildungszeit wächst. Wie man eine neue Lektion oder Prüfungsfrage beisteuert, welche Felder ein JSON-File braucht und was dabei zu beachten ist, steht in [CONTRIBUTING.md](CONTRIBUTING.md). Die vollständige Feldreferenz des JSON-Schemas liefert [docs/CONTENT_SCHEMA.md](docs/CONTENT_SCHEMA.md).

## Lizenz

Der Quellcode steht unter der [MIT-Lizenz](LICENSE).

**Wichtiger Hinweis zum Content:** IHK-Originalprüfungsaufgaben (z. B. aus dem U-Form-Verlag) sind urheberrechtlich geschützt und dürfen **nicht** in dieses Repository übernommen werden. Alle Lektionen und Fragen im Repository sind selbst formuliert (`origin.kind: "ownWork"`) — thematisch orientieren sie sich an realen Prüfungsschwerpunkten, übernehmen aber nie Wortlaut oder konkrete Aufgabenstellungen einer Original-IHK-Prüfung. Der `ContentValidator` erzwingt das für jeden Beitrag.
