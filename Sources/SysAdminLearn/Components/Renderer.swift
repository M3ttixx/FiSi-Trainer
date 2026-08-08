import Foundation
import LearnCore

/// Kapselt jede Bildschirmausgabe der Shell an einer Stelle.
struct Renderer {
    func banner() {
        let art = """
          █████▒██▓  █████    ██████ ██▓
        ▓██   ▒▓██▒▒██▓  ██▒▒██    ▒▓██▒
        ▒████ ░▒██▒▒██▒  ██░░ ▓██▄  ▒██▒
        ░▓█▒  ░░██░░██  █▀ ░  ▒   ██▒██░
        ░▒█░   ░██░░▒███▒█▄ ▒██████▒░██░
         ▒ ░   ░▓  ░░ ▒▒░ ▒ ▒ ▒▓▒ ▒ ░▓
         ░      ▒ ░ ░ ▒░  ░ ░ ░▒  ░ ░▒ ░
         ░ ░    ▒ ░   ░   ░  ░  ░  ░▒ ░
                ░      ░         ░  ░
        """
        print("")
        print(art.styled(.cyan))
        print("  T R A I N E R".styled(.bold).styled(.magenta))
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
            ("skip", "Aktuellen Schritt/aktuelle Frage überspringen"),
            ("review", "Fällige Prüfungsfragen wiederholen (Spaced Repetition)"),
            ("exam <ap1|ap2>", "Prüfung simulieren, mit Zeitbudget und Auswertung je Lernfeld"),
            ("stats", "Trefferquote je Lernfeld anzeigen"),
            ("status", "Lektions-Fortschritt anzeigen"),
            ("validate", "Alle Inhalte auf Fehler prüfen"),
            ("reset", "Fortschritt zurücksetzen"),
            ("quit", "Beenden"),
        ]
        print("Kommandos:".styled(.bold))
        let width = rows.map(\.0.count).max() ?? 0
        for (command, description) in rows {
            print("  \(command.padding(toLength: width, withPad: " ", startingAt: 0))  \(description)")
        }
        print("\nWährend einer laufenden Lektion/Frage gilt jede andere Eingabe als Lösungsversuch.".styled(.dim))
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
            print("      \(lesson.track.rawValue) · \(difficultyTag(lesson.difficulty)) · \(lesson.examPart.label) · \(lernfelder)".styled(.dim))
        }
    }

    private func difficultyTag(_ difficulty: Difficulty) -> String {
        let color: ANSI = switch difficulty {
        case .beginner: .green
        case .intermediate: .yellow
        case .advanced: .red
        }
        return difficulty.label.styled(color)
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

    /// `hintAvailable`: Lektions-Schritte haben gestaffelte Hinweise, Fragen
    /// in Review/Exam nicht — die Fehlermeldung soll nur dort auf 'hint'
    /// verweisen, wo das Kommando tatsächlich etwas tut.
    func outcome(_ outcome: Outcome, hintAvailable: Bool = true) {
        switch outcome {
        case .correct:
            print("✔ Richtig.".styled(.green))
        case .closeButWrong(let feedback):
            print("~ Fast: \(feedback)".styled(.yellow))
        case .incorrect:
            let suffix = hintAvailable ? " 'hint' für einen Hinweis, 'skip' zum Überspringen." : " 'skip' zum Überspringen."
            print("✘ Nicht richtig.\(suffix)".styled(.red))
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

    // MARK: - Prüfungsfragen (Review & Exam)

    func question(_ question: Question, index: Int, total: Int) {
        print("")
        let lernfelder = question.lernfelder.map(\.label).joined(separator: ", ")
        print("Frage \(index + 1)/\(total)".styled(.magenta) + "  ·  \(lernfelder) · \(question.difficulty.label)".styled(.dim))
        print(question.prompt.styled(.bold))
        if case .multipleChoice(let options, _) = question.answer {
            for (i, option) in options.enumerated() {
                let letter = Character(UnicodeScalar(97 + i)!)
                print("   \(i + 1)/\(letter))  \(option)")
            }
        }
    }

    func reviewIntro(count: Int) {
        print("")
        print("Wiederholung: \(count) Frage(n)".styled(.bold).styled(.cyan))
    }

    func reviewComplete(correct: Int, total: Int) {
        print("")
        print("🎉 Wiederholung abgeschlossen: \(correct)/\(total) richtig.".styled(.green).styled(.bold))
    }

    func examIntro(examPart: ExamPart, count: Int, budget: TimeInterval) {
        print("")
        print("Prüfungssimulation \(examPart.label)".styled(.bold).styled(.cyan))
        print("\(count) Fragen · Zeitbudget ca. \(formatDuration(budget)) (wird gemessen, nicht hart abgebrochen)".styled(.dim))
    }

    func examResult(_ result: ExamResult) {
        print("")
        print("Ergebnis \(result.examPart.label)".styled(.bold).styled(.cyan))
        let scoreColor: ANSI = result.scorePercent >= 50 ? .green : .red
        print("  \(result.correct)/\(result.total) richtig (\(String(format: "%.0f", result.scorePercent)) %)".styled(scoreColor))
        let timeNote = result.elapsed <= result.budget ? "im Zeitbudget" : "über dem Zeitbudget"
        print("  Zeit: \(formatDuration(result.elapsed)) von \(formatDuration(result.budget)) — \(timeNote)".styled(.dim))
        print("")
        print("Nach Lernfeld:".styled(.bold))
        for lernfeld in result.perLernfeld.keys.sorted(by: { $0.rawValue < $1.rawValue }) {
            guard let tally = result.perLernfeld[lernfeld] else { continue }
            print("  \(lernfeld.label.styled(.cyan))  \(tally.correct)/\(tally.total)  (\(String(format: "%.0f", tally.accuracyPercent)) %)")
        }
    }

    func stats(_ stats: [LernfeldStat]) {
        if stats.isEmpty {
            print("Noch keine Fragen im Content vorhanden.".styled(.yellow))
            return
        }
        print("Trefferquote je Lernfeld:".styled(.bold))
        for stat in stats {
            let accuracyText = stat.accuracyPercent.map { String(format: "%.0f %%", $0) } ?? "noch nicht geübt"
            let dueText = stat.dueCount > 0 ? " · \(stat.dueCount) fällig".styled(.yellow) : ""
            print("  \(stat.lernfeld.label.styled(.cyan))  \(accuracyText)  (\(stat.answered) beantwortet)\(dueText)")
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remaining = Int(seconds) % 60
        return minutes > 0 ? "\(minutes) min \(remaining) s" : "\(remaining) s"
    }
}
