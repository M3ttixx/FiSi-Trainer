import Foundation
import Testing
@testable import LearnCore

@Suite("Statistics")
struct StatisticsTests {
    private func makeQuestion(id: String, lernfeld: Lernfeld) -> Question {
        Question(
            id: id,
            prompt: "Prompt \(id)",
            lernfelder: [lernfeld],
            examPart: .ap1,
            difficulty: .beginner,
            answer: .shortAnswer(accepted: ["x"]),
            explanation: "Erklärung"
        )
    }

    @Test("perLernfeld berechnet Trefferquote nur für tatsächlich geübte Lernfelder")
    func perLernfeldComputesAccuracy() {
        let library = ContentLibrary(
            lessons: [],
            questions: [
                makeQuestion(id: "q1", lernfeld: .lf3),
                makeQuestion(id: "q2", lernfeld: .lf3),
                makeQuestion(id: "q3", lernfeld: .lf9),
            ]
        )
        var state = ProgressState()
        state.questions["q1"] = QuestionProgress(correctCount: 3, incorrectCount: 1)
        state.questions["q2"] = QuestionProgress(correctCount: 1, incorrectCount: 0)

        let stats = Statistics.perLernfeld(library: library, state: state)
        let lf3 = stats.first { $0.lernfeld == .lf3 }
        let lf9 = stats.first { $0.lernfeld == .lf9 }

        #expect(lf3?.correct == 4)
        #expect(lf3?.incorrect == 1)
        #expect(lf3?.accuracyPercent?.rounded() == 80)
        #expect(lf9?.answered == 0)
        #expect(lf9?.accuracyPercent == nil)
    }

    @Test("Unbeübte Lernfelder werden zuerst sortiert, danach aufsteigend nach Trefferquote")
    func sortingPrioritizesWeakAndUnpracticed() {
        let library = ContentLibrary(
            lessons: [],
            questions: [
                makeQuestion(id: "q1", lernfeld: .lf3),
                makeQuestion(id: "q2", lernfeld: .lf9),
            ]
        )
        var state = ProgressState()
        state.questions["q1"] = QuestionProgress(correctCount: 5, incorrectCount: 0)

        let stats = Statistics.perLernfeld(library: library, state: state)
        #expect(stats.first?.lernfeld == .lf9)
    }
}
