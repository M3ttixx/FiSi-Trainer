import Foundation

/// Prüft Eingaben gegen Muster, ohne Befehle auszuführen.
///
/// Der Lernstoff ist Linux (`apt`, `systemctl`, `ufw`); auf einem macOS-Host
/// gäbe es diese Befehle gar nicht. Statt sie auszuführen, wird die Eingabe
/// normalisiert und gegen das erwartete Muster geprüft.
public struct PatternVerifier: Verifier {
    public init() {}

    public func check(_ input: String, against expectation: Expectation) -> Outcome {
        let normalized = Self.normalize(input)
        guard !normalized.isEmpty else { return .incorrect }

        switch expectation {
        case .command(let pattern, _, let nearMisses):
            if matches(normalized, pattern: pattern) {
                return .correct
            }
            for miss in nearMisses where matches(normalized, pattern: miss.pattern) {
                return .closeButWrong(feedback: miss.feedback)
            }
            return .incorrect

        case .multipleChoice(let options, let correct):
            guard let chosen = Self.choiceIndex(from: normalized, options: options) else {
                return .closeButWrong(
                    feedback: "Bitte eine Option wählen — Zahl (1–\(options.count)) oder Buchstabe."
                )
            }
            return chosen == correct ? .correct : .incorrect

        case .freeText(let keywords):
            let hits = keywords.filter { normalized.contains(Self.normalize($0)) }
            if hits.count == keywords.count { return .correct }
            if hits.isEmpty { return .incorrect }
            return .closeButWrong(
                feedback: "Teilweise richtig — \(hits.count) von \(keywords.count) Stichwörtern genannt. Es fehlt noch etwas."
            )
        }
    }

    // MARK: - Normalisierung

    /// Vereinheitlicht Eingaben, damit Tippstil nicht über richtig/falsch entscheidet:
    /// Kleinschreibung, kollabierte Leerzeichen, entfernte Quotes, kein Trailing-Semikolon.
    static func normalize(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        text = text.replacingOccurrences(of: "\"", with: "")
        text = text.replacingOccurrences(of: "'", with: "")
        while text.hasSuffix(";") {
            text.removeLast()
        }
        let parts = text.split(whereSeparator: \.isWhitespace)
        return parts.joined(separator: " ")
    }

    private func matches(_ normalized: String, pattern: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            // Defektes Muster darf nie als "richtig" durchgehen; der Validator
            // fängt solche Fälle vorab ab.
            return false
        }
        let range = NSRange(normalized.startIndex..<normalized.endIndex, in: normalized)
        return regex.firstMatch(in: normalized, options: [], range: range) != nil
    }

    /// Erlaubt "2", "b" oder den ausgeschriebenen Optionstext als Antwort.
    static func choiceIndex(from normalized: String, options: [String]) -> Int? {
        if let number = Int(normalized), number >= 1, number <= options.count {
            return number - 1
        }
        if normalized.count == 1, let letter = normalized.unicodeScalars.first {
            let offset = Int(letter.value) - Int(Character("a").unicodeScalars.first?.value ?? 97)
            if offset >= 0, offset < options.count {
                return offset
            }
        }
        return options.firstIndex { normalize($0) == normalized }
    }
}
