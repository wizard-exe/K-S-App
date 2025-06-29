import SwiftUI
import ZIPFoundation
import UniformTypeIdentifiers
import UIKit
import Foundation

class DataManager {
    private let profilesKey = "profiles" // Schlüssel für UserDefaults
    private let correctionEndpoint = URL(string: "https://k-s-app-backend.onrender.com/korrigiere")!

    // Lädt Profile aus dem persistenten Speicher (UserDefaults)
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

    // Speichert Profile im persistenten Speicher (UserDefaults)
    func saveProfiles(_ profiles: [Profile]) {
        do {
            let data = try JSONEncoder().encode(profiles)
            UserDefaults.standard.set(data, forKey: profilesKey)
        } catch {
            print("Error encoding profiles: \(error)")
        }
    }

    // Exportiert Profildaten (Checkliste oder LOP) als ZIP-Datei
    func exportData(profile: Profile, exportType: ExportType) -> URL? {
        let semaphore = DispatchSemaphore(value: 0)
        var finalURL: URL?

        Task {
            finalURL = await exportDataAsync(profile: profile, exportType: exportType)
            semaphore.signal()
        }

        semaphore.wait()
        return finalURL
    }

    // Exportiert Profildaten asynchron als ZIP-Datei
    private func exportDataAsync(profile: Profile, exportType: ExportType) async -> URL? {
        let fileManager = FileManager.default
        let exportFolderName = exportType == .checklist ? "Checklist" : "LOP"
        let tempDirectory = fileManager.temporaryDirectory.appendingPathComponent(exportFolderName)

        do {
            if fileManager.fileExists(atPath: tempDirectory.path) {
                try fileManager.removeItem(at: tempDirectory)
            }
            try fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

            switch exportType {
            case .checklist:
                try exportChecklistImages(profile: profile, to: tempDirectory.appendingPathComponent("Images"))
            case .lop:
                try exportLOPImages(profile: profile, to: tempDirectory.appendingPathComponent("Images"))
                try await exportLOPCSV(profile: profile, to: tempDirectory)
            }

            let zipURL = fileManager.temporaryDirectory.appendingPathComponent("\(exportFolderName).zip")
            if fileManager.fileExists(atPath: zipURL.path) {
                try fileManager.removeItem(at: zipURL)
            }
            try fileManager.zipItem(at: tempDirectory, to: zipURL)
            return zipURL

        } catch {
            print("Export error: \(error)")
            return nil
        }
    }

    // Exportiert Bilder aus Checklistenpunkten in ein Zielverzeichnis
    private func exportChecklistImages(profile: Profile, to directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var itemCounter = 1

        for category in profile.checklists {
            for subcategory in category.subcategories {
                for item in subcategory.items {
                    guard !item.images.isEmpty else { continue }
                    let sanitizedItemName = sanitize(item.name)

                    for (index, path) in item.images.enumerated() {
                        let imageName = "\(itemCounter)_\(index + 1)_\(sanitizedItemName).jpg"
                        let destination = directory.appendingPathComponent(imageName)

                        // Bild exportieren, aber nie größer als 1 MB
                        if FileManager.default.fileExists(atPath: path), let image = UIImage(contentsOfFile: path) {
                            if let jpegData = jpegDataBelow1MB(for: image) {
                                try jpegData.write(to: destination)
                            }
                        } else {
                            print("Skipped missing file: \(path)")
                        }
                    }
                    itemCounter += 1
                }
            }
        }
    }

    // Exportiert Bilder aus LOP-Einträgen in ein Zielverzeichnis
    private func exportLOPImages(profile: Profile, to directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        for (lopIndex, item) in profile.lopItems.enumerated() {
            for (imageIndex, path) in item.images.enumerated() {
                let imageName = "\(lopIndex + 1)_\(imageIndex + 1).jpg"
                let destination = directory.appendingPathComponent(imageName)

                // Bild exportieren, aber nie größer als 1 MB
                if FileManager.default.fileExists(atPath: path), let image = UIImage(contentsOfFile: path) {
                    if let jpegData = jpegDataBelow1MB(for: image) {
                        try jpegData.write(to: destination)
                    }
                } else {
                    print("Skipped missing file: \(path)")
                }
            }
        }
    }

    // Gibt komprimiertes JPEG-Data < 1MB zurück (oder nil, falls nicht möglich)
    private func jpegDataBelow1MB(for image: UIImage) -> Data? {
        let maxFileSize: Int = 1_048_576 // 1 MB in Bytes
        var compression: CGFloat = 0.8
        let minCompression: CGFloat = 0.05
        guard var data = image.jpegData(compressionQuality: compression) else { return nil }

        // Solange das Bild zu groß ist und wir noch weiter komprimieren können:
        while data.count > maxFileSize && compression > minCompression {
            compression -= 0.05
            if let compressedData = image.jpegData(compressionQuality: compression) {
                data = compressedData
            } else {
                break
            }
        }

        // Falls immer noch zu groß: versuchen, Bild zu verkleinern
        while data.count > maxFileSize && image.size.width > 300 && image.size.height > 300 {
            let newSize = CGSize(width: image.size.width * 0.8, height: image.size.height * 0.8)
            UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            if let resized = resizedImage, let resizedData = resized.jpegData(compressionQuality: compression) {
                data = resizedData
            } else {
                break
            }
        }

        return data.count <= maxFileSize ? data : nil
    }

    // Exportiert LOP-Einträge als CSV-Datei und korrigiert Kommentare online
    private func exportLOPCSV(profile: Profile, to directory: URL) async throws {
        let csvURL = directory.appendingPathComponent("LOP.csv")
        var csvText = "Nr.,Kommentar\n"

        for (index, item) in profile.lopItems.enumerated() {
            let corrected = await correctComment(item.comment)
            let line = "\(index + 1),\"\(corrected.replacingOccurrences(of: "\"", with: "\"\""))\""
            csvText.append("\(line)\n")
        }

        try csvText.write(to: csvURL, atomically: true, encoding: .utf8)
    }

    // Korrigiert einen Kommentartext über einen externen Webservice
    private func correctComment(_ text: String) async -> String {
        var request = URLRequest(url: correctionEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = ["text": text]
        request.httpBody = try? JSONEncoder().encode(body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                if let decoded = try? JSONDecoder().decode([String: String].self, from: data),
                   let corrected = decoded["technisch"] {
                    return corrected
                }
            } else if let httpResponse = response as? HTTPURLResponse {
                print("Correction server error: \(httpResponse.statusCode)")
            }
        } catch {
            print("Correction request failed: \(error)")
        }

        return text
    }

    // Entfernt unerwünschte Zeichen aus Strings für Dateinamen
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
