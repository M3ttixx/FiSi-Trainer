import Foundation
import LearnCore

/// Laufender Lektionsstand innerhalb einer Sitzung.
private struct ActiveLesson {
    let lesson: Lesson
    var stepIndex: Int = 0
    var hintsShown: Int = 0
}

/// Die interaktive Shell: REPL-Schleife, Kommando-Routing, Lektionsablauf.
struct Shell {
    private let library: ContentLibrary
    private let verifier: any Verifier
    private let progressStore: ProgressStore
    private let renderer = Renderer()
    private var active: ActiveLesson?

    init(library: ContentLibrary, verifier: any Verifier, progressStore: ProgressStore) {
        self.library = library
        self.verifier = verifier
        self.progressStore = progressStore
    }

    mutating func run() {
        renderer.banner()
        while true {
            let promptText = active == nil ? "> " : "(\(active!.lesson.id)) > "
            guard let line = Terminal.readLine(prompt: promptText) else {
                print("")
                break
            }
            let input = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !input.isEmpty else { continue }

            if let lessonCommand = Command(rawValue: input.lowercased().split(separator: " ").first.map(String.init) ?? "") {
                if handle(lessonCommand, rawInput: input) == .quit { break }
            } else if active != nil {
                handleAttempt(input)
            } else {
                renderer.error("Unbekanntes Kommando '\(input)'. 'help' zeigt alle Kommandos.")
            }
        }
    }

    private enum Command: String {
        case help, tracks, list, start, hint, skip, status, validate, reset, quit, exit
    }

    private enum Loop { case `continue`, quit }

    private mutating func handle(_ command: Command, rawInput: String) -> Loop {
        let parts = rawInput.split(separator: " ", maxSplits: 1).map(String.init)
        let argument = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces) : nil

        switch command {
        case .help:
            renderer.help()
        case .tracks:
            renderer.tracks()
        case .list:
            listLessons(filter: argument)
        case .start:
            startLesson(id: argument)
        case .hint:
            showHint()
        case .skip:
            skipStep()
        case .status:
            renderer.status(library, store: progressStore)
        case .validate:
            renderer.validationReport(ContentValidator().validate(library))
        case .reset:
            switch progressStore.reset() {
            case .success:
                renderer.info("Fortschritt zurückgesetzt.")
            case .failure(let error):
                renderer.error("Konnte nicht zurücksetzen: \(error.localizedDescription)")
            }
        case .quit, .exit:
            return .quit
        }
        return .continue
    }

    // MARK: - Kommandos

    private func listLessons(filter: String?) {
        var lessons = library.lessons
        if let filter, let track = Track(rawValue: filter) {
            lessons = library.lessons(track: track)
        } else if let filter {
            renderer.error("Unbekannter Track '\(filter)'. Verfügbar: \(Track.allCases.map(\.rawValue).joined(separator: ", "))")
            return
        }
        renderer.lessonList(lessons, progressStore: progressStore)
    }

    private mutating func startLesson(id: String?) {
        guard let id else {
            renderer.error("Nutzung: start <lesson-id>")
            return
        }
        guard let lesson = library.lesson(id: id) else {
            renderer.error("Keine Lektion mit ID '\(id)'.")
            return
        }
        let missing = lesson.prerequisites.filter { !progressStore.progress(for: $0).isCompleted }
        if !missing.isEmpty {
            renderer.info("Hinweis: Diese Lektion baut auf \(missing.joined(separator: ", ")) auf — empfohlen, aber nicht erzwungen.")
        }
        active = ActiveLesson(lesson: lesson)
        renderer.lessonIntro(lesson)
        showCurrentStep()
    }

    private func showCurrentStep() {
        guard let active else { return }
        renderer.step(active.lesson.steps[active.stepIndex], index: active.stepIndex, total: active.lesson.steps.count)
    }

    private mutating func showHint() {
        guard var current = active else {
            renderer.error("Keine Lektion aktiv. 'start <id>' beginnt eine.")
            return
        }
        let hints = current.lesson.steps[current.stepIndex].hints
        if current.hintsShown < hints.count {
            renderer.hint(hints[current.hintsShown])
            current.hintsShown += 1
            active = current
            progressStore.update(lessonID: current.lesson.id) { $0.hintsUsed += 1 }
        } else {
            renderer.hint(nil)
        }
    }

    private mutating func skipStep() {
        guard active != nil else {
            renderer.error("Keine Lektion aktiv. 'start <id>' beginnt eine.")
            return
        }
        advanceStep()
    }

    private mutating func handleAttempt(_ input: String) {
        guard let current = active else { return }
        let step = current.lesson.steps[current.stepIndex]
        let result = verifier.check(input, against: step.expectation)
        renderer.outcome(result)

        progressStore.update(lessonID: current.lesson.id) { $0.attempts += 1 }

        if result == .correct {
            renderer.explanation(step.explanation)
            advanceStep()
        }
    }

    private mutating func advanceStep() {
        guard var current = active else { return }
        current.stepIndex += 1
        current.hintsShown = 0

        progressStore.update(lessonID: current.lesson.id) { progress in
            progress.completedSteps = max(progress.completedSteps, current.stepIndex)
        }

        if current.stepIndex >= current.lesson.steps.count {
            progressStore.update(lessonID: current.lesson.id) { $0.isCompleted = true }
            renderer.lessonComplete(current.lesson)
            active = nil
        } else {
            active = current
            showCurrentStep()
        }
    }
}
