import SwiftUI

// Profilstruktur, die ein Benutzerprofil mit zugehörigen Daten darstellt
struct Profile: Identifiable, Codable {
    var id = UUID() // Eindeutige ID für jedes Profil
    var name: String // Name des Profils
    var mode: AppMode // Modus: WEA oder PV
    var checklists: [ChecklistCategory] = [] // Checklisten, gruppiert nach Kategorien
    var lopItems: [LOPItem] = [] // Liste von LOP-Einträgen (z. B. Mängel)
    var plattformen: [Plattform] = [] // Zugeordnete Plattformen mit Checklisten
}

// Enum zur Auswahl des App-Modus (z. B. Windenergie oder Photovoltaik)
enum AppMode: String, Codable {
    case wea = "WEA" // Windenergie
    case pv = "PV"   // Photovoltaik
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
struct ChecklistItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String // Beschreibung des Punktes
    var isCompleted: Bool = false // Wurde der Punkt abgeschlossen?
    var isLOP: Bool = false // Gehört der Punkt zu einem LOP (Mängel)?
    var comment: String = "" // Optionaler Kommentar zum Punkt
    var images: [String] = [] // Zugehörige Bilder (z. B. Dateipfade oder URLs)
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
