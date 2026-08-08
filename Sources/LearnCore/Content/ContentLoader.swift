import Foundation

/// Alle geladenen Inhalte in einer Struktur.
public struct ContentLibrary: Sendable {
    public let lessons: [Lesson]
    public let questions: [Question]

    public init(lessons: [Lesson], questions: [Question]) {
        self.lessons = lessons
        self.questions = questions
    }

    public func lesson(id: String) -> Lesson? {
        lessons.first { $0.id == id }
    }

    public func lessons(track: Track) -> [Lesson] {
        lessons.filter { $0.track == track }
    }

    public func lessons(lernfeld: Lernfeld) -> [Lesson] {
        lessons.filter { $0.lernfelder.contains(lernfeld) }
    }

    public func questions(examPart: ExamPart) -> [Question] {
        questions.filter { $0.examPart.covers(examPart) }
    }
}

public enum ContentError: Error, CustomStringConvertible {
    case resourcesMissing
    case unreadable(file: String, underlying: any Error)
    case decodingFailed(file: String, underlying: any Error)

    public var description: String {
        switch self {
        case .resourcesMissing:
            "Die Inhalts-Ressourcen wurden nicht im Bundle gefunden."
        case .unreadable(let file, let underlying):
            "Datei '\(file)' konnte nicht gelesen werden: \(underlying)"
        case .decodingFailed(let file, let underlying):
            "Datei '\(file)' hat ein ungültiges Format: \(underlying)"
        }
    }
}

/// Lädt Lektionen und Prüfungsfragen aus den JSON-Ressourcen.
///
/// Fehlerhafte Dateien werden nicht stillschweigend übersprungen, sondern mit
/// Dateiname gemeldet — sonst fällt ein Tippfehler im Content erst Monate
/// später auf.
public struct ContentLoader: Sendable {
    private let bundle: Bundle

    public init(bundle: Bundle? = nil) {
        self.bundle = bundle ?? .module
    }

    public func load() throws -> ContentLibrary {
        let lessons: [Lesson] = try loadAll(subdirectory: "lessons")
        let questions: [Question] = try loadAll(subdirectory: "questions")
        return ContentLibrary(
            lessons: lessons.sorted { $0.id < $1.id },
            questions: questions.sorted { $0.id < $1.id }
        )
    }

    /// Der Ressourcenordner `Content/Resources` wird von SPM als `Resources`
    /// ins Bundle kopiert (`.copy` behält nur den letzten Pfadanteil bei) —
    /// die eigentlichen Inhalte liegen also unter `Resources/<subdirectory>`.
    ///
    /// Eine Datei darf entweder ein einzelnes Objekt (üblich für Lektionen —
    /// eine Datei pro Lektion) oder ein Array davon enthalten (üblich für
    /// Fragen, die sich thematisch bündeln lassen).
    private func loadAll<T: Decodable>(subdirectory: String) throws -> [T] {
        let urls = bundle.urls(forResourcesWithExtension: "json", subdirectory: "Resources/\(subdirectory)") ?? []
        let decoder = JSONDecoder()
        return try urls.flatMap { url -> [T] in
            let name = "\(subdirectory)/\(url.lastPathComponent)"
            let data: Data
            do {
                data = try Data(contentsOf: url)
            } catch {
                throw ContentError.unreadable(file: name, underlying: error)
            }
            if let array = try? decoder.decode([T].self, from: data) {
                return array
            }
            do {
                return [try decoder.decode(T.self, from: data)]
            } catch {
                throw ContentError.decodingFailed(file: name, underlying: error)
            }
        }
    }
}
