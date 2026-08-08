import Testing
@testable import LearnCore

@Suite("ContentLoader")
struct ContentLoaderTests {
    @Test("Lädt alle mitgelieferten Lektionen und Fragen ohne Fehler")
    func loadsBundledContent() throws {
        let library = try ContentLoader().load()
        #expect(!library.lessons.isEmpty)
        #expect(!library.questions.isEmpty)
    }

    @Test("Jede Lektion hat mindestens einen Schritt")
    func lessonsHaveSteps() throws {
        let library = try ContentLoader().load()
        for lesson in library.lessons {
            #expect(!lesson.steps.isEmpty, "\(lesson.id) hat keine Schritte")
        }
    }

    @Test("Alle Prerequisites verweisen auf existierende Lektionen")
    func prerequisitesResolve() throws {
        let library = try ContentLoader().load()
        let ids = Set(library.lessons.map(\.id))
        for lesson in library.lessons {
            for prerequisite in lesson.prerequisites {
                #expect(ids.contains(prerequisite), "\(lesson.id) verweist auf unbekannte Voraussetzung '\(prerequisite)'")
            }
        }
    }

    @Test("Mitgelieferte Inhalte bestehen die Validierung ohne Fehler")
    func bundledContentValidates() throws {
        let library = try ContentLoader().load()
        let issues = ContentValidator().validate(library)
        let errors = issues.filter { $0.severity == .error }
        #expect(errors.isEmpty, "Validierungsfehler: \(errors.map(\.description))")
    }
}
