import Foundation
import Testing
@testable import LearnCore

@Suite("SpacedRepetition")
struct SpacedRepetitionTests {
    @Test("Richtige Antwort erhöht Wiederholungszähler und schiebt Fälligkeit nach vorn")
    func correctAnswerGrowsInterval() {
        let now = Date(timeIntervalSince1970: 0)
        var progress = QuestionProgress()

        progress = SpacedRepetition.schedule(current: progress, outcome: .correct, now: now)
        #expect(progress.repetitions == 1)
        #expect(progress.intervalDays == 1)
        #expect(progress.correctCount == 1)

        progress = SpacedRepetition.schedule(current: progress, outcome: .correct, now: now)
        #expect(progress.repetitions == 2)
        #expect(progress.intervalDays == 6)

        progress = SpacedRepetition.schedule(current: progress, outcome: .correct, now: now)
        #expect(progress.repetitions == 3)
        #expect(progress.intervalDays > 6)
    }

    @Test("Falsche Antwort setzt die Wiederholungsserie zurück")
    func incorrectAnswerResetsSeries() {
        let now = Date(timeIntervalSince1970: 0)
        var progress = QuestionProgress(repetitions: 4, easinessFactor: 2.7, intervalDays: 20)

        progress = SpacedRepetition.schedule(current: progress, outcome: .incorrect, now: now)
        #expect(progress.repetitions == 0)
        #expect(progress.intervalDays == 1)
        #expect(progress.incorrectCount == 1)
    }

    @Test("Fälligkeitsdatum liegt intervalDays nach dem Referenzzeitpunkt")
    func dueDateMatchesInterval() {
        let now = Date(timeIntervalSince1970: 0)
        let progress = SpacedRepetition.schedule(current: QuestionProgress(), outcome: .correct, now: now)
        let expected = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        #expect(abs(progress.dueDate.timeIntervalSince(expected)) < 1)
    }

    @Test("Easiness-Faktor fällt nie unter 1.3")
    func easinessFactorHasFloor() {
        var progress = QuestionProgress(easinessFactor: 1.3)
        for _ in 0..<10 {
            progress = SpacedRepetition.schedule(current: progress, outcome: .incorrect)
        }
        #expect(progress.easinessFactor >= 1.3)
    }
}
