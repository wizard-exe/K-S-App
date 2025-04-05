import SwiftUI

struct Profile: Identifiable, Codable {
    var id = UUID()
    var name: String
    var mode: AppMode
    var checklists: [ChecklistCategory] = []
    var lopItems: [LOPItem] = []
    var platforms: [Platform] = []
}

enum AppMode: String, Codable {
    case wea = "WEA"
    case pv = "PV"
}

struct ChecklistCategory: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var subcategories: [ChecklistSubcategory]
}

struct ChecklistSubcategory: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var items: [ChecklistItem]
}

struct ChecklistItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var isCompleted: Bool = false
    var isLOP: Bool = false
    var comment: String = ""
    var images: [String] = []
}

struct LOPItem: Identifiable, Codable {
    var id = UUID()
    var title: String
    var comment: String
    var images: [String] = []
}

struct Platform: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var image: String? = nil
    var items: [ChecklistItem] = Platform.defaultChecklistItems()

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



