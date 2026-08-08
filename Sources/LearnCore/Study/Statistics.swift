import Foundation

/// Trefferquote und Übungsstand für ein einzelnes Lernfeld.
public struct LernfeldStat: Sendable, Identifiable {
    public var id: Lernfeld { lernfeld }
    public let lernfeld: Lernfeld
    public let correct: Int
    public let incorrect: Int
    public let dueCount: Int

    public var answered: Int { correct + incorrect }

    public var accuracyPercent: Double? {
        answered == 0 ? nil : Double(correct) / Double(answered) * 100
    }
}

/// Berechnet Fortschrittskennzahlen aus Content und Lernstand — reine
/// Funktionen ohne eigenen Zustand, damit sie sich leicht testen lassen.
public enum Statistics {
    /// Trefferquote je Lernfeld, absteigend nach Schwäche sortiert (wenig
    /// beantwortete/unsichere Lernfelder zuerst) — direkt verwendbar für
    /// "wo sollte ich als Nächstes üben?".
    public static func perLernfeld(library: ContentLibrary, state: ProgressState, now: Date = .now) -> [LernfeldStat] {
        Lernfeld.allCases.compactMap { lernfeld in
            let questions = library.questions.filter { $0.lernfelder.contains(lernfeld) }
            guard !questions.isEmpty else { return nil }

            var correct = 0
            var incorrect = 0
            var due = 0
            for question in questions {
                guard let progress = state.questions[question.id] else { continue }
                correct += progress.correctCount
                incorrect += progress.incorrectCount
                if progress.dueDate <= now { due += 1 }
            }
            return LernfeldStat(lernfeld: lernfeld, correct: correct, incorrect: incorrect, dueCount: due)
        }
        .sorted { lhs, rhs in
            switch (lhs.accuracyPercent, rhs.accuracyPercent) {
            case (nil, nil): return lhs.lernfeld.rawValue < rhs.lernfeld.rawValue
            case (nil, .some): return true
            case (.some, nil): return false
            case let (.some(a), .some(b)): return a < b
            }
        }
    }

    public static func dueQuestionCount(library: ContentLibrary, store: ProgressStore, now: Date = .now) -> Int {
        let ids = Set(library.questions.map(\.id))
        let due = store.dueQuestionIDs(asOf: now)
        return ids.intersection(due).count + (ids.count - store.snapshot.questions.keys.filter(ids.contains).count)
    }
}
