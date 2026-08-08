import Foundation

/// Eine Hands-on-Lektion: eine Folge von Schritten, die den Lernenden durch ein
/// Setup führt. Lektionen sind Daten (JSON), nie Code — der Content wächst über
/// Jahre, die Logik bleibt stabil.
public struct Lesson: Codable, Sendable, Identifiable, Equatable {
    public let schemaVersion: Int
    public let id: String
    public let title: String
    public let summary: String
    public let track: Track
    public let lernfelder: [Lernfeld]
    public let examPart: ExamPart
    public let difficulty: Difficulty
    /// IDs anderer Lektionen, die vorher sinnvoll sind.
    public let prerequisites: [String]
    public let origin: Origin
    public let steps: [Step]

    public init(
        schemaVersion: Int = ContentSchema.current,
        id: String,
        title: String,
        summary: String,
        track: Track,
        lernfelder: [Lernfeld],
        examPart: ExamPart,
        difficulty: Difficulty,
        prerequisites: [String] = [],
        origin: Origin = .ownWork,
        steps: [Step]
    ) {
        self.schemaVersion = schemaVersion
        self.id = id
        self.title = title
        self.summary = summary
        self.track = track
        self.lernfelder = lernfelder
        self.examPart = examPart
        self.difficulty = difficulty
        self.prerequisites = prerequisites
        self.origin = origin
        self.steps = steps
    }
}

/// Ein einzelner Schritt innerhalb einer Lektion.
public struct Step: Codable, Sendable, Equatable {
    /// Erklärung, die vor der Aufgabe gezeigt wird.
    public let teaching: String
    /// Die Aufgabenstellung selbst.
    public let prompt: String
    public let expectation: Expectation
    /// Gestaffelte Hinweise — `hint` gibt jeweils den nächsten aus.
    public let hints: [String]
    /// Wird nach korrekter Lösung gezeigt: das *Warum* hinter der Antwort.
    public let explanation: String

    public init(
        teaching: String,
        prompt: String,
        expectation: Expectation,
        hints: [String],
        explanation: String
    ) {
        self.teaching = teaching
        self.prompt = prompt
        self.expectation = expectation
        self.hints = hints
        self.explanation = explanation
    }
}

/// Was von der Eingabe des Lernenden erwartet wird.
public enum Expectation: Codable, Sendable, Equatable {
    /// Ein Kommando. `pattern` ist ein Regex, `canonical` die Musterlösung,
    /// `nearMisses` liefern gezieltes Feedback für typische Fehler.
    case command(pattern: String, canonical: String, nearMisses: [NearMiss])
    case multipleChoice(options: [String], correct: Int)
    /// Freitext: alle Stichwörter müssen vorkommen (Groß-/Kleinschreibung egal).
    case freeText(keywords: [String])

    private enum CodingKeys: String, CodingKey {
        case kind, pattern, canonical, nearMisses, options, correct, keywords
    }

    private enum Kind: String, Codable {
        case command, multipleChoice, freeText
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(Kind.self, forKey: .kind) {
        case .command:
            self = .command(
                pattern: try container.decode(String.self, forKey: .pattern),
                canonical: try container.decode(String.self, forKey: .canonical),
                nearMisses: try container.decodeIfPresent([NearMiss].self, forKey: .nearMisses) ?? []
            )
        case .multipleChoice:
            self = .multipleChoice(
                options: try container.decode([String].self, forKey: .options),
                correct: try container.decode(Int.self, forKey: .correct)
            )
        case .freeText:
            self = .freeText(keywords: try container.decode([String].self, forKey: .keywords))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .command(let pattern, let canonical, let nearMisses):
            try container.encode(Kind.command, forKey: .kind)
            try container.encode(pattern, forKey: .pattern)
            try container.encode(canonical, forKey: .canonical)
            try container.encode(nearMisses, forKey: .nearMisses)
        case .multipleChoice(let options, let correct):
            try container.encode(Kind.multipleChoice, forKey: .kind)
            try container.encode(options, forKey: .options)
            try container.encode(correct, forKey: .correct)
        case .freeText(let keywords):
            try container.encode(Kind.freeText, forKey: .kind)
            try container.encode(keywords, forKey: .keywords)
        }
    }
}

/// Ein typischer Fehlversuch und die passende Rückmeldung dazu. Das ist der
/// eigentliche Lerneffekt: „richtiges Werkzeug, falsche Option" statt „falsch".
public struct NearMiss: Codable, Sendable, Equatable {
    public let pattern: String
    public let feedback: String

    public init(pattern: String, feedback: String) {
        self.pattern = pattern
        self.feedback = feedback
    }
}
