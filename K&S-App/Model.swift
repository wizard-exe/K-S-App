import SwiftUI

// Profilstruktur, die ein Benutzerprofil mit zugehörigen Daten darstellt
struct Profile: Identifiable, Codable {
    var id = UUID() // Eindeutige ID für jedes Profil
    var name: String // Name des Profils
    var mode: AppMode // Modus: WEA, PV, BESS, DomRep
    var checklists: [ChecklistCategory] = [] // Checklisten, gruppiert nach Kategorien
    var lopItems: [LOPItem] = [] // Liste von LOP-Einträgen (z. B. Mängel)
    var plattformen: [Plattform] = [] // Zugeordnete Plattformen mit Checklisten
}

// Enum zur Auswahl des App-Modus
enum AppMode: String, Codable {
    case wea = "WEA"
    case pv = "PV"
    case bess = "BESS"
    case domrep = "DomRep"
}

// Kategorie innerhalb einer Checkliste, enthält mehrere Unterkategorien
struct ChecklistCategory: Identifiable, Codable, Hashable {
    var id = UUID() // Eindeutige ID
    var name: String // Name der Kategorie
    var subcategories: [ChecklistSubcategory] // Unterkategorien dieser Kategorie
}

// Unterkategorie mit einer Liste von Checklistenpunkten
struct ChecklistSubcategory: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String // Name der Unterkategorie
    var items: [ChecklistItem] // Checklistenpunkte
}

// Ein einzelner Checklistenpunkt
class ChecklistItem: ObservableObject, Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String // Beschreibung des Punktes
    @Published var isCompleted: Bool = false // Wurde der Punkt abgeschlossen?
    var isLOP: Bool = false // Gehört der Punkt zu einem LOP (Mängel)?
    var comment: String = "" // Optionaler Kommentar zum Punkt
    var images: [String] = [] // Zugehörige Bilder (z. B. Dateipfade oder URLs)

    init(id: UUID = UUID(), name: String, isCompleted: Bool = false, isLOP: Bool = false, comment: String = "", images: [String] = []) {
        self.id = id
        self.name = name
        self.isCompleted = isCompleted
        self.isLOP = isLOP
        self.comment = comment
        self.images = images
    }

    // MARK: - Codable

    enum CodingKeys: CodingKey {
        case id, name, isCompleted, isLOP, comment, images
    }

    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let name = try container.decode(String.self, forKey: .name)
        let isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        let isLOP = try container.decode(Bool.self, forKey: .isLOP)
        let comment = try container.decode(String.self, forKey: .comment)
        let images = try container.decode([String].self, forKey: .images)
        self.init(id: id, name: name, isCompleted: isCompleted, isLOP: isLOP, comment: comment, images: images)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(isLOP, forKey: .isLOP)
        try container.encode(comment, forKey: .comment)
        try container.encode(images, forKey: .images)
    }

    // MARK: - Hashable

    static func == (lhs: ChecklistItem, rhs: ChecklistItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// Ein LOP-Eintrag (z. B. ein festgestellter Mangel)
struct LOPItem: Identifiable, Codable {
    var id = UUID()
    var title: String // Titel oder Beschreibung des LOP
    var comment: String // Kommentar oder Erklärung
    var images: [String] = [] // Bilder zur Dokumentation
}

// Eine Plattform (z. B. ein Standort oder Bereich), enthält standardmäßige Checklisten
struct Plattform: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String // Name der Plattform
    var image: String? = nil // Optionales Bild zur Plattform
    var items: [ChecklistItem] = Plattform.defaultChecklistItems() // Vordefinierte Checklistenpunkte

    // Statische Methode, die die Standard-Checklistenpunkte für Plattformen liefert
    static func defaultChecklistItems() -> [ChecklistItem] {
        return [
            ChecklistItem(name: "Bolzen"),
            ChecklistItem(name: "Beleuchtung"),
            ChecklistItem(name: "Kabelbefestigung"),
            ChecklistItem(name: "Markierungen"),
            ChecklistItem(name: "Sicherheitsmaßnahmen"),
            ChecklistItem(name: "Hindernisbefeuerung"),
            ChecklistItem(name: "Turm Sektionsnummer")
        ]
    }
}
