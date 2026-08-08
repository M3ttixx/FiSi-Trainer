import Testing
@testable import LearnCore

@Suite("AnswerChecker")
struct AnswerCheckerTests {
    let checker = AnswerChecker()

    @Test("Multiple Choice: gültige und ungültige Eingaben")
    func multipleChoice() {
        let answer = Answer.multipleChoice(options: ["Apache", "Nginx", "Caddy"], correct: 1)
        #expect(checker.check("2", against: answer) == .correct)
        #expect(checker.check("b", against: answer) == .correct)
        #expect(checker.check("1", against: answer) == .incorrect)
        if case .closeButWrong = checker.check("keine ahnung", against: answer) {
            // erwartet
        } else {
            Issue.record("Erwartete closeButWrong bei unparsbarer Eingabe")
        }
    }

    @Test("ShortAnswer akzeptiert alle hinterlegten Schreibweisen, case-insensitive")
    func shortAnswer() {
        let answer = Answer.shortAnswer(accepted: ["MX", "MX-Record"])
        #expect(checker.check("mx", against: answer) == .correct)
        #expect(checker.check("MX-Record", against: answer) == .correct)
        #expect(checker.check("A-Record", against: answer) == .incorrect)
    }

    @Test("Calculation akzeptiert Komma statt Punkt und optionale Einheit")
    func calculationAcceptsCommaAndUnit() {
        let answer = Answer.calculation(expected: "1314", unit: "€")
        #expect(checker.check("1314", against: answer) == .correct)
        #expect(checker.check("1314 €", against: answer) == .correct)
        #expect(checker.check("1314,0", against: answer) == .correct)
    }

    @Test("Calculation: knapp daneben ist closeButWrong, deutlich falsch ist incorrect")
    func calculationDistinguishesNearMissFromWrong() {
        let answer = Answer.calculation(expected: "1314", unit: "€")
        if case .closeButWrong = checker.check("1315", against: answer) {
            // erwartet — Rundungsdifferenz von 1
        } else {
            Issue.record("Erwartete closeButWrong bei einer Differenz von 1")
        }
        #expect(checker.check("50", against: answer) == .incorrect)
    }

    @Test("Leere Eingabe ist immer incorrect")
    func emptyInput() {
        #expect(checker.check("   ", against: .shortAnswer(accepted: ["x"])) == .incorrect)
    }
}
