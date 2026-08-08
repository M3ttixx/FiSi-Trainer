import Foundation

/// Ergebnis eines simulierten Prüfungsdurchlaufs.
public struct ExamResult: Sendable {
    public let examPart: ExamPart
    public let total: Int
    public let correct: Int
    public let elapsed: TimeInterval
    public let budget: TimeInterval
    public let perLernfeld: [Lernfeld: LernfeldTally]

    public var scorePercent: Double {
        total == 0 ? 0 : Double(correct) / Double(total) * 100
    }
}

/// Trefferquote innerhalb eines Lernfelds.
public struct LernfeldTally: Sendable {
    public var correct: Int
    public var total: Int

    public var accuracyPercent: Double {
        total == 0 ? 0 : Double(correct) / Double(total) * 100
    }
}

/// Stellt Fragensätze für eine simulierte Prüfung zusammen und wertet sie aus.
///
/// Die Prüfung läuft ohne harten Countdown ab — ein CLI ohne Rohterminal-
/// Steuerung kann einzelne Eingaben nicht sauber unterbrechen, ohne die Shell
/// fragil zu machen. Stattdessen wird die Gesamtzeit gemessen und am Ende der
/// vorgesehenen Zeitbudget gegenübergestellt, wie bei einer Bearbeitungszeit-
/// Kontrolle auf Papier.
public struct ExamSimulator: Sendable {
    /// Sekunden Bearbeitungszeit pro Frage — grobe Annäherung an eine reale
    /// schriftliche Prüfung mit gemischten Formaten.
    private static let secondsPerQuestion: TimeInterval = 90

    public init() {}

    /// Wählt bis zu `count` Fragen zum gewünschten Prüfungsteil aus, mit
    /// deterministischer Durchmischung anhand des übergebenen Seeds — feste
    /// Seeds machen Tests reproduzierbar, `nil` mischt bei jedem Aufruf neu.
    public func selectQuestions(
        from library: ContentLibrary,
        examPart: ExamPart,
        count: Int = 10,
        seed: UInt64? = nil
    ) -> [Question] {
        var pool = library.questions(examPart: examPart)
        var generator: any RandomNumberGenerator = seed.map { SplitMix64(seed: $0) } ?? SystemRandomNumberGenerator()
        pool.shuffle(using: &generator)
        return Array(pool.prefix(count))
    }

    public func budget(for questionCount: Int) -> TimeInterval {
        Double(questionCount) * Self.secondsPerQuestion
    }

    /// Fasst eingesammelte Antworten zu einem Ergebnis zusammen.
    public func summarize(
        examPart: ExamPart,
        answered: [(question: Question, outcome: Outcome)],
        elapsed: TimeInterval
    ) -> ExamResult {
        var perLernfeld: [Lernfeld: LernfeldTally] = [:]
        var correctTotal = 0

        for (question, outcome) in answered {
            let isCorrect = outcome == .correct
            if isCorrect { correctTotal += 1 }
            for lernfeld in question.lernfelder {
                var tally = perLernfeld[lernfeld] ?? LernfeldTally(correct: 0, total: 0)
                tally.total += 1
                if isCorrect { tally.correct += 1 }
                perLernfeld[lernfeld] = tally
            }
        }

        return ExamResult(
            examPart: examPart,
            total: answered.count,
            correct: correctTotal,
            elapsed: elapsed,
            budget: budget(for: answered.count),
            perLernfeld: perLernfeld
        )
    }
}

/// Kleiner, deterministischer PRNG für reproduzierbare Tests — Foundation
/// bringt keinen seedbaren Generator mit.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
