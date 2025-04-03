import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()
    @State private var showMenu = false
    
    var body: some View {
        ZStack {
            NavigationView {
                Group {
                    if viewModel.profiles.isEmpty {
                        WelcomeView()
                            .environmentObject(viewModel)
                    } else if let profile = viewModel.activeProfile {
                        MainView(profile: profile)
                            .environmentObject(viewModel)
                    } else {
                        WelcomeView()
                            .environmentObject(viewModel)
                    }
                }
                .navigationBarTitle(viewModel.activeProfile?.name ?? "", displayMode: .inline)
                .navigationBarItems(
                    leading: Button(action: {
                        withAnimation {
                            showMenu.toggle()
                        }
                    }) {
                        Image(systemName: "line.horizontal.3")
                            .foregroundColor(Color(.white))
                    },
                    trailing: HStack {
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

            if showMenu {
                SidebarView(isShowing: $showMenu)
                    .environmentObject(viewModel)
                    .transition(.move(edge: .leading))
                    .zIndex(1)
            }
        }
    }
}

struct WelcomeView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showCreateProfile = false
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .frame(width: 200, height: 200)
                .background(Color.white)
            
            Text("Erstellen Sie ein Profil, um mit der technischen Dokumentation zu beginnen.")
                .font(.body)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
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
        .sheet(isPresented: $showCreateProfile) {
            CreateProfileView()
                .environmentObject(viewModel)
        }
    }
}

struct CreateProfileView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var profileName = ""
    @State private var selectedMode: AppMode = .wea
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profil-Informationen")) {
                    TextField("Profilname", text: $profileName)
                    
                    Picker("Modus", selection: $selectedMode) {
                        Text("Windenergieanlage").tag(AppMode.wea)
                        Text("Photovoltaik").tag(AppMode.pv)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .navigationBarTitle("Neues Profil", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Abbrechen") {
                    presentationMode.wrappedValue.dismiss()
                },
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

struct SidebarView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Binding var isShowing: Bool
    @State private var showCreateProfile = false
    @State private var profileToDelete: Profile?
    @State private var showDeleteConfirmation = false

    var body: some View {
        ZStack {
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
                                    
                                    Text(profile.mode.rawValue)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    if viewModel.activeProfile?.id == profile.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(Color("KSBlue"))
                                    }
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    profileToDelete = profile
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("Löschen", systemImage: "trash")
                                }
                            }
                        }
                        
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
                message: Text("Möchtest du das Profil „\(profileToDelete?.name ?? "")“ wirklich löschen?"),
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

struct MainView: View {
    @EnvironmentObject var viewModel: AppViewModel
    let profile: Profile
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ChecklistView()
                .tabItem {
                    Image(systemName: "checklist")
                    Text("Checkliste")
                }
                .tag(0)

            LOPView()
                .tabItem {
                    Image(systemName: "exclamationmark.circle")
                    Text("LOP")
                }
                .tag(1)

            if profile.mode == .wea {
                PlatformsView()
                    .tabItem {
                        Image(systemName: "square.stack.3d.up")
                        Text("Plattformen")
                    }
                    .tag(2)
            }

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

struct ChecklistView: View {
    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {
        VStack {
            SearchBar(text: $viewModel.searchQuery)
                .padding(.horizontal)

            List {
                ForEach(viewModel.filteredChecklists) { category in
                    Section(header: Text(category.name).font(.title3).fontWeight(.bold)) {
                        ForEach(category.subcategories) { subcategory in
                            NavigationLink(destination: ChecklistSubcategoryItemListView(
                                category: category,
                                subcategory: subcategory
                            )) {
                                Text(subcategory.name)
                                    .font(.headline)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Checkliste")
    }
}

struct ChecklistSubcategoryItemListView: View {
    @EnvironmentObject var viewModel: AppViewModel
    let category: ChecklistCategory
    let subcategory: ChecklistSubcategory

    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var currentItemIndexForImage: Int?
    @State private var navigateToDetailIndex: Int?

    var body: some View {
        List {
            Section(header: Text("Prüfbemerkungen").font(.headline)) {
                ForEach(subcategory.items.indices, id: \.self) { index in
                    let item = subcategory.items[index]

                    HStack {
                        // Checkbox
                        Button(action: {
                            toggleCompletion(for: index)
                        }) {
                            Image(systemName: item.isCompleted ? "checkmark.square" : "square")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(BorderlessButtonStyle())

                        // Item-Name
                        Text(item.name)
                            .lineLimit(1)

                        Spacer()

                        // LOP-Indikator
                        if item.isLOP {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                        }

                        // Kamera-Symbol
                        Button(action: {
                            currentItemIndexForImage = index
                            sourceType = .camera
                            showImagePicker = true
                        }) {
                            Image(systemName: "camera")
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(BorderlessButtonStyle())

                        // Info-Button
                        Button(action: {
                            navigateToDetailIndex = index
                        }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .contentShape(Rectangle())
                    .background(
                        NavigationLink(
                            destination: Group {
                                if let i = navigateToDetailIndex {
                                    ChecklistItemDetailView(
                                        category: category,
                                        subcategory: subcategory,
                                        itemIndex: i
                                    )
                                }
                            },
                            isActive: Binding(
                                get: { navigateToDetailIndex != nil },
                                set: { newValue in
                                    if !newValue {
                                        navigateToDetailIndex = nil
                                    }
                                }
                            )
                        ) {
                            EmptyView()
                        }
                        .hidden()
                    )
                }
            }
        }
        .navigationTitle(subcategory.name)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(
                sourceType: sourceType,
                selectedImage: $selectedImage,
                isPresented: $showImagePicker
            )
            .onDisappear {
                handleImagePickerDismiss()
            }
        }
    }

    private func handleImagePickerDismiss() {
        guard let index = currentItemIndexForImage,
              let image = selectedImage,
              let path = viewModel.saveImage(image),
              let profileIndex = viewModel.profiles.firstIndex(where: { $0.id == viewModel.activeProfile?.id }),
              let categoryIndex = viewModel.profiles[profileIndex].checklists.firstIndex(where: { $0.id == category.id }),
              let subcategoryIndex = viewModel.profiles[profileIndex].checklists[categoryIndex].subcategories.firstIndex(where: { $0.id == subcategory.id }) else {
            return
        }

        viewModel.profiles[profileIndex]
            .checklists[categoryIndex]
            .subcategories[subcategoryIndex]
            .items[index]
            .images.append(path)

        viewModel.saveProfiles()
        selectedImage = nil
    }

    private func toggleCompletion(for index: Int) {
        guard let profileIndex = viewModel.profiles.firstIndex(where: { $0.id == viewModel.activeProfile?.id }),
              let categoryIndex = viewModel.profiles[profileIndex].checklists.firstIndex(where: { $0.id == category.id }),
              let subcategoryIndex = viewModel.profiles[profileIndex].checklists[categoryIndex].subcategories.firstIndex(where: { $0.id == subcategory.id }) else {
            return
        }

        viewModel.profiles[profileIndex]
            .checklists[categoryIndex]
            .subcategories[subcategoryIndex]
            .items[index]
            .isCompleted.toggle()

        viewModel.saveProfiles()
    }
}


struct ChecklistItemDetailView: View {
    @EnvironmentObject var viewModel: AppViewModel
    let category: ChecklistCategory
    let subcategory: ChecklistSubcategory
    let itemIndex: Int

    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var selectedImage: UIImage?
    @State private var showFullScreenImage = false
    @State private var fullScreenImagePath: String?

    var item: Binding<ChecklistItem> {
        Binding<ChecklistItem>(
            get: {
                guard let profileIndex = viewModel.profiles.firstIndex(where: { $0.id == viewModel.activeProfile?.id }),
                      let categoryIndex = viewModel.profiles[profileIndex].checklists.firstIndex(where: { $0.id == category.id }),
                      let subcategoryIndex = viewModel.profiles[profileIndex].checklists[categoryIndex].subcategories.firstIndex(where: { $0.id == subcategory.id }),
                      itemIndex < viewModel.profiles[profileIndex].checklists[categoryIndex].subcategories[subcategoryIndex].items.count else {
                    return ChecklistItem(id: UUID(), name: "")
                }
                return viewModel.profiles[profileIndex].checklists[categoryIndex].subcategories[subcategoryIndex].items[itemIndex]
            },
            set: { newValue in
                guard let profileIndex = viewModel.profiles.firstIndex(where: { $0.id == viewModel.activeProfile?.id }),
                      let categoryIndex = viewModel.profiles[profileIndex].checklists.firstIndex(where: { $0.id == category.id }),
                      let subcategoryIndex = viewModel.profiles[profileIndex].checklists[categoryIndex].subcategories.firstIndex(where: { $0.id == subcategory.id }),
                      itemIndex < viewModel.profiles[profileIndex].checklists[categoryIndex].subcategories[subcategoryIndex].items.count else {
                    return
                }
                viewModel.profiles[profileIndex].checklists[categoryIndex].subcategories[subcategoryIndex].items[itemIndex] = newValue
                viewModel.saveProfiles()
            }
        )
    }

    var body: some View {
        Form {
            Section(header: Text("Status")) {
                Toggle("Offener Punkt (LOP)", isOn: Binding(
                    get: { item.wrappedValue.isLOP },
                    set: { newValue in
                        item.wrappedValue.isLOP = newValue
                        if newValue {
                            viewModel.addToLOP(item: item.wrappedValue)
                        } else {
                            // Entfernen aus LOP
                            if let profileIndex = viewModel.profiles.firstIndex(where: { $0.id == viewModel.activeProfile?.id }) {
                                viewModel.profiles[profileIndex].lopItems.removeAll { lopItem in
                                    lopItem.comment == item.wrappedValue.comment && lopItem.images == item.wrappedValue.images
                                }
                                viewModel.saveProfiles()
                            }
                        }
                    }
                ))
            }

            Section(header: Text("Kommentar")) {
                TextEditor(text: Binding(
                    get: { item.wrappedValue.comment },
                    set: { item.wrappedValue.comment = $0 }
                ))
                .frame(minHeight: 100)
            }

            Section(header: Text("Bilder")) {
                HStack {
                    Button(action: {
                        sourceType = .camera
                        showImagePicker = true
                    }) {
                        Label("Foto aufnehmen", systemImage: "camera")
                    }

                    Spacer()

                    Button(action: {
                        sourceType = .photoLibrary
                        showImagePicker = true
                    }) {
                        Label("Aus Galerie", systemImage: "photo.on.rectangle")
                    }
                }

                if !item.wrappedValue.images.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(item.wrappedValue.images, id: \.self) { imagePath in
                                if let uiImage = UIImage(contentsOfFile: imagePath) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .cornerRadius(8)
                                        .onTapGesture {
                                            fullScreenImagePath = imagePath
                                            showFullScreenImage = true
                                        }
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                viewModel.deleteImage(at: imagePath)
                                                if let index = item.wrappedValue.images.firstIndex(of: imagePath) {
                                                    item.wrappedValue.images.remove(at: index)
                                                }
                                            } label: {
                                                Label("Löschen", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(item.wrappedValue.name)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: sourceType, selectedImage: $selectedImage, isPresented: $showImagePicker)
                .onDisappear {
                    if let image = selectedImage, let path = viewModel.saveImage(image) {
                        item.wrappedValue.images.append(path)
                        selectedImage = nil
                    }
                }
        }
        .fullScreenCover(isPresented: $showFullScreenImage) {
            if let path = fullScreenImagePath, let uiImage = UIImage(contentsOfFile: path) {
                FullScreenImageView(image: uiImage, isPresented: $showFullScreenImage)
            }
        }
    }
}


struct LOPView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showAddLOP = false

    var body: some View {
        ZStack(alignment: .bottom) {
            List {
                ForEach(viewModel.activeProfile?.lopItems ?? []) { lopItem in
                    NavigationLink(destination: LOPItemDetailView(lopItem: lopItem)) {
                        VStack(alignment: .leading) {
                            Text(lopItem.title)
                                .font(.headline)

                            if !lopItem.comment.isEmpty {
                                Text(lopItem.comment)
                                    .font(.subheadline)
                                    .lineLimit(2)
                            }

                            if !lopItem.images.isEmpty {
                                HStack {
                                    Image(systemName: "photo")
                                    Text("\(lopItem.images.count)")
                                }
                                .font(.caption)
                                .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .onDelete { indexSet in
                    guard let lopItems = viewModel.activeProfile?.lopItems else { return }

                    for index in indexSet {
                        for imagePath in lopItems[index].images {
                            viewModel.deleteImage(at: imagePath)
                        }
                    }

                    guard let profileIndex = viewModel.profiles.firstIndex(where: { $0.id == viewModel.activeProfile?.id }) else { return }
                    viewModel.profiles[profileIndex].lopItems.remove(atOffsets: indexSet)
                    viewModel.saveProfiles()
                }
            }
            .padding(.bottom, 70) // Platz für Button lassen
            .navigationTitle("LOP")

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
    }
}


struct AddLOPItemView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var comment = ""
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var selectedImage: UIImage?
    @State private var imagePaths: [String] = []
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Kommentar")) {
                    TextEditor(text: $comment)
                        .frame(minHeight: 100)
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
                    }
                    
                    if !imagePaths.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(imagePaths, id: \.self) { path in
                                    if let uiImage = UIImage(contentsOfFile: path) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .cornerRadius(8)
                                            .contextMenu {
                                                Button(role: .destructive) {
                                                    viewModel.deleteImage(at: path)
                                                    if let index = imagePaths.firstIndex(of: path) {
                                                        imagePaths.remove(at: index)
                                                    }
                                                } label: {
                                                    Label("Löschen", systemImage: "trash")
                                                }
                                            }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Neuer LOP-Eintrag")
                        .navigationBarItems(
                            leading: Button("Abbrechen") {
                                for path in imagePaths {
                                    viewModel.deleteImage(at: path)
                                }
                                presentationMode.wrappedValue.dismiss()
                            },
                            trailing: Button("Speichern") {
                                guard let profile = viewModel.activeProfile else { return }
                                
                                let lopNumber = profile.lopItems.count + 1
                                let lopItem = LOPItem(
                                    title: "LOP-\(lopNumber)",
                                    comment: comment,
                                    images: imagePaths
                                )
                                
                                guard let profileIndex = viewModel.profiles.firstIndex(where: { $0.id == profile.id }) else { return }
                                viewModel.profiles[profileIndex].lopItems.append(lopItem)
                                viewModel.saveProfiles()
                                
                                presentationMode.wrappedValue.dismiss()
                            }
                            .disabled(comment.isEmpty)
                        )
                    }
                    .sheet(isPresented: $showImagePicker) {
                        ImagePicker(sourceType: sourceType, selectedImage: $selectedImage, isPresented: $showImagePicker)
                            .onDisappear {
                                if let image = selectedImage, let path = viewModel.saveImage(image) {
                                    imagePaths.append(path)
                                    selectedImage = nil
                                }
                            }
                    }
                }
            }

struct LOPItemDetailView: View {
    @EnvironmentObject var viewModel: AppViewModel
    let lopItem: LOPItem
    
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var selectedImage: UIImage?
    @State private var showingFullScreenImage = false
    @State private var fullScreenImagePath: String?
    @State private var comment: String
    @State private var imagePaths: [String]
    
    init(lopItem: LOPItem) {
        self.lopItem = lopItem
        _comment = State(initialValue: lopItem.comment)
        _imagePaths = State(initialValue: lopItem.images)
    }
    
    var body: some View {
        Form {
            Section(header: Text("Kommentar")) {
                TextEditor(text: $comment)
                    .frame(minHeight: 100)
                    .onChange(of: comment) { newValue in
                        updateLOPItem()
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
                }
                
                if !imagePaths.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(imagePaths, id: \.self) { path in
                                if let uiImage = UIImage(contentsOfFile: path) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .cornerRadius(8)
                                        .onTapGesture {
                                            fullScreenImagePath = path
                                            showingFullScreenImage = true
                                        }
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                viewModel.deleteImage(at: path)
                                                if let index = imagePaths.firstIndex(of: path) {
                                                    imagePaths.remove(at: index)
                                                    updateLOPItem()
                                                }
                                            } label: {
                                                Label("Löschen", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(lopItem.title)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: sourceType, selectedImage: $selectedImage, isPresented: $showImagePicker)
                .onDisappear {
                    if let image = selectedImage, let path = viewModel.saveImage(image) {
                        imagePaths.append(path)
                        updateLOPItem()
                        selectedImage = nil
                    }
                }
        }
        .fullScreenCover(isPresented: $showingFullScreenImage) {
            if let path = fullScreenImagePath, let uiImage = UIImage(contentsOfFile: path) {
                FullScreenImageView(image: uiImage, isPresented: $showingFullScreenImage)
            }
        }
    }
    
    private func updateLOPItem() {
        guard let profileIndex = viewModel.profiles.firstIndex(where: { $0.id == viewModel.activeProfile?.id }),
              let lopIndex = viewModel.profiles[profileIndex].lopItems.firstIndex(where: { $0.id == lopItem.id }) else {
            return
        }
        
        viewModel.profiles[profileIndex].lopItems[lopIndex].comment = comment
        viewModel.profiles[profileIndex].lopItems[lopIndex].images = imagePaths
        viewModel.saveProfiles()
    }
}

struct PlatformsView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showAddPlatform = false
    
    var body: some View {
        List {
            ForEach(viewModel.activeProfile?.platforms ?? []) { platform in
                NavigationLink(destination: PlatformDetailView(platform: platform)) {
                    HStack {
                        if let imagePath = platform.image, let uiImage = UIImage(contentsOfFile: imagePath) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .cornerRadius(8)
                        } else {
                            Image(systemName: "square.stack.3d.up")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .padding(15)
                                .foregroundColor(Color("KSBlue"))
                        }
                        
                        VStack(alignment: .leading) {
                            Text(platform.name)
                                .font(.headline)
                            
                            // Feature status summary
                            HStack {
                                FeatureIndicator(isActive: platform.bolts.isActive, label: "Bolzen")
                                FeatureIndicator(isActive: platform.lighting.isActive, label: "Beleuchtung")
                                FeatureIndicator(isActive: platform.safetyMeasures.isActive, label: "Sicherheit")
                            }
                        }
                    }
                }
            }
            .onDelete { indexSet in
                guard let profileIndex = viewModel.profiles.firstIndex(where: { $0.id == viewModel.activeProfile?.id }) else { return }
                
                for index in indexSet {
                    // Delete platform image
                    if let imagePath = viewModel.profiles[profileIndex].platforms[index].image {
                        viewModel.deleteImage(at: imagePath)
                    }
                }
                
                viewModel.profiles[profileIndex].platforms.remove(atOffsets: indexSet)
                viewModel.saveProfiles()
            }
        }
        .navigationTitle("Plattformen")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showAddPlatform = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddPlatform) {
            AddPlatformView()
                .environmentObject(viewModel)
        }
    }
}

struct FeatureIndicator: View {
    let isActive: Bool
    let label: String
    
    var body: some View {
        HStack(spacing: 2) {
            Circle()
                .fill(isActive ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.trailing, 4)
    }
}

struct AddPlatformView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var platformName = ""
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var selectedImage: UIImage?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Name")) {
                    TextField("Plattformname", text: $platformName)
                }
                
                Section(header: Text("Bild")) {
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
                    }
                    
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(8)
                    }
                }
            }
            .navigationTitle("Neue Plattform")
            .navigationBarItems(
                leading: Button("Abbrechen") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Hinzufügen") {
                    viewModel.addPlatform(name: platformName, image: selectedImage)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(platformName.isEmpty)
            )
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: sourceType, selectedImage: $selectedImage, isPresented: $showImagePicker)
        }
    }
}

struct PlatformDetailView: View {
    @EnvironmentObject var viewModel: AppViewModel
    let platform: Platform
    
    @State private var platformName: String
    @State private var boltsActive: Bool
    @State private var boltsComment: String
    @State private var lightingActive: Bool
    @State private var lightingComment: String
    @State private var cableFasteningActive: Bool
    @State private var cableFasteningComment: String
    @State private var markingsActive: Bool
    @State private var markingsComment: String
    @State private var safetyMeasuresActive: Bool
    @State private var safetyMeasuresComment: String
    @State private var obstacleBeaconActive: Bool
    @State private var obstacleBeaconComment: String
    
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var selectedImage: UIImage?
    @State private var showingFullScreenImage = false
    
    init(platform: Platform) {
        self.platform = platform
        _platformName = State(initialValue: platform.name)
        _boltsActive = State(initialValue: platform.bolts.isActive)
        _boltsComment = State(initialValue: platform.bolts.comment)
        _lightingActive = State(initialValue: platform.lighting.isActive)
        _lightingComment = State(initialValue: platform.lighting.comment)
        _cableFasteningActive = State(initialValue: platform.cableFastening.isActive)
        _cableFasteningComment = State(initialValue: platform.cableFastening.comment)
        _markingsActive = State(initialValue: platform.markings.isActive)
        _markingsComment = State(initialValue: platform.markings.comment)
        _safetyMeasuresActive = State(initialValue: platform.safetyMeasures.isActive)
        _safetyMeasuresComment = State(initialValue: platform.safetyMeasures.comment)
        _obstacleBeaconActive = State(initialValue: platform.obstacleBeacon.isActive)
        _obstacleBeaconComment = State(initialValue: platform.obstacleBeacon.comment)
    }
    
    var body: some View {
        Form {
            Section(header: Text("Name")) {
                TextField("Plattformname", text: $platformName)
                    .onChange(of: platformName) { _ in updatePlatform() }
            }
            
            Section(header: Text("Bild")) {
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
                }
                
                if let imagePath = platform.image, let uiImage = UIImage(contentsOfFile: imagePath) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(8)
                        .onTapGesture {
                            showingFullScreenImage = true
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                guard let profileIndex = viewModel.profiles.firstIndex(where: { $0.id == viewModel.activeProfile?.id }),
                                      let platformIndex = viewModel.profiles[profileIndex].platforms.firstIndex(where: { $0.id == platform.id }) else {
                                    return
                                }
                                
                                if let imagePath = viewModel.profiles[profileIndex].platforms[platformIndex].image {
                                    viewModel.deleteImage(at: imagePath)
                                    viewModel.profiles[profileIndex].platforms[platformIndex].image = nil
                                    viewModel.saveProfiles()
                                }
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                }
            }
            
            FeatureSection(title: "Bolzen", isActive: $boltsActive, comment: $boltsComment) {
                updatePlatform()
            }
            
            FeatureSection(title: "Beleuchtung", isActive: $lightingActive, comment: $lightingComment) {
                updatePlatform()
            }
            
            FeatureSection(title: "Kabelbefestigung", isActive: $cableFasteningActive, comment: $cableFasteningComment) {
                updatePlatform()
            }
            
            FeatureSection(title: "Markierungen", isActive: $markingsActive, comment: $markingsComment) {
                updatePlatform()
            }
            
            FeatureSection(title: "Sicherheitsmaßnahmen", isActive: $safetyMeasuresActive, comment: $safetyMeasuresComment) {
                updatePlatform()
            }
            
            FeatureSection(title: "Hindernisbefeuerung", isActive: $obstacleBeaconActive, comment: $obstacleBeaconComment) {
                updatePlatform()
            }
        }
        .navigationTitle(platform.name)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: sourceType, selectedImage: $selectedImage, isPresented: $showImagePicker)
                .onDisappear {
                    if let image = selectedImage {
                        updatePlatformImage(image)
                        selectedImage = nil
                    }
                }
        }
        .fullScreenCover(isPresented: $showingFullScreenImage) {
            if let imagePath = platform.image, let uiImage = UIImage(contentsOfFile: imagePath) {
                FullScreenImageView(image: uiImage, isPresented: $showingFullScreenImage)
            }
        }
    }
    
    private func updatePlatform() {
        guard let profileIndex = viewModel.profiles.firstIndex(where: { $0.id == viewModel.activeProfile?.id }),
              let platformIndex = viewModel.profiles[profileIndex].platforms.firstIndex(where: { $0.id == platform.id }) else {
            return
        }
        
        viewModel.profiles[profileIndex].platforms[platformIndex].name = platformName
        viewModel.profiles[profileIndex].platforms[platformIndex].bolts = FeatureStatus(isActive: boltsActive, comment: boltsComment)
        viewModel.profiles[profileIndex].platforms[platformIndex].lighting = FeatureStatus(isActive: lightingActive, comment: lightingComment)
        viewModel.profiles[profileIndex].platforms[platformIndex].cableFastening = FeatureStatus(isActive: cableFasteningActive, comment: cableFasteningComment)
        viewModel.profiles[profileIndex].platforms[platformIndex].markings = FeatureStatus(isActive: markingsActive, comment: markingsComment)
        viewModel.profiles[profileIndex].platforms[platformIndex].safetyMeasures = FeatureStatus(isActive: safetyMeasuresActive, comment: safetyMeasuresComment)
        viewModel.profiles[profileIndex].platforms[platformIndex].obstacleBeacon = FeatureStatus(isActive: obstacleBeaconActive, comment: obstacleBeaconComment)
        
        viewModel.saveProfiles()
    }
    
    private func updatePlatformImage(_ image: UIImage) {
        guard let profileIndex = viewModel.profiles.firstIndex(where: { $0.id == viewModel.activeProfile?.id }),
              let platformIndex = viewModel.profiles[profileIndex].platforms.firstIndex(where: { $0.id == platform.id }) else {
            return
        }
        
        // Delete old image if it exists
        if let imagePath = viewModel.profiles[profileIndex].platforms[platformIndex].image {
            viewModel.deleteImage(at: imagePath)
        }
        
        // Save new image
        if let path = viewModel.saveImage(image) {
            viewModel.profiles[profileIndex].platforms[platformIndex].image = path
            viewModel.saveProfiles()
        }
    }
}

struct FeatureSection: View {
    let title: String
    @Binding var isActive: Bool
    @Binding var comment: String
    let onUpdate: () -> Void
    
    var body: some View {
        Section(header: Text(title)) {
            Toggle("Aktiviert", isOn: $isActive)
                .onChange(of: isActive) { _ in onUpdate() }
            
            if isActive {
                TextEditor(text: $comment)
                    .frame(minHeight: 80)
                    .onChange(of: comment) { _ in onUpdate() }
            }
        }
    }
}

struct ExportView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var exportType: ExportType = .checklist
    @State private var showingShareSheet = false
    @State private var exportURL: URL?
    @State private var isExporting = false
    
    var body: some View {
        Form {
            Section(header: Text("Export-Typ")) {
                Picker("Export-Typ", selection: $exportType) {
                    Text("Checklisten").tag(ExportType.checklist)
                    Text("LOP").tag(ExportType.lop)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            Section {
                Button(action: {
                    isExporting = true
                    
                    // Simulate export process (in a real app, this would be the actual export)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        exportURL = viewModel.exportData(exportType: exportType)
                        isExporting = false
                        
                        if exportURL != nil {
                            showingShareSheet = true
                        }
                    }
                }) {
                    HStack {
                        Text("Daten exportieren")
                        
                        if isExporting {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(isExporting || viewModel.activeProfile == nil)
            }
            
            Section(header: Text("Hinweis")) {
                Text("Der Export erstellt eine ZIP-Datei mit allen Daten und Bildern, die Sie teilen können.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Export")
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct SettingsView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showResetAlert = false
    @State private var showCreateProfile = false
    @State private var profileToDelete: Profile?

    var body: some View {
        Form {
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
                        viewModel.setActiveProfile(profile)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            profileToDelete = profile
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                    }
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

                Button(action: {
                    showCreateProfile = true
                }) {
                    Label("Neues Profil", systemImage: "plus")
                }
            }

            Section {
                Button(action: {
                    showResetAlert = true
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundColor(.red)
                        Text("Aktives Profil zurücksetzen")
                            .foregroundColor(.red)
                    }
                }
            }

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
        .alert(isPresented: $showResetAlert) {
            Alert(
                title: Text("Profil zurücksetzen"),
                message: Text("Möchten Sie das aktive Profil wirklich zurücksetzen? Alle Daten werden gelöscht."),
                primaryButton: .destructive(Text("Zurücksetzen")) {
                    viewModel.resetActiveProfile()
                },
                secondaryButton: .cancel()
            )
        }
        .sheet(isPresented: $showCreateProfile) {
            CreateProfileView()
                .environmentObject(viewModel)
        }
    }
}

struct FullScreenImageView: View {
    let image: UIImage
    @Binding var isPresented: Bool
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = value
                        }
                        .onEnded { _ in
                            withAnimation {
                                scale = 1.0
                            }
                        }
                )
                .onTapGesture(count: 2) {
                    withAnimation {
                        scale = scale == 1.0 ? 2.0 : 1.0
                    }
                }
        }
        .overlay(
            Button(action: {
                isPresented = false
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .padding(),
            alignment: .topTrailing
        )
    }
}

struct SearchBar: UIViewRepresentable {
    @Binding var text: String
    
    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String
        
        init(text: Binding<String>) {
            _text = text
        }
        
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
        }
        
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

struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.isPresented = false
        }

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

#Preview {
    ContentView()
        .environmentObject(AppViewModel())
}
