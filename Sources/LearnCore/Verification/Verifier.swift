import Foundation

/// Ergebnis einer Überprüfung.
public enum Outcome: Sendable, Equatable {
    case correct
    /// Erkennbar auf dem richtigen Weg — mit gezielter Rückmeldung.
    case closeButWrong(feedback: String)
    case incorrect
}

/// Abstraktion über die Art der Überprüfung.
///
/// In v1 prüft `PatternVerifier` die Eingabe gegen Muster, ohne etwas
/// auszuführen. Ein späterer Container-Runner implementiert dasselbe Protokoll
/// und lässt Befehle real in einer Linux-Umgebung laufen — die Lektionsinhalte
/// bleiben davon unberührt.
public protocol Verifier: Sendable {
    func check(_ input: String, against expectation: Expectation) -> Outcome
}
