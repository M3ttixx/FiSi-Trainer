import Foundation
import LearnCore

/// Laufender Lektionsstand innerhalb einer Sitzung.
private struct ActiveLesson {
    let lesson: Lesson
    var stepIndex: Int = 0
    var hintsShown: Int = 0
}

/// Laufende Wiederholungs-Session (Spaced Repetition).
private struct ActiveReview {
    let questions: [Question]
    var index: Int = 0
    var correct: Int = 0
}

/// Laufende Prüfungssimulation.
private struct ActiveExam {
    let examPart: ExamPart
    let questions: [Question]
    var index: Int = 0
    var answered: [(question: Question, outcome: Outcome)] = []
    let startedAt: Date
}

/// Welche Aktivität die Shell gerade führt — immer höchstens eine gleichzeitig.
private enum Mode {
    case idle
    case lesson(ActiveLesson)
    case review(ActiveReview)
    case exam(ActiveExam)
}

/// Die interaktive Shell: REPL-Schleife, Kommando-Routing, Lektions-, Review-
/// und Prüfungsablauf.
struct Shell {
    private let library: ContentLibrary
    private let verifier: any Verifier
    private let answerChecker = AnswerChecker()
    private let examSimulator = ExamSimulator()
    private let progressStore: ProgressStore
    private let renderer = Renderer()
    private var mode: Mode = .idle

    init(library: ContentLibrary, verifier: any Verifier, progressStore: ProgressStore) {
        self.library = library
        self.verifier = verifier
        self.progressStore = progressStore
    }

    mutating func run() {
        renderer.banner()
        let dueCount = dueForReview().count
        if dueCount > 0 {
            renderer.info("\(dueCount) Frage(n) heute fällig — 'review' startet die Wiederholung.")
        }
        while true {
            guard let line = Terminal.readLine(prompt: promptText()) else {
                print("")
                break
            }
            let input = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !input.isEmpty else { continue }

            if let command = Command(rawValue: input.lowercased().split(separator: " ").first.map(String.init) ?? "") {
                if handle(command, rawInput: input) == .quit { break }
            } else {
                switch mode {
                case .idle:
                    renderer.error("Unbekanntes Kommando '\(input)'. 'help' zeigt alle Kommandos.")
                case .lesson:
                    handleLessonAttempt(input)
                case .review:
                    handleReviewAttempt(input)
                case .exam:
                    handleExamAttempt(input)
                }
            }
        }
    }

    private func promptText() -> String {
        switch mode {
        case .idle: "> "
        case .lesson(let active): "(\(active.lesson.id)) > "
        case .review: "(review) > "
        case .exam(let active): "(exam \(active.examPart.rawValue)) > "
        }
    }

    private enum Command: String {
        case help, tracks, list, start, hint, skip, status, validate, reset
        case review, exam, stats, quit, exit
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
            skip()
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
        case .review:
            startReview()
        case .exam:
            startExam(part: argument)
        case .stats:
            renderer.stats(Statistics.perLernfeld(library: library, state: progressStore.snapshot))
        case .quit, .exit:
            return .quit
        }
        return .continue
    }

    // MARK: - Lektionen

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
        guard case .idle = mode else {
            renderer.error("Erst die laufende Aktivität beenden (quit/skip bis zum Ende).")
            return
        }
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
        mode = .lesson(ActiveLesson(lesson: lesson))
        renderer.lessonIntro(lesson)
        showCurrentStep()
    }

    private func showCurrentStep() {
        guard case .lesson(let active) = mode else { return }
        renderer.step(active.lesson.steps[active.stepIndex], index: active.stepIndex, total: active.lesson.steps.count)
    }

    private mutating func showHint() {
        guard case .lesson(var active) = mode else {
            renderer.error("Hinweise gibt es nur innerhalb einer laufenden Lektion.")
            return
        }
        let hints = active.lesson.steps[active.stepIndex].hints
        if active.hintsShown < hints.count {
            renderer.hint(hints[active.hintsShown])
            active.hintsShown += 1
            mode = .lesson(active)
            progressStore.update(lessonID: active.lesson.id) { $0.hintsUsed += 1 }
        } else {
            renderer.hint(nil)
        }
    }

    private mutating func skip() {
        switch mode {
        case .idle:
            renderer.error("Keine Aktivität aktiv.")
        case .lesson:
            advanceLessonStep()
        case .review:
            advanceReview(outcome: nil)
        case .exam:
            advanceExam(outcome: .incorrect)
        }
    }

    private mutating func handleLessonAttempt(_ input: String) {
        guard case .lesson(let active) = mode else { return }
        let step = active.lesson.steps[active.stepIndex]
        let result = verifier.check(input, against: step.expectation)
        renderer.outcome(result)

        progressStore.update(lessonID: active.lesson.id) { $0.attempts += 1 }

        if result == .correct {
            renderer.explanation(step.explanation)
            advanceLessonStep()
        }
    }

    private mutating func advanceLessonStep() {
        guard case .lesson(var active) = mode else { return }
        active.stepIndex += 1
        active.hintsShown = 0

        progressStore.update(lessonID: active.lesson.id) { progress in
            progress.completedSteps = max(progress.completedSteps, active.stepIndex)
        }

        if active.stepIndex >= active.lesson.steps.count {
            progressStore.update(lessonID: active.lesson.id) { $0.isCompleted = true }
            renderer.lessonComplete(active.lesson)
            mode = .idle
        } else {
            mode = .lesson(active)
            showCurrentStep()
        }
    }

    // MARK: - Review (Spaced Repetition)

    /// Bereits gesehene Fragen, deren Fälligkeitsdatum erreicht ist.
    private func dueForReview() -> [Question] {
        library.questions.filter { question in
            guard let progress = progressStore.snapshot.questions[question.id] else { return false }
            return progress.dueDate <= .now
        }
    }

    /// Fragen, die noch nie beantwortet wurden — Einstieg in die Wiederholungsserie.
    private func unseenQuestions() -> [Question] {
        library.questions.filter { progressStore.snapshot.questions[$0.id] == nil }
    }

    private mutating func startReview() {
        guard case .idle = mode else {
            renderer.error("Erst die laufende Aktivität beenden.")
            return
        }
        var due = dueForReview()
        if due.isEmpty {
            due = unseenQuestions()
            guard !due.isEmpty else {
                renderer.info("Alles wiederholt, nichts ist gerade fällig. Später wieder vorbeischauen.")
                return
            }
            renderer.info("Keine fälligen Wiederholungen — starte mit \(due.count) neuen Fragen.")
        }
        mode = .review(ActiveReview(questions: due.shuffled()))
        renderer.reviewIntro(count: due.count)
        showCurrentQuestion()
    }

    private func showCurrentQuestion() {
        switch mode {
        case .review(let active):
            renderer.question(active.questions[active.index], index: active.index, total: active.questions.count)
        case .exam(let active):
            renderer.question(active.questions[active.index], index: active.index, total: active.questions.count)
        default:
            break
        }
    }

    private mutating func handleReviewAttempt(_ input: String) {
        guard case .review(let active) = mode else { return }
        let question = active.questions[active.index]
        let result = answerChecker.check(input, against: question.answer)
        renderer.outcome(result, hintAvailable: false)
        renderer.explanation(question.explanation)

        let updated = SpacedRepetition.schedule(current: progressStore.progress(questionID: question.id), outcome: result)
        progressStore.updateQuestion(id: question.id) { $0 = updated }

        advanceReview(outcome: result)
    }

    private mutating func advanceReview(outcome: Outcome?) {
        guard case .review(var active) = mode else { return }
        if outcome == .correct { active.correct += 1 }
        active.index += 1

        if active.index >= active.questions.count {
            renderer.reviewComplete(correct: active.correct, total: active.questions.count)
            mode = .idle
        } else {
            mode = .review(active)
            showCurrentQuestion()
        }
    }

    // MARK: - Prüfungssimulation

    private mutating func startExam(part: String?) {
        guard case .idle = mode else {
            renderer.error("Erst die laufende Aktivität beenden.")
            return
        }
        guard let part, let examPart = ExamPart(rawValue: part), examPart != .both else {
            renderer.error("Nutzung: exam <ap1|ap2>")
            return
        }
        let questions = examSimulator.selectQuestions(from: library, examPart: examPart)
        guard !questions.isEmpty else {
            renderer.error("Keine Fragen für \(examPart.label) hinterlegt.")
            return
        }
        mode = .exam(ActiveExam(examPart: examPart, questions: questions, startedAt: .now))
        renderer.examIntro(examPart: examPart, count: questions.count, budget: examSimulator.budget(for: questions.count))
        showCurrentQuestion()
    }

    private mutating func handleExamAttempt(_ input: String) {
        guard case .exam(let active) = mode else { return }
        let question = active.questions[active.index]
        let result = answerChecker.check(input, against: question.answer)
        renderer.outcome(result, hintAvailable: false)
        renderer.explanation(question.explanation)
        advanceExam(outcome: result)
    }

    private mutating func advanceExam(outcome: Outcome) {
        guard case .exam(var active) = mode else { return }
        let question = active.questions[active.index]
        active.answered.append((question: question, outcome: outcome))
        active.index += 1

        if active.index >= active.questions.count {
            let elapsed = Date.now.timeIntervalSince(active.startedAt)
            let result = examSimulator.summarize(examPart: active.examPart, answered: active.answered, elapsed: elapsed)
            renderer.examResult(result)
            mode = .idle
        } else {
            mode = .exam(active)
            showCurrentQuestion()
        }
    }
}
