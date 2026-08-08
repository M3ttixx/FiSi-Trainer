import Foundation
#if canImport(Glibc)
import Glibc
#else
import Darwin
#endif

/// Kleine Terminal-Helfer: Zeilen lesen, Farb-/TTY-Erkennung.
enum Terminal {
    /// Farben nur, wenn tatsächlich auf ein Terminal geschrieben wird — sonst
    /// bleiben Pipes, Logdateien und Tests frei von ANSI-Codes.
    static var colorEnabled: Bool {
        isatty(fileno(stdout)) == 1 && ProcessInfo.processInfo.environment["TERM"] != "dumb"
    }

    /// Liest eine Zeile von der Standardeingabe. `nil` bei EOF (z. B. Ctrl-D).
    static func readLine(prompt: String) -> String? {
        FileHandle.standardOutput.write(Data(prompt.utf8))
        return Swift.readLine(strippingNewline: true)
    }
}

enum ANSI: String {
    case reset = "\u{001B}[0m"
    case bold = "\u{001B}[1m"
    case dim = "\u{001B}[2m"
    case green = "\u{001B}[32m"
    case red = "\u{001B}[31m"
    case yellow = "\u{001B}[33m"
    case cyan = "\u{001B}[36m"
    case magenta = "\u{001B}[35m"
}

extension String {
    /// Umschließt den Text mit dem Farbcode, aber nur wenn Farben aktiv sind.
    func styled(_ code: ANSI) -> String {
        guard Terminal.colorEnabled else { return self }
        return "\(code.rawValue)\(self)\(ANSI.reset.rawValue)"
    }
}
