import Foundation

/// Lernstand zu einer einzelnen Lektion.
public struct LessonProgress: Codable, Sendable, Equatable {
    public var completedSteps: Int
    public var attempts: Int
    public var hintsUsed: Int
    public var isCompleted: Bool
    public var lastVisited: Date

    public init(
        completedSteps: Int = 0,
        attempts: Int = 0,
        hintsUsed: Int = 0,
        isCompleted: Bool = false,
        lastVisited: Date = .now
    ) {
        self.completedSteps = completedSteps
        self.attempts = attempts
        self.hintsUsed = hintsUsed
        self.isCompleted = isCompleted
        self.lastVisited = lastVisited
    }
}

/// Der gesamte persistierte Lernstand.
///
/// `version` erlaubt Migrationen: über eine dreijährige Ausbildung ändert sich
/// das Format garantiert, und der Fortschritt darf dabei nie verloren gehen.
public struct ProgressState: Codable, Sendable, Equatable {
    public static let currentVersion = 1

    public var version: Int
    public var lessons: [String: LessonProgress]
    public var createdAt: Date

    public init(
        version: Int = ProgressState.currentVersion,
        lessons: [String: LessonProgress] = [:],
        createdAt: Date = .now
    ) {
        self.version = version
        self.lessons = lessons
        self.createdAt = createdAt
    }
}

/// Lädt und speichert den Lernstand als JSON im Application-Support-Verzeichnis.
public final class ProgressStore: @unchecked Sendable {
    private let fileURL: URL
    private let queue = DispatchQueue(label: "de.fisitrainer.progress")
    private var state: ProgressState

    /// Standardablage: `~/Library/Application Support/FiSiTrainer/progress.json`
    public static func defaultURL() throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return base.appendingPathComponent("FiSiTrainer", isDirectory: true)
            .appendingPathComponent("progress.json")
    }

    public init(fileURL: URL) {
        self.fileURL = fileURL
        self.state = Self.read(from: fileURL)
    }

    public var snapshot: ProgressState {
        queue.sync { state }
    }

    public func progress(for lessonID: String) -> LessonProgress {
        queue.sync { state.lessons[lessonID] ?? LessonProgress() }
    }

    /// Ändert den Stand einer Lektion und schreibt ihn sofort weg.
    @discardableResult
    public func update(lessonID: String, _ change: (inout LessonProgress) -> Void) -> Result<Void, any Error> {
        queue.sync {
            var progress = state.lessons[lessonID] ?? LessonProgress()
            change(&progress)
            progress.lastVisited = .now
            state.lessons[lessonID] = progress
            return persist()
        }
    }

    @discardableResult
    public func reset() -> Result<Void, any Error> {
        queue.sync {
            state = ProgressState()
            return persist()
        }
    }

    // MARK: - Persistenz

    private func persist() -> Result<Void, any Error> {
        do {
            let directory = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(state)
            // Atomar schreiben: ein Absturz mitten im Schreiben darf den
            // Lernstand von Monaten nicht zerstören.
            try data.write(to: fileURL, options: .atomic)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    /// Liest den Stand. Eine defekte Datei blockiert nie den Start — sie wird
    /// zur Seite gelegt und der Stand neu begonnen.
    private static func read(from url: URL) -> ProgressState {
        guard let data = try? Data(contentsOf: url) else {
            return ProgressState()
        }
        do {
            let decoded = try JSONDecoder().decode(ProgressState.self, from: data)
            return migrate(decoded)
        } catch {
            let backup = url.deletingPathExtension().appendingPathExtension("corrupt.json")
            try? FileManager.default.removeItem(at: backup)
            try? FileManager.default.moveItem(at: url, to: backup)
            return ProgressState()
        }
    }

    /// Hebt ältere Stände auf das aktuelle Format. Aktuell existiert nur
    /// Version 1; die Weiche steht bereit, damit spätere Änderungen den
    /// Lernstand nicht wegwerfen.
    private static func migrate(_ state: ProgressState) -> ProgressState {
        guard state.version < ProgressState.currentVersion else { return state }
        var migrated = state
        migrated.version = ProgressState.currentVersion
        return migrated
    }
}
