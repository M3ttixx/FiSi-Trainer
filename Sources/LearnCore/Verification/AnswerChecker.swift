import Foundation

/// Prüft Antworten auf Prüfungsfragen (`Answer`), analog zu `PatternVerifier`
/// für Lektions-Schritte (`Expectation`). Beide teilen dieselbe Normalisierung,
/// damit Tippstil (Groß-/Kleinschreibung, Leerzeichen) nirgends über
/// richtig/falsch entscheidet.
public struct AnswerChecker: Sendable {
    public init() {}

    public func check(_ input: String, against answer: Answer) -> Outcome {
        let normalized = PatternVerifier.normalize(input)
        guard !normalized.isEmpty else { return .incorrect }

        switch answer {
        case .multipleChoice(let options, let correct):
            guard let chosen = PatternVerifier.choiceIndex(from: normalized, options: options) else {
                return .closeButWrong(
                    feedback: "Bitte eine Option wählen — Zahl (1–\(options.count)) oder Buchstabe."
                )
            }
            return chosen == correct ? .correct : .incorrect

        case .shortAnswer(let accepted):
            let normalizedAccepted = Set(accepted.map(PatternVerifier.normalize))
            return normalizedAccepted.contains(normalized) ? .correct : .incorrect

        case .calculation(let expected, let unit):
            return checkCalculation(normalized, expected: expected, unit: unit)
        }
    }

    /// Zahlenantworten erlauben Komma statt Punkt und eine optionale,
    /// mitgetippte Einheit — beides gängige, korrekte Schreibweisen.
    private func checkCalculation(_ normalized: String, expected: String, unit: String?) -> Outcome {
        var candidate = normalized
        if let unit {
            let normalizedUnit = PatternVerifier.normalize(unit)
            if candidate.hasSuffix(normalizedUnit) {
                candidate = String(candidate.dropLast(normalizedUnit.count)).trimmingCharacters(in: .whitespaces)
            }
        }
        candidate = candidate.replacingOccurrences(of: ",", with: ".")
        let normalizedExpected = PatternVerifier.normalize(expected).replacingOccurrences(of: ",", with: ".")

        if candidate == normalizedExpected {
            return .correct
        }
        if let candidateValue = Double(candidate), let expectedValue = Double(normalizedExpected) {
            if abs(candidateValue - expectedValue) < 0.0001 {
                return .correct
            }
            // Nah dran (z. B. Rundungsdifferenz) verdient gezieltes Feedback;
            // eine deutlich andere Zahl ist schlicht falsch, keine Einheiten-
            // Verwechslung.
            let tolerance = max(abs(expectedValue) * 0.02, 0.5)
            if abs(candidateValue - expectedValue) <= tolerance {
                return .closeButWrong(feedback: "Nah dran — prüfe Rundung, Vorzeichen oder Einheit noch einmal.")
            }
        }
        return .incorrect
    }
}
