import Foundation

/// Aktuelle Version des Content-Schemas. Wird in jeder JSON-Datei mitgeführt,
/// damit spätere Formatänderungen migriert statt von Hand nachgezogen werden.
public enum ContentSchema {
    public static let current = 1
}

/// Thematischer Lernpfad — die Gliederung der Praxis-Lektionen.
public enum Track: String, Codable, Sendable, CaseIterable {
    case web
    case database
    case network
    case virtualization

    public var title: String {
        switch self {
        case .web: "Webserver & Proxies"
        case .database: "Datenbanken"
        case .network: "Netzwerk & Sicherheit"
        case .virtualization: "Virtualisierung"
        }
    }
}

/// Lernfelder des Ausbildungsrahmenplans Fachinformatiker/-in Systemintegration.
public enum Lernfeld: Int, Codable, Sendable, CaseIterable {
    case lf1 = 1, lf2, lf3, lf4, lf5, lf6, lf7, lf8, lf9, lf10, lf11, lf12

    public var title: String {
        switch self {
        case .lf1: "Das Unternehmen und die eigene Rolle"
        case .lf2: "Arbeitsplätze nach Kundenwunsch ausstatten"
        case .lf3: "Clients in Netzwerke einbinden"
        case .lf4: "Schutzbedarfsanalyse im eigenen Arbeitsbereich"
        case .lf5: "Software zur Verwaltung von Daten anpassen"
        case .lf6: "Serviceanfragen bearbeiten"
        case .lf7: "Cyber-physische Systeme ergänzen"
        case .lf8: "Daten systemübergreifend bereitstellen"
        case .lf9: "Netzwerke und Dienste bereitstellen"
        case .lf10: "Kunden bei der Systemintegration unterstützen"
        case .lf11: "Betrieb und Sicherheit vernetzter Systeme"
        case .lf12: "Kundenspezifische Systemintegration"
        }
    }

    /// Kurzform für Listen und Statistiken, z. B. "LF9".
    public var label: String { "LF\(rawValue)" }
}

/// Zuordnung zu den gestreckten Abschlussprüfungen.
public enum ExamPart: String, Codable, Sendable, CaseIterable {
    case ap1
    case ap2
    case both

    /// Ob ein Inhalt für den gefragten Prüfungsteil relevant ist.
    public func covers(_ part: ExamPart) -> Bool {
        self == .both || part == .both || self == part
    }

    public var label: String {
        switch self {
        case .ap1: "AP1"
        case .ap2: "AP2"
        case .both: "AP1+AP2"
        }
    }
}

public enum Difficulty: String, Codable, Sendable, CaseIterable {
    case beginner
    case intermediate
    case advanced

    public var label: String {
        switch self {
        case .beginner: "Einsteiger"
        case .intermediate: "Fortgeschritten"
        case .advanced: "Profi"
        }
    }
}

/// Herkunft eines Inhalts. Im öffentlichen Repository ist ausschließlich
/// `ownWork` zulässig — IHK-Originalaufgaben sind urheberrechtlich geschützt.
public enum Origin: Codable, Sendable, Equatable {
    /// Selbst formulierter Inhalt, gegebenenfalls thematisch an Prüfungen orientiert.
    case ownWork
    /// Inhalt aus einer frei lizenzierten Quelle, mit Nachweis.
    case publicSource(url: String)

    private enum CodingKeys: String, CodingKey {
        case kind, url
    }

    private enum Kind: String, Codable {
        case ownWork, publicSource
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(Kind.self, forKey: .kind) {
        case .ownWork:
            self = .ownWork
        case .publicSource:
            self = .publicSource(url: try container.decode(String.self, forKey: .url))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .ownWork:
            try container.encode(Kind.ownWork, forKey: .kind)
        case .publicSource(let url):
            try container.encode(Kind.publicSource, forKey: .kind)
            try container.encode(url, forKey: .url)
        }
    }
}
