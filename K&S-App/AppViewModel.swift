import SwiftUI
import UIKit
import Foundation

class AppViewModel: ObservableObject {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Published var profiles: [Profile] = []
    @Published var activeProfile: Profile?
    @Published var searchQuery: String = ""
    
    private let dataManager = DataManager()
    
    init() {
        loadProfiles()
        if let firstProfile = profiles.first {
            activeProfile = firstProfile
        }
    }
    
    func loadProfiles() {
        profiles = dataManager.loadProfiles()
    }
    
    func saveProfiles() {
        dataManager.saveProfiles(profiles)
    }
    
    func createProfile(name: String, mode: AppMode) {
        let checklist: [ChecklistCategory] = (mode == .wea) ? defaultWEACategories() : defaultPVCategories()
        let newProfile = Profile(name: name, mode: mode, checklists: checklist)
        profiles.append(newProfile)
        activeProfile = newProfile
        saveProfiles()
    }
    
    private func defaultWEACategories() -> [ChecklistCategory] {
        return [
            ChecklistCategory(name: "Prüfbemerkungen", subcategories: [
                ChecklistSubcategory(name: "Kennzeichnung", items: [
                    ChecklistItem(name: "WEA-Standortkennzeichnung außen"),
                    ChecklistItem(name: "Sicherheitshinweise außen"),
                    ChecklistItem(name: "Hinweisschilder Gefahr durch Eisschlag"),
                    ChecklistItem(name: "Typenschild WEA"),
                    ChecklistItem(name: "Typenschild Turm"),
                    ChecklistItem(name: "CE-Kennzeichnung"),
                    ChecklistItem(name: "Steigleiter/Steigschutz Kennzeichnung"),
                    ChecklistItem(name: "Sicherheits- und Bedienhinweise"),
                    ChecklistItem(name: "Flucht- und Rettungsplan"),
                    ChecklistItem(name: "Beschriftung Bedienelemente"),
                    ChecklistItem(name: "Anschlagpunkte Kennzeichnung"),
                    ChecklistItem(name: "WEA-Tageskennzeichnung"),
                    ChecklistItem(name: "WEA-Nachtkennzeichnung"),
                    ChecklistItem(name: "Bedarfsgesteuerte Nachtkennzeichnung")
                ]),
                ChecklistSubcategory(name: "Dokumentation", items: [
                    ChecklistItem(name: "Betriebsanleitung"),
                    ChecklistItem(name: "Anlagenlogbuch/Einsatzberichte"),
                    ChecklistItem(name: "Wartungspflichtenheft"),
                    ChecklistItem(name: "Wartungsanleitung"),
                    ChecklistItem(name: "Wartungsprotokolle/Einsatzberichte"),
                    ChecklistItem(name: "EG-Konformitätserklärung"),
                    ChecklistItem(name: "Genehmigungsbescheid"),
                    ChecklistItem(name: "Übersichtsliste der Hauptkomponenten"),
                    ChecklistItem(name: "Statusliste"),
                    ChecklistItem(name: "Schaltpläne"),
                    ChecklistItem(name: "Inbetriebnahmeprotokoll"),
                    ChecklistItem(name: "Rotorblätter (Herstellerzertifikate)"),
                    ChecklistItem(name: "Kinematische Daten"),
                    ChecklistItem(name: "Fachunternehmererklärungen zur Eiserkennung"),
                    ChecklistItem(name: "Prüfnachweise für prüfpflichtige Ausrüstung"),
                    ChecklistItem(name: "Erdungsmessung/Nachweis Erdungswiderstand"),
                    ChecklistItem(name: "Errichterbestätigung DGUV V3")
                ]),
                ChecklistSubcategory(name: "Instandhaltung", items: [
                    ChecklistItem(name: "Datum der letzten Wartung"),
                    ChecklistItem(name: "Datum des letzten Überdrehzahltests")
                ]),
                ChecklistSubcategory(name: "Betriebsverhalten, Betriebs- und Sicherheitssysteme und Einstellungen", items: [
                    ChecklistItem(name: "Betriebsverhalten"),
                    ChecklistItem(name: "Ausrichtung zur Windrichtung"),
                    ChecklistItem(name: "Notabschaltungen, Auslösung der Sicherheitskette"),
                    ChecklistItem(name: "Brandschutz: Rauchmelder"),
                    ChecklistItem(name: "Eigenfrequenz Turm"),
                    ChecklistItem(name: "Anlagenparametrierung"),
                    ChecklistItem(name: "Temperaturüberwachung"),
                    ChecklistItem(name: "Schattenabschaltung"),
                    ChecklistItem(name: "Schallreduzierter Betrieb"),
                    ChecklistItem(name: "Artenschutzabschaltung (Fledermausabschaltung)"),
                    ChecklistItem(name: "Fledermausmonitoring")
                ]),
                ChecklistSubcategory(name: "Arbeitssicherheit, Arbeitsschutz, PSA und Aufstieg", items: [
                    ChecklistItem(name: "Feuerlöscher"),
                    ChecklistItem(name: "Verbandkästen"),
                    ChecklistItem(name: "Persönliche Schutzausrüstung gegen Absturz (PSAgA)"),
                    ChecklistItem(name: "Rettungsgerät"),
                    ChecklistItem(name: "Steigleitern"),
                    ChecklistItem(name: "Steigschutz"),
                    ChecklistItem(name: "Anschlagpunkte"),
                    ChecklistItem(name: "Servicelift"),
                    ChecklistItem(name: "Servicelift Aufhängung"),
                    ChecklistItem(name: "Beleuchtung und Notbeleuchtung"),
                    ChecklistItem(name: "Zugänge, Arbeitsplätze und Plattformen")
                ]),
                ChecklistSubcategory(name: "Netzanbindung", items: [
                    ChecklistItem(name: "Transformator"),
                    ChecklistItem(name: "Single Line Diagramm / Parkübersichtsplan")
                ]),
                ChecklistSubcategory(name: "Fundament", items: [
                    ChecklistItem(name: "Fundament Erdauflast"),
                    ChecklistItem(name: "Fundamentkörper außen (Risse)"),
                    ChecklistItem(name: "Vergussbeton außen"),
                    ChecklistItem(name: "Drainage"),
                    ChecklistItem(name: "Fundament innen"),
                    ChecklistItem(name: "Vergussbeton innen"),
                    ChecklistItem(name: "Fundament innen (Wassereintritt)"),
                    ChecklistItem(name: "Verkabelung/Einbauteile/Erdungssystem")
                ]),
                ChecklistSubcategory(name: "Turm", items: [
                    ChecklistItem(name: "Turmtür"),
                    ChecklistItem(name: "Flansche außen (Korrosion)"),
                    ChecklistItem(name: "Blechoberflächen außen"),
                    ChecklistItem(name: "Flanschverschraubungen innen"),
                    ChecklistItem(name: "Flansche innen (Korrosion)"),
                    ChecklistItem(name: "Schweißnähte innen"),
                    ChecklistItem(name: "Blechoberflächen innen"),
                    ChecklistItem(name: "Turm Betonsektionen außen (Risse)"),
                    ChecklistItem(name: "Turm Betonsektionen innen"),
                    ChecklistItem(name: "Eingangsebene (Materiallagerung)"),
                    ChecklistItem(name: "Schaltschränke"),
                    ChecklistItem(name: "Kabel/elektrische Installationen")
                ]),
                ChecklistSubcategory(name: "Gondel", items: [
                    ChecklistItem(name: "Zustand"),
                    ChecklistItem(name: "Gehäuse der Gondel"),
                    ChecklistItem(name: "Sensoren – Vibrationssensor"),
                    ChecklistItem(name: "Kran / Hebevorrichtung (aktuelle Prüfplakette)"),
                    ChecklistItem(name: "Sicherheitslaschen geprüft")
                ]),

                ChecklistSubcategory(name: "Top-Box / Wechselrichter", items: [
                    ChecklistItem(name: "Zustand"),
                    ChecklistItem(name: "Wechselrichter"),
                    ChecklistItem(name: "Steuerschrank"),
                    ChecklistItem(name: "Not-Aus-Taster")
                ]),

                ChecklistSubcategory(name: "Getriebe", items: [
                    ChecklistItem(name: "Zustand"),
                    ChecklistItem(name: "Dämpfungselemente"),
                    ChecklistItem(name: "Heiz- oder Kühlsystem"),
                    ChecklistItem(name: "Leckagen"),
                    ChecklistItem(name: "Lager"),
                    ChecklistItem(name: "Filtersystem"),
                    ChecklistItem(name: "Besondere Hinweise")
                ]),

                ChecklistSubcategory(name: "Generator", items: [
                    ChecklistItem(name: "Zustand"),
                    ChecklistItem(name: "Dämpfungselemente"),
                    ChecklistItem(name: "Kühlsystem"),
                    ChecklistItem(name: "Kupplung"),
                    ChecklistItem(name: "Schleifring – Zustand"),
                    ChecklistItem(name: "Besondere Hinweise")
                ]),

                ChecklistSubcategory(name: "Azimutsystem", items: [
                    ChecklistItem(name: "Antriebe"),
                    ChecklistItem(name: "Schmierung"),
                    ChecklistItem(name: "Zahnradantriebe"),
                    ChecklistItem(name: "Azimut-Zahnradring"),
                    ChecklistItem(name: "Bremseinheit"),
                    ChecklistItem(name: "Besondere Hinweise")
                ]),

                ChecklistSubcategory(name: "Sensoren / Hindernisbefeuerung", items: [
                    ChecklistItem(name: "Wetterstation"),
                    ChecklistItem(name: "Hindernisbefeuerung – Tag"),
                    ChecklistItem(name: "Eiserkennungssensor"),
                    ChecklistItem(name: "Hindernisbefeuerung – Nacht"),
                    ChecklistItem(name: "Notstromversorgung Befeuerung"),
                    ChecklistItem(name: "CMS-Sensoren und -System"),
                    ChecklistItem(name: "Cybersicherheit"),
                    ChecklistItem(name: "Besondere Hinweise")
                ]),

                ChecklistSubcategory(name: "Nabe", items: [
                    ChecklistItem(name: "Rotorverriegelung"),
                    ChecklistItem(name: "Zugang"),
                    ChecklistItem(name: "Pitchantriebe"),
                    ChecklistItem(name: "Blattlager"),
                    ChecklistItem(name: "Innere Ausrüstung"),
                    ChecklistItem(name: "Not-Aus-Taster"),
                    ChecklistItem(name: "Notenergieversorgung"),
                    ChecklistItem(name: "Blitzschutzsystem"),
                    ChecklistItem(name: "Besondere Hinweise")
                ]),

                ChecklistSubcategory(name: "Rotorblätter", items: [
                    ChecklistItem(name: "Blitzschutz"),
                    ChecklistItem(name: "Blattwurzel – innen"),
                    ChecklistItem(name: "Tageskennzeichnung Blattoberfläche"),
                    ChecklistItem(name: "Blattwurzel – außen"),
                    ChecklistItem(name: "Zustand Rotorblatt – außen"),
                    ChecklistItem(name: "Sensoren"),
                    ChecklistItem(name: "Besondere Hinweise")
                ])

            ])
        ]
    }
    
    private func defaultPVCategories() -> [ChecklistCategory] {
        return [
            
            ChecklistCategory(name: "Prüfbemerkungen", subcategories: [
                ChecklistSubcategory(name: "Kennzeichnung", items: [
                    ChecklistItem(name: "Typenschilder und CE-Kennzeichnung"),
                    ChecklistItem(name: "Warnbeschilderung"),
                    ChecklistItem(name: "Strangkabel und Unterverteiler (AC, GAK)")
                ]),
                ChecklistSubcategory(name: "Allgemeine Einrichtungen", items: [
                    ChecklistItem(name: "Zufahrt"),
                    ChecklistItem(name: "Verschmutzungsrisiko"),
                    ChecklistItem(name: "Sicherung, Überwachung")
                ]),
                ChecklistSubcategory(name: "Betriebsverhalten Wechselrichter und Anlagenzustand", items: [
                    ChecklistItem(name: "Genereller Zustand"),
                    ChecklistItem(name: "Elektrische Schaltpläne für Wechselrichter"),
                    ChecklistItem(name: "Aufgezeichnete Betriebsdaten – Messkanäle"),
                    ChecklistItem(name: "Wechselrichter-Display"),
                    ChecklistItem(name: "Zugang zu den Wechselrichtern"),
                    ChecklistItem(name: "Aufstellungsort der Wechselrichter"),
                    ChecklistItem(name: "Beschriftung Wechselrichter"),
                    ChecklistItem(name: "Überspannungsschutz - Zustand"),
                    ChecklistItem(name: "Berührschutz"),
                    ChecklistItem(name: "Erdungspunkte und PE-Schiene Korrosion, fester Sitz"),
                    ChecklistItem(name: "Netzeinspeisung")
                ]),
                ChecklistSubcategory(name: "Elektrische und maschinenbauliche Komponenten", items: [
                    ChecklistItem(name: "DC Anschluss Generatoranschlusskästen"),
                    ChecklistItem(name: "AC Sammelkästen"),
                    ChecklistItem(name: "Thermografische Untersuchungen der elektrischen Einrichtungen"),
                    ChecklistItem(name: "Betriebszustände Generatoranschlusskästen"),
                    ChecklistItem(name: "Stringbeschriftung bei GAKs, WRs")
                ]),
                ChecklistSubcategory(name: "MS-Bereich und Transformator, Übergabestation", items: [
                    ChecklistItem(name: "Allgemeiner Zustand"),
                    ChecklistItem(name: "Aufstellungsort"),
                    ChecklistItem(name: "Pläne, Schilder, Beschriftung"),
                    ChecklistItem(name: "Transformator"),
                    ChecklistItem(name: "Stationskeller"),
                    ChecklistItem(name: "MS-Schalter"),
                    ChecklistItem(name: "Erdungspunkte und PE-Schiene, Korrosion, fester Sitz"),
                    ChecklistItem(name: "Elektrische Anschlüsse"),
                    ChecklistItem(name: "Thermografische Untersuchungen der elektrischen Einrichtungen"),
                    ChecklistItem(name: "Energiezähler"),
                    ChecklistItem(name: "Fernwirktechnik für Direktvermarkter gemäß EEG"),
                    ChecklistItem(name: "BDEW-Mittelspannungsrichtlinie - notwendige Anlagenzertifikate")
                ]),
                ChecklistSubcategory(name: "Generator", items: [
                    ChecklistItem(name: "Standort und Ausrichtung"),
                    ChecklistItem(name: "Gelände"),
                    ChecklistItem(name: "Gestellsystem"),
                    ChecklistItem(name: "Gestellerdung"),
                    ChecklistItem(name: "Gestellfestigkeit"),
                    ChecklistItem(name: "Fundamente"),
                    ChecklistItem(name: "Gestellverzinkung allgemein"),
                    ChecklistItem(name: "Gestellverzinkungdicke"),
                    ChecklistItem(name: "Montage der GAK‘s, WR, AC-Verteiler"),
                    ChecklistItem(name: "Äußerer Blitzschutz"),
                    ChecklistItem(name: "Einstrahlungssensor"),
                    ChecklistItem(name: "Verschmutzung"),
                    ChecklistItem(name: "Interne, externe Verschattung")
                ]),
                ChecklistSubcategory(name: "Module und Befestigung", items: [
                    ChecklistItem(name: "Module"),
                    ChecklistItem(name: "Vergleichende Strommessungen"),
                    ChecklistItem(name: "Leistungsfähigkeit"),
                    ChecklistItem(name: "Modulbefestigung"),
                    ChecklistItem(name: "Modulbefestigung - Drehmoment"),
                    ChecklistItem(name: "Neigungswinkel Module"),
                    ChecklistItem(name: "Verschattungswinkel"),
                    ChecklistItem(name: "Modulabstände"),
                    ChecklistItem(name: "Modulbruch"),
                    ChecklistItem(name: "Optisch auffällige Module"),
                    ChecklistItem(name: "Thermisch auffällige Module")
                ]),
                ChecklistSubcategory(name: "Gleich- und Wechselstromleitungen", items: [
                    ChecklistItem(name: "Kantenschutz (Kabel)"),
                    ChecklistItem(name: "Kabelfixierung, UV-Beständigkeit"),
                    ChecklistItem(name: "Stringverkabelung"),
                    ChecklistItem(name: "Kabelführung Gleichstrom"),
                    ChecklistItem(name: "Kabelführung Wechselstrom"),
                    ChecklistItem(name: "Steckverbinder"),
                    ChecklistItem(name: "Leiterschlaufen und Biegeradien")
                ])
            ])
        ]
    }
    
    func deleteProfile(_ profile: Profile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            // Delete associated images
            deleteProfileImages(profile)
            
            profiles.remove(at: index)
            if profile.id == activeProfile?.id {
                activeProfile = profiles.first
            }
            saveProfiles()
        }
    }
    
    func updateProfile(_ profile: Profile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
            if profile.id == activeProfile?.id {
                activeProfile = profile
            }
            saveProfiles()
        }
    }
    
    func setActiveProfile(_ profile: Profile) {
        activeProfile = profile
    }
    
    func resetActiveProfile() {
        if let profile = activeProfile {
            // Delete associated images
            deleteProfileImages(profile)
            
            let updatedProfile = Profile(id: profile.id, name: profile.name, mode: profile.mode)
            updateProfile(updatedProfile)
        }
    }
    
    func deleteProfileImages(_ profile: Profile) {
        // Delete checklist images
        for category in profile.checklists {
            for subcategory in category.subcategories {
                for item in subcategory.items {
                    for imagePath in item.images {
                        deleteImage(at: imagePath)
                    }
                }
            }
        }
        
        // Delete LOP images
        for lopItem in profile.lopItems {
            for imagePath in lopItem.images {
                deleteImage(at: imagePath)
            }
        }
        
        // Delete platform images
        for platform in profile.platforms {
            if let imagePath = platform.image {
                deleteImage(at: imagePath)
            }
        }
    }
    
    func deleteImage(at path: String) {
        do {
            try FileManager.default.removeItem(atPath: path)
        } catch {
            print("Error deleting image: \(error)")
        }
    }
    
    func saveImageToGallery(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
    
    func saveImage(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = UUID().uuidString + ".jpg"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            saveImageToGallery(image) // Always save to Photo Gallery as requested
            return fileURL.path
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
    
    func exportData(exportType: ExportType) -> URL? {
        guard let profile = activeProfile else { return nil }
        
        // Implementation for exporting data as CSV and images as ZIP
        // This would include creating CSV files for checklists or LOP items
        // and packaging them with images into a ZIP file
        
        return dataManager.exportData(profile: profile, exportType: exportType)
    }
    
    // Filtered checklists based on search query
    var filteredChecklists: [ChecklistCategory] {
        guard let profile = activeProfile else { return [] }
        
        if searchQuery.isEmpty {
            return profile.checklists
        }
        
        return profile.checklists.compactMap { category in
            let filteredSubcategories = category.subcategories.compactMap { subcategory in
                let filteredItems = subcategory.items.filter { item in
                    item.name.lowercased().contains(searchQuery.lowercased()) ||
                    item.comment.lowercased().contains(searchQuery.lowercased())
                }
                
                return filteredItems.isEmpty ? nil : ChecklistSubcategory(id: subcategory.id, name: subcategory.name, items: filteredItems)
            }
            
            return filteredSubcategories.isEmpty ? nil : ChecklistCategory(id: category.id, name: category.name, subcategories: filteredSubcategories)
        }
    }
    
    // Add a checklist item to LOP
    func addToLOP(item: ChecklistItem) {
        guard let profile = activeProfile else { return }
        
        let lopNumber = profile.lopItems.count + 1
        let lopItem = LOPItem(
            title: "LOP-\(lopNumber)",
            comment: item.comment,
            images: item.images
        )
        
        activeProfile?.lopItems.append(lopItem)
        saveProfiles()
    }
    
    // Add a new platform (only for WEA mode)
    func addPlatform(name: String, image: UIImage?) {
        guard let profile = activeProfile, profile.mode == .wea else { return }
        
        var imagePath: String? = nil
        if let image = image {
            imagePath = saveImage(image)
        }
        
        let platform = Platform(name: name, image: imagePath)
        activeProfile?.platforms.append(platform)
        saveProfiles()
    }
}

enum ExportType {
    case checklist
    case lop
}
