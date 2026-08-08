import LearnCore

/// Kapselt jede Bildschirmausgabe der Shell an einer Stelle.
struct Renderer {
    func banner() {
        print("")
        print("  FiSi-Trainer".styled(.bold).styled(.cyan))
        print("  Server-Setups, Netzwerke, Datenbanken — und Prüfungsvorbereitung für AP1/AP2.".styled(.dim))
        print("  Tippe 'help' für die Kommandoübersicht.\n")
    }

    func help() {
        let rows: [(String, String)] = [
            ("help", "Diese Übersicht anzeigen"),
            ("tracks", "Lernpfade auflisten"),
            ("list [track]", "Lektionen auflisten, optional gefiltert (web/database/network/virtualization)"),
            ("start <id>", "Eine Lektion starten"),
            ("hint", "Nächsten Hinweis zum aktuellen Schritt anzeigen"),
            ("skip", "Aktuellen Schritt überspringen"),
            ("status", "Eigenen Fortschritt anzeigen"),
            ("validate", "Alle Inhalte auf Fehler prüfen"),
            ("reset", "Fortschritt zurücksetzen"),
            ("quit", "Beenden"),
        ]
        print("Kommandos:".styled(.bold))
        let width = rows.map(\.0.count).max() ?? 0
        for (command, description) in rows {
            print("  \(command.padding(toLength: width, withPad: " ", startingAt: 0))  \(description)")
        }
        print("\nWährend einer laufenden Lektion gilt jede andere Eingabe als Lösungsversuch.".styled(.dim))
    }

    func tracks() {
        print("Lernpfade:".styled(.bold))
        for track in Track.allCases {
            print("  \(track.rawValue.styled(.cyan))  — \(track.title)")
        }
    }

    func lessonList(_ lessons: [Lesson], progressStore: ProgressStore) {
        if lessons.isEmpty {
            print("Keine Lektionen gefunden.".styled(.yellow))
            return
        }
        for lesson in lessons {
            let done = progressStore.progress(for: lesson.id).isCompleted
            let mark = done ? "✔".styled(.green) : " "
            let lernfelder = lesson.lernfelder.map(\.label).joined(separator: ", ")
            print("  \(mark) \(lesson.id.styled(.cyan))  \(lesson.title)")
            print("      \(lesson.track.rawValue) · \(lesson.difficulty.label) · \(lesson.examPart.label) · \(lernfelder)".styled(.dim))
        }
    }

    func lessonIntro(_ lesson: Lesson) {
        print("")
        print(lesson.title.styled(.bold).styled(.cyan))
        print(lesson.summary)
        print("Schritte: \(lesson.steps.count) · \(lesson.difficulty.label) · \(lesson.examPart.label)".styled(.dim))
        print("")
    }

    func step(_ step: Step, index: Int, total: Int) {
        print("")
        print("Schritt \(index + 1)/\(total)".styled(.magenta))
        print(step.teaching)
        print("")
        print("➜ \(step.prompt)".styled(.bold))
        if case .multipleChoice(let options, _) = step.expectation {
            for (i, option) in options.enumerated() {
                let letter = Character(UnicodeScalar(97 + i)!)
                print("   \(i + 1)/\(letter))  \(option)")
            }
        }
    }

    func outcome(_ outcome: Outcome) {
        switch outcome {
        case .correct:
            print("✔ Richtig.".styled(.green))
        case .closeButWrong(let feedback):
            print("~ Fast: \(feedback)".styled(.yellow))
        case .incorrect:
            print("✘ Nicht richtig. 'hint' für einen Hinweis, 'skip' zum Überspringen.".styled(.red))
        }
    }

    func explanation(_ text: String) {
        print("")
        print(text.styled(.dim))
    }

    func hint(_ text: String?) {
        if let text {
            print("Hinweis: \(text)".styled(.yellow))
        } else {
            print("Keine weiteren Hinweise für diesen Schritt.".styled(.dim))
        }
    }

    func lessonComplete(_ lesson: Lesson) {
        print("")
        print("🎉 Lektion abgeschlossen: \(lesson.title)".styled(.green).styled(.bold))
    }

    func status(_ library: ContentLibrary, store: ProgressStore) {
        let snapshot = store.snapshot
        let completed = snapshot.lessons.values.filter(\.isCompleted).count
        print("Fortschritt:".styled(.bold))
        print("  \(completed)/\(library.lessons.count) Lektionen abgeschlossen")
        for track in Track.allCases {
            let lessons = library.lessons(track: track)
            guard !lessons.isEmpty else { continue }
            let done = lessons.filter { store.progress(for: $0.id).isCompleted }.count
            print("  \(track.title): \(done)/\(lessons.count)")
        }
    }

    func validationReport(_ issues: [ValidationIssue]) {
        if issues.isEmpty {
            print("✔ Alle Inhalte sind gültig.".styled(.green))
            return
        }
        let errors = issues.filter { $0.severity == .error }
        let warnings = issues.filter { $0.severity == .warning }
        for issue in issues {
            let color: ANSI = issue.severity == .error ? .red : .yellow
            print(issue.description.styled(color))
        }
        print("")
        print("\(errors.count) Fehler, \(warnings.count) Warnungen.".styled(errors.isEmpty ? .yellow : .red))
    }

    func error(_ message: String) {
        print("Fehler: \(message)".styled(.red))
    }

    func info(_ message: String) {
        print(message.styled(.dim))
    }
}
