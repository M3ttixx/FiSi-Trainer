import Foundation
import Testing
@testable import LearnCore

@Suite("ProgressStore")
struct ProgressStoreTests {
    private func temporaryFile() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("fisitrainer-tests-\(UUID().uuidString)")
            .appendingPathComponent("progress.json")
    }

    @Test("Ein frischer Store startet ohne Fortschritt")
    func startsEmpty() {
        let store = ProgressStore(fileURL: temporaryFile())
        #expect(store.snapshot.lessons.isEmpty)
    }

    @Test("Änderungen überstehen einen Neustart des Stores (Round-Trip)")
    func roundTrips() {
        let url = temporaryFile()
        let first = ProgressStore(fileURL: url)
        first.update(lessonID: "web-nginx-basics") { progress in
            progress.completedSteps = 3
            progress.attempts = 5
            progress.isCompleted = true
        }

        let second = ProgressStore(fileURL: url)
        let progress = second.progress(for: "web-nginx-basics")
        #expect(progress.completedSteps == 3)
        #expect(progress.attempts == 5)
        #expect(progress.isCompleted)
    }

    @Test("Ein korruptes Fortschritts-File blockiert den Start nicht")
    func recoversFromCorruptFile() throws {
        let url = temporaryFile()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("{ das ist kein gültiges json".utf8).write(to: url)

        let store = ProgressStore(fileURL: url)
        #expect(store.snapshot.lessons.isEmpty)

        // Nach einer neuen Änderung lässt sich normal weiterschreiben.
        let result = store.update(lessonID: "net-ssh-hardening") { $0.attempts = 1 }
        if case .failure(let error) = result {
            Issue.record("Schreiben nach Wiederherstellung fehlgeschlagen: \(error)")
        }
    }

    @Test("reset() leert den Fortschritt")
    func resetClearsProgress() {
        let url = temporaryFile()
        let store = ProgressStore(fileURL: url)
        store.update(lessonID: "web-nginx-basics") { $0.isCompleted = true }
        #expect(!store.snapshot.lessons.isEmpty)

        store.reset()
        #expect(store.snapshot.lessons.isEmpty)
    }
}
