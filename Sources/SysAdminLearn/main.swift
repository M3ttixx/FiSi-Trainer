import Foundation
import LearnCore

let appVersion = "0.2.0"

let arguments = Set(CommandLine.arguments.dropFirst())
if arguments.contains("--help") || arguments.contains("-h") {
    print("""
    FiSi-Trainer \(appVersion)
    Interaktive Lern-Shell für angehende Fachinformatiker Systemintegration.

    Nutzung: SysAdminLearn [--help] [--version] [--validate]

      --help, -h      Diese Übersicht anzeigen und beenden
      --version, -v   Versionsnummer anzeigen und beenden
      --validate      Alle Lerninhalte prüfen und mit dem Ergebnis als Exit-Code beenden
                       (0 = keine Fehler, 1 = Fehler) — nützlich für CI.

    Ohne Argumente startet die interaktive Shell; dort zeigt 'help' alle Kommandos.
    """)
    exit(0)
}
if arguments.contains("--version") || arguments.contains("-v") {
    print("FiSi-Trainer \(appVersion)")
    exit(0)
}

let library: ContentLibrary
do {
    library = try ContentLoader().load()
} catch {
    FileHandle.standardError.write(Data("Inhalte konnten nicht geladen werden: \(error)\n".utf8))
    exit(1)
}

if arguments.contains("--validate") {
    let issues = ContentValidator().validate(library)
    let errors = issues.filter { $0.severity == .error }
    for issue in issues {
        print(issue.description)
    }
    print("\n\(errors.count) Fehler, \(issues.count - errors.count) Warnungen.")
    exit(errors.isEmpty ? 0 : 1)
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
