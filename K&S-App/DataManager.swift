import SwiftUI
import ZIPFoundation
import UniformTypeIdentifiers
import UIKit
import Foundation

class DataManager {
    private let profilesKey = "profiles"

    func loadProfiles() -> [Profile] {
        if let data = UserDefaults.standard.data(forKey: profilesKey) {
            do {
                let profiles = try JSONDecoder().decode([Profile].self, from: data)
                return profiles
            } catch {
                print("Error decoding profiles: \(error)")
            }
        }
        return []
    }

    func saveProfiles(_ profiles: [Profile]) {
        do {
            let data = try JSONEncoder().encode(profiles)
            UserDefaults.standard.set(data, forKey: profilesKey)
        } catch {
            print("Error encoding profiles: \(error)")
        }
    }

    func exportData(profile: Profile, exportType: ExportType) -> URL? {
        let fileManager = FileManager.default
        let exportFolderName = exportType == .checklist ? "Checklist" : "LOP"
        let tempDirectory = fileManager.temporaryDirectory.appendingPathComponent(exportFolderName)

        do {
            try fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

            switch exportType {
            case .checklist:
                try exportChecklistImages(profile: profile, to: tempDirectory)
            case .lop:
                try exportLOPImagesAndCSV(profile: profile, to: tempDirectory)
            }

            let zipURL = fileManager.temporaryDirectory.appendingPathComponent("\(exportFolderName).zip")
            try fileManager.zipItem(at: tempDirectory, to: zipURL)
            return zipURL

        } catch {
            print("Export error: \(error)")
            return nil
        }
    }

    private func exportChecklistImages(profile: Profile, to directory: URL) throws {
        var itemCounter = 1

        for category in profile.checklists {
            for subcategory in category.subcategories {
                for item in subcategory.items {
                    guard !item.images.isEmpty else { continue }

                    let sanitizedItemName = sanitize(item.name)

                    for (index, path) in item.images.enumerated() {
                        let imageName = "\(itemCounter)_\(index + 1)_\(sanitizedItemName).jpg"
                        let destination = directory.appendingPathComponent(imageName)

                        if FileManager.default.fileExists(atPath: path) {
                            try FileManager.default.copyItem(atPath: path, toPath: destination.path)
                        } else {
                            print("Skipped missing file: \(path)")
                        }
                    }

                    itemCounter += 1
                }
            }
        }
    }

    private func exportLOPImagesAndCSV(profile: Profile, to directory: URL) throws {
        var csvLines: [String] = ["Nummer,Kommentar"]

        for (lopIndex, item) in profile.lopItems.enumerated() {
            for (imageIndex, path) in item.images.enumerated() {
                let imageName = "\(lopIndex + 1)_\(imageIndex + 1).jpg"
                let destination = directory.appendingPathComponent(imageName)

                if FileManager.default.fileExists(atPath: path) {
                    try FileManager.default.copyItem(atPath: path, toPath: destination.path)
                } else {
                    print("Skipped missing file: \(path)")
                }
            }

            let line = "\(lopIndex + 1),\(item.comment.replacingOccurrences(of: ",", with: ";"))"
            csvLines.append(line)
        }

        let csvContent = csvLines.joined(separator: "\n")
        let csvURL = directory.appendingPathComponent("LOP_Kommentare.csv")
        try csvContent.write(to: csvURL, atomically: true, encoding: .utf8)
    }

    private func sanitize(_ string: String) -> String {
        return string.replacingOccurrences(of: "/", with: "_")
                       .replacingOccurrences(of: "\\", with: "_")
                       .replacingOccurrences(of: ":", with: "_")
                       .replacingOccurrences(of: "*", with: "_")
                       .replacingOccurrences(of: "?", with: "_")
                       .replacingOccurrences(of: "\"", with: "_")
                       .replacingOccurrences(of: "<", with: "_")
                       .replacingOccurrences(of: ">", with: "_")
                       .replacingOccurrences(of: "|", with: "_")
    }
}
