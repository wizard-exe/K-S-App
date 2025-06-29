import SwiftUI
import Combine

// Die ContentView ist der Einstiegspunkt der App und steuert die Hauptnavigation
struct ContentView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showMenu = false

    var body: some View {
        ZStack {
            // Hauptnavigation für die App
            NavigationView {
                Group {
                    // Zeige Willkommensbildschirm, falls keine Profile vorhanden sind
                    if viewModel.profiles.isEmpty {
                        WelcomeView()
                            .environmentObject(viewModel)
                    }
                    // Zeige MainView für das aktuell aktive Profil
                    else if let profile = viewModel.activeProfile {
                        MainView(profile: profile)
                            .environmentObject(viewModel)
                    }
                    // Fallback, falls kein Profil aktiv ist
                    else {
                        WelcomeView()
                            .environmentObject(viewModel)
                    }
                }
                .navigationBarTitle(viewModel.activeProfile?.name ?? "", displayMode: .inline)
                .navigationBarItems(
                    leading: Button(action: {
                        // Öffnet/Schließt das Seitenmenü
                        withAnimation {
                            showMenu.toggle()
                        }
                    }) {
                        Image(systemName: "line.horizontal.3")
                            .foregroundColor(Color(.white))
                    },
                    trailing: HStack {
                        // Zahnrad für Einstellungen, nur wenn ein Profil aktiv ist
                        if viewModel.activeProfile != nil {
                            NavigationLink(destination: SettingsView().environmentObject(viewModel)) {
                                Image(systemName: "gear")
                                    .foregroundColor(Color(.white))
                            }
                        }
                    }
                )
            }
            .zIndex(0)

            // Überlagertes Sidebar-Menü
            if showMenu {
                SidebarView(isShowing: $showMenu)
                    .environmentObject(viewModel)
                    .transition(.move(edge: .leading))
                    .zIndex(1)
            }
        }
    }
}

// Zeigt den Startbildschirm, wenn noch kein Profil existiert
struct WelcomeView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showCreateProfile = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // App-Logo
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .frame(width: 200, height: 200)
                .background(Color.white)

            // Einleitungstext
            Text("Erstellen Sie ein Profil, um mit der technischen Dokumentation zu beginnen.")
                .font(.body)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            // Button zum Erstellen eines neuen Profils
            Button(action: {
                showCreateProfile = true
            }) {
                Text("Profil erstellen")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .foregroundColor(Color("KSBlue"))
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.bottom, 50)
        }
        .padding()
        .background(Color("KSBlue"))
        .ignoresSafeArea()
        // Sheet für das Erstellen eines neuen Profils
        .sheet(isPresented: $showCreateProfile) {
            CreateProfileView()
                .environmentObject(viewModel)
        }
    }
}

// View zum Erstellen eines neuen Profils, inklusive Modusauswahl
struct CreateProfileView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var profileName = ""
    @State private var selectedMode: AppMode = .wea

    var body: some View {
        NavigationView {
            Form {
                // Bereich für Profilinformationen
                Section(header: Text("Profil-Informationen")) {
                    // Eingabe für Profilnamen
                    TextField("Profilname", text: $profileName)

                    // Auswahl des Modus (Windenergie oder Photovoltaik)
                    Picker("Modus", selection: $selectedMode) {
                        Text("Windenergieanlage").tag(AppMode.wea)
                        Text("Photovoltaik").tag(AppMode.pv)
                        Text("BESS").tag(AppMode.bess)
                        Text("DomRep").tag(AppMode.domrep)
                    }
                    .pickerStyle(WheelPickerStyle())
                }
            }
            .navigationBarTitle("Neues Profil", displayMode: .inline)
            .navigationBarItems(
                // Button zum Abbrechen
                leading: Button("Abbrechen") {
                    presentationMode.wrappedValue.dismiss()
                },
                // Button zum Erstellen, nur aktiv, wenn ein Name eingegeben wurde
                trailing: Button("Erstellen") {
                    viewModel.createProfile(name: profileName, mode: selectedMode)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(profileName.isEmpty)
            )
            .tint(.white)
        }
    }
}

// Seitenleiste für die Profilverwaltung und Navigation
struct SidebarView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Binding var isShowing: Bool
    @State private var showCreateProfile = false
    @State private var profileToDelete: Profile?
    @State private var showDeleteConfirmation = false

    var body: some View {
        ZStack {
            // Dunkler Overlay-Hintergrund, schließt das Menü bei Klick
            Color.black.opacity(0.5)
                .onTapGesture {
                    withAnimation {
                        isShowing = false
                    }
                }

            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Spacer()
                        // Schließen-Button für die Sidebar
                        Button(action: {
                            withAnimation {
                                isShowing = false
                            }
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .padding(.top, 80)

                    Divider()

                    // Liste aller vorhandenen Profile
                    List {
                        ForEach(viewModel.profiles) { profile in
                            Button(action: {
                                viewModel.setActiveProfile(profile)
                                withAnimation {
                                    isShowing = false
                                }
                            }) {
                                HStack {
                                    Text(profile.name)
                                        .foregroundColor(.primary)

                                    Spacer()

                                    // Zeigt den Profilmodus (WEA/PV)
                                    Text(profile.mode.rawValue)
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    // Häkchen für das aktuell aktive Profil
                                    if viewModel.activeProfile?.id == profile.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(Color("KSBlue"))
                                    }
                                }
                            }
                            // Swipe-to-Delete für jedes Profil
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    profileToDelete = profile
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("Löschen", systemImage: "trash")
                                }
                            }
                        }

                        // Button für das Anlegen eines neuen Profils
                        Button(action: {
                            showCreateProfile = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Neues Profil")
                            }
                            .foregroundColor(Color("KSBlue"))
                        }
                    }
                    .listStyle(PlainListStyle())

                    Spacer()
                }
                .frame(width: 300)
                .background(Color.white)
                .edgesIgnoringSafeArea(.vertical)

                Spacer()
            }
        }
        .edgesIgnoringSafeArea(.all)
        .sheet(isPresented: $showCreateProfile) {
            CreateProfileView()
                .environmentObject(viewModel)
        }
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("Profil löschen"),
                message: Text("Möchtest du das Profil \(profileToDelete?.name ?? "") wirklich löschen?"),
                primaryButton: .destructive(Text("Löschen")) {
                    if let profile = profileToDelete {
                        viewModel.deleteProfile(profile)
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
}

// Haupt-Inhaltsansicht für ein Profil: Steuert die Tabs (Checkliste, LOP, ggf. Plattformen, Export)
struct MainView: View {
    @EnvironmentObject var viewModel: AppViewModel
    let profile: Profile
    @AppStorage("SelectedTabIndex") private var selectedTab = 0

    var body: some View {
        // TabView für die vier Hauptbereiche der App
        TabView(selection: $selectedTab) {
            // Tab: Checkliste
            ChecklistView()
                .tabItem {
                    Image(systemName: "checklist")
                    Text("Checkliste")
                }
                .tag(0)

            // Tab: LOP (List of Open Points)
            LOPView()
                .tabItem {
                    Image(systemName: "exclamationmark.circle")
                    Text("LOP")
                }
                .tag(1)

            // Tab: Plattformen (nur für WEA-Profile)
            if profile.mode == .wea {
                PlattformenView()
                    .tabItem {
                        Image(systemName: "square.stack.3d.up")
                        Text("Plattformen")
                    }
                    .tag(2)
            }

            // Tab: Export-Funktion
            ExportView()
                .tabItem {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export")
                }
                .tag(3)
        }
        .accentColor(Color("KSBlue"))
    }
}

// Zeigt alle Checklisten-Kategorien eines Profils an (Hauptübersicht)
struct ChecklistView: View {
    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Suchleiste mit Lupe
            SearchBar(text: $viewModel.searchQuery)
                .padding(.horizontal, 8)
                .padding(.top, 6)

            List {
                if let profile = viewModel.activeProfile {
                    ForEach(filteredCategories(profile: profile)) { category in
                        let filteredSubcategories = self.filteredSubcategories(category: category)
                        if !filteredSubcategories.isEmpty {
                            Section(header: Text(category.name).font(.headline)) {
                                ForEach(filteredSubcategories) { subcategory in
                                    let filteredItems = self.filteredItems(subcategory: subcategory)
                                    if !filteredItems.isEmpty {
                                        NavigationLink(
                                            destination: ChecklistSubcategoryItemListViewFiltered(
                                                category: category,
                                                subcategory: subcategory,
                                                filteredItems: filteredItems
                                            )
                                        ) {
                                            ChecklistSubcategoryRowView(
                                                name: subcategory.name,
                                                observer: SubcategoryCompletionObserver(items: filteredItems)
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Checkliste")
        }
    }

    // Kategorien filtern: Nur behalten, wenn darunter Subkategorien mit Items sind, die zum Suchtext passen
    private func filteredCategories(profile: Profile) -> [ChecklistCategory] {
        guard !viewModel.searchQuery.isEmpty else { return profile.checklists }
        return profile.checklists.filter { category in
            category.subcategories.contains { sub in
                filteredItems(subcategory: sub).count > 0
            }
        }
    }

    // Subkategorien filtern: Nur behalten, wenn darin Items zum Suchtext passen
    private func filteredSubcategories(category: ChecklistCategory) -> [ChecklistSubcategory] {
        guard !viewModel.searchQuery.isEmpty else { return category.subcategories }
        return category.subcategories.filter { sub in
            filteredItems(subcategory: sub).count > 0
        }
    }

    // Items filtern: Nur behalten, wenn der Item-Name zum Suchtext passt
    private func filteredItems(subcategory: ChecklistSubcategory) -> [ChecklistItem] {
        guard !viewModel.searchQuery.isEmpty else { return subcategory.items }
        return subcategory.items.filter { item in
            item.name.localizedCaseInsensitiveContains(viewModel.searchQuery)
        }
    }
}

//Zeigt gefilterte Items einer Subkategorie an (für NavigationLink im Filter-Modus)
struct ChecklistSubcategoryItemListViewFiltered: View {
    @EnvironmentObject var viewModel: AppViewModel
    let category: ChecklistCategory
    let subcategory: ChecklistSubcategory
    let filteredItems: [ChecklistItem]

    @State private var showImagePicker = false
    @State private var selectedItemIndex: Int? = nil
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var selectedImage: UIImage?
    @State private var navigationTargetIndex: Int? = nil

    var body: some View {
        List {
            ForEach(filteredItems.indices, id: \.self) { index in
                let item = filteredItems[index]
                HStack(spacing: 12) {
                    Button(action: {
                        if let globalItem = globalBinding(for: item) {
                            globalItem.isCompleted.wrappedValue.toggle()
                            viewModel.saveProfiles()
                        }
                    }) {
                        Image(systemName: item.isCompleted ? "checkmark.square.fill" : "square")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(Color("KSBlue"))
                    }
                    .buttonStyle(BorderlessButtonStyle())

                    Text(item.name)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    HStack {
                        Button(action: {
                            sourceType = .camera
                            selectedItemIndex = index
                            showImagePicker = true
                        }) {
                            Image(systemName: "camera")
                        }
                        .buttonStyle(BorderlessButtonStyle())

                        Button(action: {
                            navigationTargetIndex = index
                        }) {
                            Image(systemName: "info.circle")
                        }
                        .buttonStyle(BorderlessButtonStyle())

                        ZStack {
                            NavigationLink(
                                destination: detailView(for: item),
                                tag: index,
                                selection: $navigationTargetIndex,
                                label: { EmptyView() }
                            )
                            .frame(width: 0, height: 0)
                            .hidden()
                        }
                    }
                }
                .contentShape(Rectangle())
            }
        }
        .navigationTitle(subcategory.name)
    }

    // Liefert das globale Binding zum Item (wichtig für Status-Updates!)
    func globalBinding(for filteredItem: ChecklistItem) -> Binding<ChecklistItem>? {
        guard let profile = viewModel.activeProfile,
              let profileIndex = viewModel.profiles.firstIndex(where: { $0.id == profile.id }),
              let categoryIndex = viewModel.profiles[profileIndex].checklists.firstIndex(where: { $0.id == category.id }),
              let subcategoryIndex = viewModel.profiles[profileIndex].checklists[categoryIndex].subcategories.firstIndex(where: { $0.id == subcategory.id }),
              let itemIndex = viewModel.profiles[profileIndex].checklists[categoryIndex].subcategories[subcategoryIndex].items.firstIndex(where: { $0.id == filteredItem.id })
        else { return nil }
        return $viewModel.profiles[profileIndex].checklists[categoryIndex].subcategories[subcategoryIndex].items[itemIndex]
    }

    // Navigiert zur Detailansicht für das Item
    private func detailView(for item: ChecklistItem) -> some View {
        if let global = globalBinding(for: item) {
            return AnyView(ChecklistItemDetailView(
                category: category,
                subcategory: subcategory,
                itemIndex: 0, // index für filtered view ist irrelevant!
                item: global
            ).environmentObject(viewModel))
        }
        return AnyView(EmptyView())
    }
}

// Erweiterung, damit Int in ForEach verwendet werden kann
extension Int: Identifiable {
    public var id: Int { self }
}

struct ChecklistSubcategoryRowView: View {
    let name: String
    @ObservedObject var observer: SubcategoryCompletionObserver

    var body: some View {
        HStack {
            Text(name)
            Spacer()
            if observer.allCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
    }
}

class SubcategoryCompletionObserver: ObservableObject {
    @Published var allCompleted: Bool = false

    private var cancellables: [AnyCancellable] = []

    init(items: [ChecklistItem]) {
        update(items: items)
    }

    func update(items: [ChecklistItem]) {
        cancellables.removeAll()
        allCompleted = items.allSatisfy { $0.isCompleted }

        for item in items {
            item.objectWillChange
                .sink { [weak self] _ in
                    DispatchQueue.main.async {
                        self?.allCompleted = items.allSatisfy { $0.isCompleted }
                    }
                }
                .store(in: &cancellables)
        }
    }
}


// Zeigt alle Items einer Unterkategorie an, inkl. Status und Bilder
struct ChecklistSubcategoryItemListView: View {
    @EnvironmentObject var viewModel: AppViewModel
    let category: ChecklistCategory
    let subcategory: ChecklistSubcategory

    @State private var showImagePicker = false
    @State private var selectedItemIndex: Int? = nil
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var selectedImage: UIImage?
    @State private var navigationTargetIndex: Int? = nil

    var body: some View {
        List {
            // Zugriff auf aktuelle Listen-Position im globalen Model
            if let profileIndex = viewModel.profiles.firstIndex(where: { $0.id == viewModel.activeProfile?.id }),
               let categoryIndex = viewModel.profiles[profileIndex].checklists.firstIndex(where: { $0.id == category.id }),
               let subcategoryIndex = viewModel.profiles[profileIndex].checklists[categoryIndex].subcategories.firstIndex(where: { $0.id == subcategory.id }) {

                // Alle Items der Subkategorie als eigene Zeilen
                ForEach(viewModel.profiles[profileIndex].checklists[categoryIndex].subcategories[subcategoryIndex].items.indices, id: \.self) { index in
                    let binding = $viewModel.profiles[profileIndex].checklists[categoryIndex].subcategories[subcategoryIndex].items[index]
                    let item = binding.wrappedValue

                    HStack(spacing: 12) {
                        // Button zum Abhaken des Items
                        Button(action: {
                            binding.isCompleted.wrappedValue.toggle()
                            viewModel.saveProfiles()
                        }) {
                            Image(systemName: item.isCompleted ? "checkmark.square.fill" : "square")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(Color("KSBlue"))
                        }
                        .buttonStyle(BorderlessButtonStyle())

                        // Name des Items
                        Text(item.name)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)

                        Spacer()

                        // Schnelle Aktionen: Kamera, Detailansicht
                        HStack {
                            // Foto aufnehmen und zuweisen
                            Button(action: {
                                sourceType = .camera
                                selectedItemIndex = index
                                showImagePicker = true
                            }) {
                                Image(systemName: "camera")
                            }
                            .buttonStyle(BorderlessButtonStyle())

                            // Navigiere zu Detailansicht des Items
                            Button(action: {
                                navigationTargetIndex = index
                            }) {
                                Image(systemName: "info.circle")
                            }
                            .buttonStyle(BorderlessButtonStyle())

                            // NavigationLink für Detail-Ansicht (versteckt)
                            ZStack {
                                NavigationLink(
                                    destination: detailView(for: index),
                                    tag: index,
                                    selection: $navigationTargetIndex,
                                    label: { EmptyView() }
                                )
                                .frame(width: 0, height: 0)
                                .hidden()
                            }
                        }
                    }
                    .contentShape(Rectangle())
                    // Tap auf Zeile öffnet auch Kamera (außer auf Button-Fläche)
                    .onTapGesture {
                        if !isTapInsideButtonArea() {
                            sourceType = .camera
                            selectedItemIndex = index
                            showImagePicker = true
                        }
                    }
                }
            }
        }
        .navigationTitle(subcategory.name)
        // Zeigt ImagePicker als Vollbild, wenn benötigt
        .fullScreenCover(isPresented: $showImagePicker) {
            ImagePicker(sourceType: sourceType, selectedImage: $selectedImage, isPresented: $showImagePicker)
                .onDisappear {
                    // Bild abspeichern und dem Item hinzufügen
                    if let index = selectedItemIndex,
                       let image = selectedImage,
                       let path = viewModel.saveImage(image),
                       let profileIndex = viewModel.profiles.firstIndex(where: { $0.id == viewModel.activeProfile?.id }),
                       let categoryIndex = viewModel.profiles[profileIndex].checklists.firstIndex(where: { $0.id == category.id }),
                       let subcategoryIndex = viewModel.profiles[profileIndex].checklists[categoryIndex].subcategories.firstIndex(where: { $0.id == subcategory.id }) {

                        viewModel.profiles[profileIndex].checklists[categoryIndex].subcategories[subcategoryIndex].items[index].images.append(path)
                        viewModel.saveProfiles()
                        selectedImage = nil
                    }
                }
        }

    }

    // Liefert die Detail-Ansicht eines Items zurück
    private func detailView(for index: Int) -> some View {
        if let profileIndex = viewModel.profiles.firstIndex(where: { $0.id == viewModel.activeProfile?.id }),
           let categoryIndex = viewModel.profiles[profileIndex].checklists.firstIndex(where: { $0.id == category.id }),
           let subcategoryIndex = viewModel.profiles[profileIndex].checklists[categoryIndex].subcategories.firstIndex(where: { $0.id == subcategory.id }) {

            let binding = $viewModel.profiles[profileIndex]
                .checklists[categoryIndex]
                .subcategories[subcategoryIndex]
                .items[index]

            return AnyView(ChecklistItemDetailView(
                category: category,
                subcategory: subcategory,
                itemIndex: index,
                item: binding
            ).environmentObject(viewModel))
        }

        return AnyView(EmptyView())
    }

    // Optional: Verhindert versehentliche Mehrfachauslösung beim Tap (hier immer false)
    func isTapInsideButtonArea() -> Bool {
        false
    }
}

// Zeigt die Detailansicht eines einzelnen Checklist-Items inkl. Bilder und Kommentar
struct ChecklistItemDetailView: View {
    @EnvironmentObject var viewModel: AppViewModel
    let category: ChecklistCategory
    let subcategory: ChecklistSubcategory
    let itemIndex: Int

    @Binding var item: ChecklistItem

    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var selectedImage: UIImage? = nil
    @State private var showingFullScreenImage = false
    @State private var fullScreenImagePath: String?

    var body: some View {
        Form {
            // Kommentarbereich für das Item
            Section(header: Text("Kommentar")) {
                TextEditor(text: $item.comment)
                    .frame(minHeight: 100)
                    .onChange(of: item.comment) { _ in
                        // Speichert Kommentareingabe sofort
                        viewModel.saveProfiles()
                    }
            }

            // Bilderbereich mit Kamera/Galerie und Bildübersicht
            Section(header: Text("Bilder")) {
                HStack {
                    // Button für Kamera
                    Button(action: {
                        sourceType = .camera
                        showImagePicker = true
                    }) {
                        HStack {
                            Image(systemName: "camera")
                            Text("Foto aufnehmen")
                        }
                    }
                    .buttonStyle(BorderlessButtonStyle())

                    Spacer()

                    // Button für Galerie
                    Button(action: {
                        sourceType = .photoLibrary
                        showImagePicker = true
                    }) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            Text("Aus Galerie")
                        }
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }

                // Wenn Bilder vorhanden: als Scrollbar anzeigen, Löschen & Vollbild möglich
                if !item.images.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(item.images, id: \.self) { path in
                                if FileManager.default.fileExists(atPath: path),
                                   let uiImage = UIImage(contentsOfFile: path) {
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .cornerRadius(8)
                                            .clipped()
                                            .onTapGesture {
                                                // Bild in Vollbild öffnen
                                                fullScreenImagePath = path
                                                showingFullScreenImage = true
                                            }

                                        // Bild löschen-Button
                                        Button(action: {
                                            withAnimation {
                                                viewModel.deleteImage(at: path)
                                                if let index = item.images.firstIndex(of: path) {
                                                    item.images.remove(at: index)
                                                    viewModel.saveProfiles()
                                                }
                                            }
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                                .background(Color.white.clipShape(Circle()))
                                        }
                                        .offset(x: -8, y: 8)
                                    }
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            }

            // Button, um das Item zur LOP-Liste hinzuzufügen
            Section {
                Button(action: {
                    viewModel.addToLOP(item: item)
                }) {
                    Label("Zu LOP hinzufügen", systemImage: "plus.circle")
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Details")
        // Vollbild-ImagePicker für Fotos
        .fullScreenCover(isPresented: $showImagePicker) {
            ImagePicker(sourceType: sourceType, selectedImage: $selectedImage, isPresented: $showImagePicker)
        }
        .onChange(of: selectedImage) { newImage in
            if let image = newImage,
               let path = viewModel.saveImage(image) {
                item.images.append(path)
                viewModel.saveProfiles()
                selectedImage = nil
            }
        }
        // Vollbildanzeige für Bildansicht
        .fullScreenCover(isPresented: $showingFullScreenImage) {
            if let path = fullScreenImagePath,
               let uiImage = UIImage(contentsOfFile: path) {
                FullScreenImageView(image: uiImage, isPresented: $showingFullScreenImage)
            }
        }
    }
}

// LOPView zeigt die Übersicht und Verwaltung aller LOP-Einträge eines Profils
struct LOPView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showAddLOP = false
    @State private var lopItemToDelete: LOPItem?
    @State private var showDeleteConfirmation = false

    var body: some View {
        ZStack(alignment: .bottom) {
            List {
                // KEINE BILDER MEHR in der Übersicht!
                ForEach(viewModel.activeProfile?.lopItems ?? []) { lopItem in
                    NavigationLink(destination: LOPItemDetailView(lopItemId: lopItem.id)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(lopItem.title)
                                .font(.headline)
                            // Kommentar immer aktuell (persistenter Zugriff)
                            if let updatedComment = self.updatedComment(for: lopItem) {
                                if !updatedComment.isEmpty {
                                    Text(updatedComment)
                                        .font(.subheadline)
                                        .lineLimit(2)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            lopItemToDelete = lopItem
                            showDeleteConfirmation = true
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.bottom, 70)
            .navigationTitle("LOP")
            .navigationBarBackButtonHidden(true)

            Button(action: {
                showAddLOP = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Neuer LOP-Eintrag")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color("KSBlue"))
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding()
            }
        }
        .sheet(isPresented: $showAddLOP) {
            AddLOPItemView()
                .environmentObject(viewModel)
        }
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("LOP-Eintrag löschen"),
                message: Text("Möchtest du den LOP-Eintrag wirklich löschen?"),
                primaryButton: .destructive(Text("Löschen")) {
                    if let item = lopItemToDelete {
                        deleteLOPItem(item)
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }

    // Holt den aktuellen Kommentar aus dem ViewModel (immer live, nie aus alter Liste)
    private func updatedComment(for lopItem: LOPItem) -> String? {
        guard let profile = viewModel.activeProfile,
              let idx = viewModel.profiles.firstIndex(where: { $0.id == profile.id }),
              let lidx = viewModel.profiles[idx].lopItems.firstIndex(where: { $0.id == lopItem.id }) else { return lopItem.comment }
        return viewModel.profiles[idx].lopItems[lidx].comment
    }

    private func deleteLOPItem(_ item: LOPItem) {
        guard let profileIndex = viewModel.profiles.firstIndex(where: { $0.id == viewModel.activeProfile?.id }),
              let itemIndex = viewModel.profiles[profileIndex].lopItems.firstIndex(where: { $0.id == item.id }) else {
            return
        }
        for imagePath in viewModel.profiles[profileIndex].lopItems[itemIndex].images {
            viewModel.deleteImage(at: imagePath)
        }
        viewModel.profiles[profileIndex].lopItems.remove(at: itemIndex)
        viewModel.saveProfiles()
    }
}

// AddLOPItemView: Zum Hinzufügen eines neuen LOP-Eintrags mit beliebig vielen Bildern
struct AddLOPItemView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var comment = ""
    @State private var imagePaths: [String] = []
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var selectedImage: UIImage?
    @State private var showingFullScreenImage = false
    @State private var fullScreenImagePath: String?

    var body: some View {
        NavigationView {
            Form {
                // Kommentar-Eingabefeld
                Section(header: Text("Kommentar")) {
                    TextEditor(text: $comment)
                        .frame(minHeight: 100)
                }
                // Bild-Bereich (Kamera/Galerie & Scrollbar)
                Section(header: Text("Bilder")) {
                    HStack {
                        Button(action: {
                            sourceType = .camera
                            showImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: "camera")
                                Text("Foto aufnehmen")
                            }
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        
                        Spacer()
                        
                        Button(action: {
                            sourceType = .photoLibrary
                            showImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                Text("Aus Galerie")
                            }
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    // Horizontale Bild-Vorschau-Scrollbar mit Tap für Fullscreen
                    if !imagePaths.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(imagePaths, id: \.self) { path in
                                    if let uiImage = UIImage(contentsOfFile: path) {
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 100, height: 100)
                                                .cornerRadius(8)
                                                .clipped()
                                                .onTapGesture {
                                                    // Bild im Vollbild öffnen
                                                    fullScreenImagePath = path
                                                    showingFullScreenImage = true
                                                }
                                            // Bild löschen
                                            Button(action: {
                                                withAnimation {
                                                    viewModel.deleteImage(at: path)
                                                    imagePaths.removeAll { $0 == path }
                                                }
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.red)
                                                    .background(Color.white.clipShape(Circle()))
                                            }
                                            .offset(x: -8, y: 8)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Neuer LOP-Eintrag")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Abbrechen") {
                    // Noch nicht gespeicherte Bilder wieder löschen
                    for path in imagePaths {
                        viewModel.deleteImage(at: path)
                    }
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.white),
                trailing: Button("Speichern") {
                    guard let profile = viewModel.activeProfile,
                          let profileIndex = viewModel.profiles.firstIndex(where: { $0.id == profile.id }) else { return }
                    let lopNumber = viewModel.profiles[profileIndex].lopItems.count + 1
                    let lopItem = LOPItem(title: "LOP-\(lopNumber)", comment: comment, images: imagePaths)
                    presentationMode.wrappedValue.dismiss()
                    DispatchQueue.main.async {
                        viewModel.profiles[profileIndex].lopItems.append(lopItem)
                        viewModel.activeProfile = viewModel.profiles[profileIndex]
                        viewModel.saveProfiles()
                    }
                }
                .disabled(comment.isEmpty)
                .foregroundColor(.white)
            )
        }
        .navigationBarBackButtonHidden(true)
        // Vollbild-ImagePicker (Kamera/Galerie)
        .fullScreenCover(isPresented: $showImagePicker) {
            ImagePicker(sourceType: sourceType, selectedImage: $selectedImage, isPresented: $showImagePicker)
                .onDisappear {
                    if let image = selectedImage, let path = viewModel.saveImage(image) {
                        imagePaths.append(path)
                        selectedImage = nil
                    }
                }
        }
        // Vollbildanzeige für Bild (FullScreenImageWrapper als Standard deiner App)
        .fullScreenCover(isPresented: $showingFullScreenImage) {
            FullScreenImageWrapper(path: fullScreenImagePath, isPresented: $showingFullScreenImage)
        }
    }
}

// Zeigt ein einzelnes Bild im Fullscreen (aus Pfad geladen), mit einfachem "Schließen"-Button oben rechts.
// Kann als Wrapper für LOP, Checklist und Plattform genutzt werden.
struct FullScreenImageWrapper: View {
    let path: String?
    @Binding var isPresented: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Bild anzeigen, wenn Pfad vorhanden und Bild ladbar
            if let path = path, let uiImage = UIImage(contentsOfFile: path) {
                Color.black.ignoresSafeArea() // Hintergrund
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                    .ignoresSafeArea()
            } else {
                // Fallback, falls Bild fehlt
                Color.black.ignoresSafeArea()
                VStack {
                    Spacer()
                    Text("Bild nicht gefunden")
                        .foregroundColor(.white)
                        .font(.headline)
                    Spacer()
                }
            }

            // Schließen-Button
            Button(action: {
                isPresented = false
            }) {
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .frame(width: 38, height: 38)
                    .foregroundColor(.white)
                    .shadow(radius: 10)
                    .padding(20)
            }
        }
        .statusBar(hidden: true)
    }
}

// Detailansicht eines einzelnen LOP-Eintrags mit Fullscreen-Image
struct LOPItemDetailView: View {
    @EnvironmentObject var viewModel: AppViewModel
    let lopItemId: UUID

    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var selectedImage: UIImage?
    @State private var showingFullScreenImage = false
    @State private var fullScreenImagePath: String?

    private var lopItemIndex: (profileIndex: Int, lopIndex: Int)? {
        guard let profileIndex = viewModel.profiles.firstIndex(where: { $0.id == viewModel.activeProfile?.id }),
              let lopIndex = viewModel.profiles[profileIndex].lopItems.firstIndex(where: { $0.id == lopItemId }) else { return nil }
        return (profileIndex, lopIndex)
    }

    var body: some View {
        Form {
            Section(header: Text("Kommentar")) {
                if let idx = lopItemIndex {
                    TextEditor(text: Binding(
                        get: { viewModel.profiles[idx.profileIndex].lopItems[idx.lopIndex].comment },
                        set: { newValue in
                            viewModel.profiles[idx.profileIndex].lopItems[idx.lopIndex].comment = newValue
                            viewModel.saveProfiles()
                        }
                    ))
                    .frame(minHeight: 100)
                }
            }
            Section(header: Text("Bilder")) {
                HStack {
                    Button(action: {
                        sourceType = .camera
                        showImagePicker = true
                    }) {
                        HStack {
                            Image(systemName: "camera")
                            Text("Foto aufnehmen")
                        }
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    Spacer()
                    Button(action: {
                        sourceType = .photoLibrary
                        showImagePicker = true
                    }) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            Text("Aus Galerie")
                        }
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                if let idx = lopItemIndex {
                    let images = viewModel.profiles[idx.profileIndex].lopItems[idx.lopIndex].images
                    if !images.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(images, id: \.self) { path in
                                    if let uiImage = UIImage(contentsOfFile: path), !path.isEmpty {
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 100, height: 100)
                                                .cornerRadius(8)
                                                .clipped()
                                                .onTapGesture {
                                                    // Bild in Vollbild öffnen
                                                    fullScreenImagePath = path
                                                    showingFullScreenImage = true
                                                }
                                            Button(action: {
                                                withAnimation {
                                                    viewModel.deleteImage(at: path)
                                                    viewModel.profiles[idx.profileIndex].lopItems[idx.lopIndex].images.removeAll { $0 == path }
                                                    viewModel.saveProfiles()
                                                }
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.red)
                                                    .background(Color.white.clipShape(Circle()))
                                            }
                                            .offset(x: -8, y: 8)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(lopItem?.title ?? "LOP-Detail")
        .fullScreenCover(isPresented: $showImagePicker) {
            ImagePicker(sourceType: sourceType, selectedImage: $selectedImage, isPresented: $showImagePicker)
                .onDisappear {
                    if let idx = lopItemIndex, let image = selectedImage, let path = viewModel.saveImage(image) {
                        viewModel.profiles[idx.profileIndex].lopItems[idx.lopIndex].images.append(path)
                        viewModel.saveProfiles()
                        selectedImage = nil
                    }
                }
        }
        .fullScreenCover(isPresented: $showingFullScreenImage) {
            FullScreenImageWrapper(path: fullScreenImagePath, isPresented: $showingFullScreenImage)
        }
    }

    private var lopItem: LOPItem? {
        guard let idx = lopItemIndex else { return nil }
        return viewModel.profiles[idx.profileIndex].lopItems[idx.lopIndex]
    }
}


// PlattformenView: Zeigt die Liste aller Plattformen eines Profils an und erlaubt Hinzufügen und Löschen.
struct PlattformenView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showAddPlattform = false
    @State private var plattformToDelete: Plattform?
    @State private var showDeleteConfirmation = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Listendarstellung aller Plattformen mit Navigation zur Detailansicht
            List {
                ForEach(viewModel.activeProfile?.plattformen ?? []) { plattform in
                    NavigationLink(destination: PlattformDetailView(plattform: plattform)) {
                        Text(plattform.name)
                            .font(.headline)
                    }
                    // Swipe-Action zum Löschen einer Plattform
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            plattformToDelete = plattform
                            showDeleteConfirmation = true
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.bottom, 70)
            .navigationTitle("Plattformen")
            .navigationBarBackButtonHidden(true)

            // Button zum Hinzufügen einer neuen Plattform
            Button(action: {
                showAddPlattform = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Neue Plattform")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color("KSBlue"))
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding()
            }
        }
        // Sheet für die View zum Hinzufügen einer neuen Plattform
        .sheet(isPresented: $showAddPlattform) {
            AddPlattformView()
                .environmentObject(viewModel)
        }
        // Alert für Löschbestätigung
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("Plattform löschen"),
                message: Text("Möchtest du die Plattform wirklich löschen?"),
                primaryButton: .destructive(Text("Löschen")) {
                    if let plattform = plattformToDelete {
                        deletePlattform(plattform)
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }

    // Entfernt eine Plattform aus dem Profil, inkl. Bild
    private func deletePlattform(_ plattform: Plattform) {
        guard let profileIndex = viewModel.profiles.firstIndex(where: { $0.id == viewModel.activeProfile?.id }),
              let plattformIndex = viewModel.profiles[profileIndex].plattformen.firstIndex(where: { $0.id == plattform.id }) else {
            return
        }

        // Löscht zugehöriges Bild (falls vorhanden)
        if let imagePath = viewModel.profiles[profileIndex].plattformen[plattformIndex].image {
            viewModel.deleteImage(at: imagePath)
        }

        // Plattform aus Liste entfernen und speichern
        viewModel.profiles[profileIndex].plattformen.remove(at: plattformIndex)
        viewModel.saveProfiles()
    }
}

// AddPlattformView: Eingabemaske zum Erstellen einer neuen Plattform mit Namen und optionalem Bild
struct AddPlattformView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var name = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera

    var body: some View {
        NavigationView {
            Form {
                // Eingabefeld für den Namen der neuen Plattform
                Section(header: Text("Name")) {
                    TextField("Plattform-Name", text: $name)
                }
                // Hier könnte optional noch ein Bild hinzugefügt werden (ausbaubar)
            }
            .navigationTitle("Neue Plattform")
            .navigationBarItems(
                // Abbrechen: Schließt die Eingabemaske
                leading: Button("Abbrechen") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.white),
                // Speichern: Legt die neue Plattform an
                trailing: Button("Speichern") {
                    addPlattform()
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.white)
                .disabled(name.isEmpty) // Nur aktiv, wenn Name vergeben
            )
        }
    }

    // Fügt die Plattform mit optionalem Bild zum aktuellen Profil hinzu
    private func addPlattform() {
        guard let profile = viewModel.activeProfile,
              let profileIndex = viewModel.profiles.firstIndex(where: { $0.id == profile.id }) else { return }

        // Bild speichern (falls vorhanden)
        let imagePath = selectedImage.flatMap { viewModel.saveImage($0) }

        // Plattform erzeugen und hinzufügen
        let plattform = Plattform(name: name, image: imagePath)
        viewModel.profiles[profileIndex].plattformen.append(plattform)
        viewModel.activeProfile = viewModel.profiles[profileIndex]
        viewModel.saveProfiles()
        viewModel.objectWillChange.send()
    }
}

// PlattformDetailView: Zeigt alle Checklisten-Items einer Plattform mit Status und Bildfunktion
struct PlattformDetailView: View {
    @EnvironmentObject var viewModel: AppViewModel
    let plattform: Plattform

    @State private var selectedItemIndex: Int? = nil
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var navigationTargetIndex: Int? = nil

    var body: some View {
        List {
            // Hole aktuelle Plattform-Position im Modell (damit Änderungen auch gespeichert werden)
            if let profileIndex = viewModel.profiles.firstIndex(where: { $0.id == viewModel.activeProfile?.id }),
               let plattformIndex = viewModel.profiles[profileIndex].plattformen.firstIndex(where: { $0.id == plattform.id }) {

                // Für jedes Checklisten-Item eine Zeile
                ForEach(viewModel.profiles[profileIndex].plattformen[plattformIndex].items.indices, id: \.self) { index in
                    let binding = $viewModel.profiles[profileIndex].plattformen[plattformIndex].items[index]
                    let item = binding.wrappedValue

                    HStack(spacing: 12) {
                        // Status abhaken/entfernen
                        Button(action: {
                            binding.isCompleted.wrappedValue.toggle()
                            viewModel.saveProfiles()
                        }) {
                            Image(systemName: item.isCompleted ? "checkmark.square.fill" : "square")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(Color("KSBlue"))
                        }
                        .buttonStyle(BorderlessButtonStyle())

                        // Name des Checklisten-Items
                        Text(item.name)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()

                        // Buttons: Foto aufnehmen / Detailansicht
                        HStack {
                            // Kamera für das Item öffnen
                            Button(action: {
                                sourceType = .camera
                                selectedItemIndex = index
                                showImagePicker = true
                            }) {
                                Image(systemName: "camera")
                            }

                            // Info/Details öffnen
                            Button(action: {
                                navigationTargetIndex = index
                            }) {
                                Image(systemName: "info.circle")
                            }
                            .buttonStyle(BorderlessButtonStyle())

                            // NavigationLink für Detailansicht (versteckt)
                            NavigationLink(
                                destination: detailView(for: index),
                                tag: index,
                                selection: $navigationTargetIndex,
                                label: { EmptyView() }
                            )
                            .frame(width: 0)
                            .hidden()
                        }
                    }
                }
            }
        }
        .navigationTitle(plattform.name)
        // Vollbild-ImagePicker für das Hinzufügen eines Fotos
        .fullScreenCover(isPresented: $showImagePicker) {
            ImagePicker(sourceType: sourceType, selectedImage: $selectedImage, isPresented: $showImagePicker)
                .onDisappear {
                    // Nach Auswahl des Fotos dem Item hinzufügen
                    if let index = selectedItemIndex,
                       let image = selectedImage,
                       let profileIndex = viewModel.profiles.firstIndex(where: { $0.id == viewModel.activeProfile?.id }),
                       let plattformIndex = viewModel.profiles[profileIndex].plattformen.firstIndex(where: { $0.id == plattform.id }) {

                        viewModel.profiles[profileIndex].plattformen[plattformIndex].items[index].images.append(viewModel.saveImage(image) ?? "")
                        viewModel.saveProfiles()
                        selectedImage = nil
                    }
                }
        }
    }

    // Zeigt die Detailansicht für ein Plattform-ChecklistItem
    private func detailView(for index: Int) -> some View {
        if let profileIndex = viewModel.profiles.firstIndex(where: { $0.id == viewModel.activeProfile?.id }),
           let plattformIndex = viewModel.profiles[profileIndex].plattformen.firstIndex(where: { $0.id == plattform.id }) {
            let binding = $viewModel.profiles[profileIndex].plattformen[plattformIndex].items[index]

            // Nutzt die gleiche Detail-View wie reguläre Checklistenpunkte
            return AnyView(ChecklistItemDetailView(
                category: .init(name: plattform.name, subcategories: []),
                subcategory: .init(name: "", items: []),
                itemIndex: index,
                item: binding
            ).environmentObject(viewModel))
        }
        return AnyView(EmptyView())
    }
}

// Ansicht für den Datenexport (Checklisten & LOP)
struct ExportView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var exportType: ExportType = .checklist         // Auswahl des Export-Typs
    @State private var showingShareSheet = false                    // Steuert Anzeige des Share-Sheets
    @State private var exportURL: URL?                              // Pfad zur exportierten Datei
    @State private var isExporting = false                          // Zeigt Ladezustand während des Exports an
    
    var body: some View {
        Form {
            // Auswahl, ob Checklisten oder LOP exportiert werden sollen
            Section(header: Text("Export-Typ")) {
                Picker("Export-Typ", selection: $exportType) {
                    Text("Checklisten").tag(ExportType.checklist)
                    Text("LOP").tag(ExportType.lop)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Button zum Starten des Exports
            Section {
                Button(action: {
                    isExporting = true    // Ladeanzeige aktivieren
                    
                    // Simulierte Wartezeit (könnte bei echten langen Operationen notwendig sein)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        exportURL = viewModel.exportData(exportType: exportType) // Exportdaten erzeugen
                        isExporting = false // Ladeanzeige wieder deaktivieren
                        
                        // Falls Export erfolgreich, zeige Teilen-Dialog an
                        if exportURL != nil {
                            showingShareSheet = true
                        }
                    }
                }) {
                    HStack {
                        Text("Daten exportieren")
                        // Wenn Export läuft, Ladeanzeige
                        if isExporting {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                // Button ist deaktiviert, wenn Export läuft oder kein Profil gewählt ist
                .disabled(isExporting || viewModel.activeProfile == nil)
            }
            
            // Hinweistext zum Export
            Section(header: Text("Hinweis")) {
                Text("Der Export erstellt eine ZIP-Datei mit allen Daten und Bildern, die Sie teilen können.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Export")
        // Präsentiert das ShareSheet, wenn eine Export-Datei bereitsteht
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
    }
}

// Hilfs-View: System-ShareSheet für Datei-Export
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    // Erstellt einen UIActivityViewController (Teilen/Exportieren)
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    // Keine Updates nötig, Methode bleibt leer
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Ansicht für Einstellungen & Profilverwaltung
struct SettingsView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showResetAlert = false
    @State private var showCreateProfile = false
    @State private var profileToDelete: Profile?

    var body: some View {
        Form {
            // Profilverwaltung (Auflisten, Löschen, neues Profil)
            Section(header: Text("Profile")) {
                ForEach(viewModel.profiles) { profile in
                    HStack {
                        Text(profile.name)
                        Spacer()
                        Text(profile.mode.rawValue)
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Setzt aktives Profil
                        viewModel.setActiveProfile(profile)
                    }
                    .swipeActions(edge: .trailing) {
                        // Löschen-Button für Profile
                        Button(role: .destructive) {
                            profileToDelete = profile
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                    }
                    // Lösch-Bestätigung als Alert
                    .alert(item: $profileToDelete) { profile in
                        Alert(
                            title: Text("Profil löschen"),
                            message: Text("Möchten Sie das Profil \"\(profile.name)\" wirklich löschen? Alle zugehörigen Daten werden entfernt."),
                            primaryButton: .destructive(Text("Löschen")) {
                                viewModel.deleteProfile(profile)
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
                // Button für neues Profil
                Button(action: {
                    showCreateProfile = true
                }) {
                    Label("Neues Profil", systemImage: "plus")
                }
            }
            // App-Info
            Section(header: Text("App-Informationen"), footer: Text("© 2025 K&S")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Einstellungen")
        // Zeigt Eingabemaske für neues Profil
        .sheet(isPresented: $showCreateProfile) {
            CreateProfileView()
                .environmentObject(viewModel)
        }
    }
}

// Für die Vollbildanzeige und Zoom-Geste eines Bildes
struct FullScreenImageView: View {
    let image: UIImage
    @Binding var isPresented: Bool
    @State private var scale: CGFloat = 1.0

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .gesture(MagnificationGesture()
                    .onChanged { value in
                        scale = max(1.0, value)
                    }
                )
                .background(Color.black)
                .ignoresSafeArea()
            Button(action: { isPresented = false }) {
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            .padding([.top, .trailing], 30)
        }
    }
}

// Native UIKit-Suchleiste, eingebunden in SwiftUI
struct SearchBar: UIViewRepresentable {
    @Binding var text: String
    
    // Coordinator zur Verwaltung der Suchleiste
    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String
        
        init(text: Binding<String>) {
            _text = text
        }
        
        // Wird bei Texteingabe aufgerufen
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
        }
        
        // Schließt die Tastatur beim Suchen
        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text)
    }
    
    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar()
        searchBar.delegate = context.coordinator
        searchBar.placeholder = "Suchen..."
        searchBar.autocapitalizationType = .none
        searchBar.searchBarStyle = .minimal
        return searchBar
    }
    
    func updateUIView(_ uiView: UISearchBar, context: Context) {
        uiView.text = text
    }
}

// ImagePicker: Ermöglicht das Auswählen oder Aufnehmen eines Bildes
struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool

    // Coordinator verbindet UIKit mit SwiftUI
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        // Wird aufgerufen, wenn ein Bild ausgewählt wurde
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.isPresented = false
        }

        // Wird aufgerufen, wenn der Nutzer abbricht
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

// Preview für die Hauptansicht
#Preview {
    ContentView()
}
