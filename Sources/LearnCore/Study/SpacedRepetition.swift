import Foundation

/// SM-2-Spaced-Repetition (SuperMemo 2): berechnet aus dem bisherigen Stand
/// einer Frage und der Qualität der letzten Antwort das nächste
/// Wiederholungsintervall. Reine Funktion, kein Zustand — leicht testbar und
/// unabhängig von Verifikation/Persistenz.
public enum SpacedRepetition {
    /// Bildet ein `Outcome` auf die SM-2-Qualitätsskala (0–5) ab.
    /// `correct` zählt als "leicht gewusst", `closeButWrong` als "gewusst,
    /// aber unsicher", `incorrect` als "nicht gewusst" — SM-2 setzt bei
    /// Werten unter 3 die Wiederholungsserie zurück.
    public static func quality(for outcome: Outcome) -> Int {
        switch outcome {
        case .correct: 5
        case .closeButWrong: 3
        case .incorrect: 0
        }
    }

    /// Berechnet den nächsten Stand nach einer Antwort. `now` ist injizierbar,
    /// damit Tests nicht von der Systemzeit abhängen.
    public static func schedule(
        current: QuestionProgress,
        outcome: Outcome,
        now: Date = .now
    ) -> QuestionProgress {
        var next = current
        let q = quality(for: outcome)

        if q < 3 {
            next.repetitions = 0
            next.intervalDays = 1
            next.incorrectCount += 1
        } else {
            switch next.repetitions {
            case 0: next.intervalDays = 1
            case 1: next.intervalDays = 6
            default: next.intervalDays = Int((Double(next.intervalDays) * next.easinessFactor).rounded())
            }
            next.repetitions += 1
            next.correctCount += 1
        }

        let delta = 0.1 - Double(5 - q) * (0.08 + Double(5 - q) * 0.02)
        next.easinessFactor = max(1.3, next.easinessFactor + delta)
        next.dueDate = Calendar.current.date(byAdding: .day, value: max(next.intervalDays, 1), to: now) ?? now
        return next
    }
}
