import Foundation

/// Eine Prüfungsfrage im Stil der gestreckten Abschlussprüfung.
///
/// Wichtig: `origin` muss im öffentlichen Repository `.ownWork` sein.
/// IHK-Originalaufgaben sind urheberrechtlich geschützt; hier stehen selbst
/// formulierte Fragen zu denselben Themen.
public struct Question: Codable, Sendable, Identifiable, Equatable {
    public let schemaVersion: Int
    public let id: String
    public let prompt: String
    public let lernfelder: [Lernfeld]
    public let examPart: ExamPart
    public let difficulty: Difficulty
    public let answer: Answer
    /// Das *Warum* hinter der Lösung — ohne das ist eine Frage nur ein Quiz.
    public let explanation: String
    public let origin: Origin

    public init(
        schemaVersion: Int = ContentSchema.current,
        id: String,
        prompt: String,
        lernfelder: [Lernfeld],
        examPart: ExamPart,
        difficulty: Difficulty,
        answer: Answer,
        explanation: String,
        origin: Origin = .ownWork
    ) {
        self.schemaVersion = schemaVersion
        self.id = id
        self.prompt = prompt
        self.lernfelder = lernfelder
        self.examPart = examPart
        self.difficulty = difficulty
        self.answer = answer
        self.explanation = explanation
        self.origin = origin
    }
}

/// Antwortform einer Prüfungsfrage.
public enum Answer: Codable, Sendable, Equatable {
    case multipleChoice(options: [String], correct: Int)
    /// Kurzantwort: akzeptierte Schreibweisen der Lösung.
    case shortAnswer(accepted: [String])
    /// Rechenaufgabe (Subnetting, Speicherbedarf …) mit exakter Lösung.
    case calculation(expected: String, unit: String?)

    private enum CodingKeys: String, CodingKey {
        case kind, options, correct, accepted, expected, unit
    }

    private enum Kind: String, Codable {
        case multipleChoice, shortAnswer, calculation
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(Kind.self, forKey: .kind) {
        case .multipleChoice:
            self = .multipleChoice(
                options: try container.decode([String].self, forKey: .options),
                correct: try container.decode(Int.self, forKey: .correct)
            )
        case .shortAnswer:
            self = .shortAnswer(accepted: try container.decode([String].self, forKey: .accepted))
        case .calculation:
            self = .calculation(
                expected: try container.decode(String.self, forKey: .expected),
                unit: try container.decodeIfPresent(String.self, forKey: .unit)
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .multipleChoice(let options, let correct):
            try container.encode(Kind.multipleChoice, forKey: .kind)
            try container.encode(options, forKey: .options)
            try container.encode(correct, forKey: .correct)
        case .shortAnswer(let accepted):
            try container.encode(Kind.shortAnswer, forKey: .kind)
            try container.encode(accepted, forKey: .accepted)
        case .calculation(let expected, let unit):
            try container.encode(Kind.calculation, forKey: .kind)
            try container.encode(expected, forKey: .expected)
            try container.encodeIfPresent(unit, forKey: .unit)
        }
    }
}
