import Testing
@testable import LearnCore

@Suite("ExamSimulator")
struct ExamSimulatorTests {
    private func makeQuestion(id: String, lernfeld: Lernfeld, examPart: ExamPart) -> Question {
        Question(
            id: id,
            prompt: "Prompt \(id)",
            lernfelder: [lernfeld],
            examPart: examPart,
            difficulty: .beginner,
            answer: .shortAnswer(accepted: ["x"]),
            explanation: "Erklärung"
        )
    }

    @Test("selectQuestions liefert nur Fragen des angefragten Prüfungsteils, deterministisch bei festem Seed")
    func selectQuestionsFiltersAndIsDeterministic() {
        let library = ContentLibrary(
            lessons: [],
            questions: [
                makeQuestion(id: "a1", lernfeld: .lf1, examPart: .ap1),
                makeQuestion(id: "a2", lernfeld: .lf2, examPart: .ap1),
                makeQuestion(id: "b1", lernfeld: .lf3, examPart: .ap2),
                makeQuestion(id: "c1", lernfeld: .lf4, examPart: .both),
            ]
        )
        let simulator = ExamSimulator()
        let selection = simulator.selectQuestions(from: library, examPart: .ap1, count: 10, seed: 42)
        let ids = Set(selection.map(\.id))
        #expect(ids == ["a1", "a2", "c1"])

        let again = simulator.selectQuestions(from: library, examPart: .ap1, count: 10, seed: 42)
        #expect(selection.map(\.id) == again.map(\.id))
    }

    @Test("summarize berechnet Score und Aufschlüsselung je Lernfeld korrekt")
    func summarizeComputesBreakdown() {
        let q1 = makeQuestion(id: "q1", lernfeld: .lf3, examPart: .ap1)
        let q2 = makeQuestion(id: "q2", lernfeld: .lf3, examPart: .ap1)
        let q3 = makeQuestion(id: "q3", lernfeld: .lf9, examPart: .ap1)

        let simulator = ExamSimulator()
        let result = simulator.summarize(
            examPart: .ap1,
            answered: [(q1, .correct), (q2, .incorrect), (q3, .correct)],
            elapsed: 42
        )

        #expect(result.total == 3)
        #expect(result.correct == 2)
        #expect(result.scorePercent.rounded() == 67)
        #expect(result.perLernfeld[.lf3]?.correct == 1)
        #expect(result.perLernfeld[.lf3]?.total == 2)
        #expect(result.perLernfeld[.lf9]?.correct == 1)
        #expect(result.perLernfeld[.lf9]?.total == 1)
    }
}
