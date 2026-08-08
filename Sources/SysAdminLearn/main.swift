import Foundation
import LearnCore

let library: ContentLibrary
do {
    library = try ContentLoader().load()
} catch {
    FileHandle.standardError.write(Data("Inhalte konnten nicht geladen werden: \(error)\n".utf8))
    exit(1)
}

let progressStore: ProgressStore
do {
    progressStore = ProgressStore(fileURL: try ProgressStore.defaultURL())
} catch {
    FileHandle.standardError.write(Data("Fortschrittsverzeichnis nicht verfügbar: \(error)\n".utf8))
    exit(1)
}

var shell = Shell(library: library, verifier: PatternVerifier(), progressStore: progressStore)
shell.run()
