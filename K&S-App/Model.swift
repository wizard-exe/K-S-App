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

struct ChecklistCategory: Identifiable, Codable {
    var id = UUID()
    var name: String
    var subcategories: [ChecklistSubcategory]
}

struct ChecklistSubcategory: Identifiable, Codable {
    var id = UUID()
    var name: String
    var items: [ChecklistItem]
}

struct ChecklistItem: Identifiable, Codable {
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

struct Platform: Identifiable, Codable {
    var id = UUID()
    var name: String
    var image: String?
    var bolts: FeatureStatus = FeatureStatus()
    var lighting: FeatureStatus = FeatureStatus()
    var cableFastening: FeatureStatus = FeatureStatus()
    var markings: FeatureStatus = FeatureStatus()
    var safetyMeasures: FeatureStatus = FeatureStatus()
    var obstacleBeacon: FeatureStatus = FeatureStatus()
}

struct FeatureStatus: Codable {
    var isActive: Bool = false
    var comment: String = ""
}
