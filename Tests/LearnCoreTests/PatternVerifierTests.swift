import Testing
@testable import LearnCore

@Suite("PatternVerifier")
struct PatternVerifierTests {
    let verifier = PatternVerifier()

    private var commandExpectation: LearnCore.Expectation {
        .command(
            pattern: "^(sudo )?systemctl status nginx(\\.service)?$",
            canonical: "systemctl status nginx",
            nearMisses: [
                NearMiss(pattern: "^(sudo )?service nginx status$", feedback: "Alte SysV-Schreibweise.")
            ]
        )
    }

    @Test("Erkennt die exakte Musterlösung als richtig")
    func exactMatch() {
        #expect(verifier.check("systemctl status nginx", against: commandExpectation) == .correct)
    }

    @Test("Ignoriert Groß-/Kleinschreibung und überflüssige Leerzeichen")
    func normalizesWhitespaceAndCase() {
        #expect(verifier.check("  SYSTEMCTL   status   NGINX  ", against: commandExpectation) == .correct)
    }

    @Test("Akzeptiert sudo-Präfix laut Muster")
    func acceptsSudoPrefix() {
        #expect(verifier.check("sudo systemctl status nginx", against: commandExpectation) == .correct)
    }

    @Test("Erkennt einen dokumentierten Near-Miss mit gezieltem Feedback")
    func detectsNearMiss() {
        let result = verifier.check("service nginx status", against: commandExpectation)
        guard case .closeButWrong(let feedback) = result else {
            Issue.record("Erwartete closeButWrong, bekam \(result)")
            return
        }
        #expect(feedback.contains("SysV"))
    }

    @Test("Eindeutig falsche Eingabe ist incorrect")
    func clearlyWrong() {
        #expect(verifier.check("rm -rf /", against: commandExpectation) == .incorrect)
    }

    @Test("Leere Eingabe ist immer incorrect")
    func emptyInput() {
        #expect(verifier.check("   ", against: commandExpectation) == .incorrect)
    }

    @Test("Multiple Choice: Zahl, Buchstabe und Text führen zum selben Ergebnis")
    func multipleChoiceAcceptsSeveralForms() {
        let expectation = LearnCore.Expectation.multipleChoice(options: ["Apache", "Nginx", "Caddy"], correct: 1)
        #expect(verifier.check("2", against: expectation) == .correct)
        #expect(verifier.check("b", against: expectation) == .correct)
        #expect(verifier.check("Nginx", against: expectation) == .correct)
        #expect(verifier.check("1", against: expectation) == .incorrect)
    }

    @Test("Freitext meldet Teiltreffer als closeButWrong")
    func freeTextPartialMatch() {
        let expectation = LearnCore.Expectation.freeText(keywords: ["vertraulichkeit", "integrität", "verfügbarkeit"])
        let result = verifier.check("vertraulichkeit und integrität", against: expectation)
        guard case .closeButWrong = result else {
            Issue.record("Erwartete closeButWrong, bekam \(result)")
            return
        }
    }

    @Test("Freitext mit allen Stichwörtern ist correct")
    func freeTextFullMatch() {
        let expectation = LearnCore.Expectation.freeText(keywords: ["vertraulichkeit", "integrität", "verfügbarkeit"])
        let result = verifier.check("Vertraulichkeit, Integrität und Verfügbarkeit", against: expectation)
        #expect(result == .correct)
    }
}
