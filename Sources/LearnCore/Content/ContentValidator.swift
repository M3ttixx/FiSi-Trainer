import Foundation

/// Ein gefundener Mangel im Content.
public struct ValidationIssue: Sendable, Equatable, CustomStringConvertible {
    public enum Severity: String, Sendable {
        case error
        case warning
    }

    public let severity: Severity
    public let subject: String
    public let message: String

    public var description: String {
        "[\(severity.rawValue.uppercased())] \(subject): \(message)"
    }
}

/// Prüft die Inhaltsbibliothek auf alles, was zur Laufzeit sonst still
/// schiefgeht — und auf die Lizenzregel für das öffentliche Repository.
///
/// Läuft als `validate`-Kommando und als Test, damit Content-Beiträge sich
/// selbst prüfen.
public struct ContentValidator: Sendable {
    public init() {}

    public func validate(_ library: ContentLibrary) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        issues.append(contentsOf: validateLessons(library))
        issues.append(contentsOf: validateQuestions(library))
        return issues
    }

    // MARK: - Lektionen

    private func validateLessons(_ library: ContentLibrary) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        let ids = Set(library.lessons.map(\.id))

        for id in duplicates(in: library.lessons.map(\.id)) {
            issues.append(.init(severity: .error, subject: "Lektion \(id)", message: "ID kommt mehrfach vor."))
        }

        for lesson in library.lessons {
            let subject = "Lektion \(lesson.id)"

            if lesson.schemaVersion != ContentSchema.current {
                issues.append(.init(
                    severity: .warning,
                    subject: subject,
                    message: "schemaVersion \(lesson.schemaVersion) weicht von der aktuellen (\(ContentSchema.current)) ab."
                ))
            }
            if lesson.origin != .ownWork {
                issues.append(.init(
                    severity: .error,
                    subject: subject,
                    message: "Nur selbst formulierte Inhalte (origin = ownWork) dürfen ins öffentliche Repository."
                ))
            }
            if lesson.steps.isEmpty {
                issues.append(.init(severity: .error, subject: subject, message: "Enthält keine Schritte."))
            }
            if lesson.lernfelder.isEmpty {
                issues.append(.init(severity: .warning, subject: subject, message: "Keinem Lernfeld zugeordnet — fehlt später in der Statistik."))
            }
            for prerequisite in lesson.prerequisites where !ids.contains(prerequisite) {
                issues.append(.init(
                    severity: .error,
                    subject: subject,
                    message: "Voraussetzung '\(prerequisite)' existiert nicht."
                ))
            }
            if lesson.prerequisites.contains(lesson.id) {
                issues.append(.init(severity: .error, subject: subject, message: "Setzt sich selbst voraus."))
            }

            for (index, step) in lesson.steps.enumerated() {
                issues.append(contentsOf: validate(step: step, index: index, subject: subject))
            }
        }
        return issues
    }

    private func validate(step: Step, index: Int, subject: String) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        let where_ = "\(subject), Schritt \(index + 1)"

        if step.prompt.trimmed.isEmpty {
            issues.append(.init(severity: .error, subject: where_, message: "Leere Aufgabenstellung."))
        }
        if step.explanation.trimmed.isEmpty {
            issues.append(.init(severity: .error, subject: where_, message: "Leere Erklärung — das Warum ist der Lerneffekt."))
        }
        if step.hints.isEmpty {
            issues.append(.init(severity: .warning, subject: where_, message: "Keine Hinweise hinterlegt."))
        }

        switch step.expectation {
        case .command(let pattern, let canonical, let nearMisses):
            issues.append(contentsOf: checkRegex(pattern, at: where_))
            for miss in nearMisses {
                issues.append(contentsOf: checkRegex(miss.pattern, at: "\(where_) (nearMiss)"))
            }
            // Die Musterlösung muss ihr eigenes Muster erfüllen — sonst ist eine
            // der beiden Seiten falsch, und das merkt man sonst erst im Betrieb.
            if PatternVerifier().check(canonical, against: step.expectation) != .correct {
                issues.append(.init(
                    severity: .error,
                    subject: where_,
                    message: "Musterlösung '\(canonical)' erfüllt das eigene Muster nicht."
                ))
            }
        case .multipleChoice(let options, let correct):
            if options.count < 2 {
                issues.append(.init(severity: .error, subject: where_, message: "Mindestens zwei Optionen nötig."))
            }
            if !options.indices.contains(correct) {
                issues.append(.init(severity: .error, subject: where_, message: "Index der richtigen Antwort liegt außerhalb der Optionen."))
            }
        case .freeText(let keywords):
            if keywords.isEmpty {
                issues.append(.init(severity: .error, subject: where_, message: "Keine Stichwörter — jede Antwort gälte als falsch."))
            }
        }
        return issues
    }

    // MARK: - Fragen

    private func validateQuestions(_ library: ContentLibrary) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []

        for id in duplicates(in: library.questions.map(\.id)) {
            issues.append(.init(severity: .error, subject: "Frage \(id)", message: "ID kommt mehrfach vor."))
        }

        for question in library.questions {
            let subject = "Frage \(question.id)"

            if question.origin != .ownWork {
                issues.append(.init(
                    severity: .error,
                    subject: subject,
                    message: "Nur selbst formulierte Fragen (origin = ownWork) dürfen ins öffentliche Repository."
                ))
            }
            if question.schemaVersion != ContentSchema.current {
                issues.append(.init(
                    severity: .warning,
                    subject: subject,
                    message: "schemaVersion \(question.schemaVersion) weicht von der aktuellen (\(ContentSchema.current)) ab."
                ))
            }
            if question.prompt.trimmed.isEmpty {
                issues.append(.init(severity: .error, subject: subject, message: "Leere Fragestellung."))
            }
            if question.explanation.trimmed.isEmpty {
                issues.append(.init(severity: .error, subject: subject, message: "Leere Erklärung."))
            }
            if question.lernfelder.isEmpty {
                issues.append(.init(severity: .warning, subject: subject, message: "Keinem Lernfeld zugeordnet."))
            }

            switch question.answer {
            case .multipleChoice(let options, let correct):
                if options.count < 2 {
                    issues.append(.init(severity: .error, subject: subject, message: "Mindestens zwei Optionen nötig."))
                }
                if !options.indices.contains(correct) {
                    issues.append(.init(severity: .error, subject: subject, message: "Index der richtigen Antwort liegt außerhalb der Optionen."))
                }
            case .shortAnswer(let accepted):
                if accepted.isEmpty {
                    issues.append(.init(severity: .error, subject: subject, message: "Keine akzeptierte Antwort hinterlegt."))
                }
            case .calculation(let expected, _):
                if expected.trimmed.isEmpty {
                    issues.append(.init(severity: .error, subject: subject, message: "Kein Ergebnis hinterlegt."))
                }
            }
        }
        return issues
    }

    // MARK: - Helfer

    private func checkRegex(_ pattern: String, at subject: String) -> [ValidationIssue] {
        do {
            _ = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            return []
        } catch {
            return [.init(severity: .error, subject: subject, message: "Ungültiges Muster '\(pattern)': \(error.localizedDescription)")]
        }
    }

    private func duplicates(in ids: [String]) -> [String] {
        var seen: Set<String> = []
        var duplicated: Set<String> = []
        for id in ids where !seen.insert(id).inserted {
            duplicated.insert(id)
        }
        return duplicated.sorted()
    }
}

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
