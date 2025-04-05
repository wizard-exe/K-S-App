import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: AppViewModel
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
        List {
            ForEach(viewModel.filteredChecklists) { category in
                Section(header: Text(category.name).font(.headline)) {
                    ForEach(category.subcategories) { subcategory in
                        NavigationLink(destination: ChecklistSubcategoryItemListView(category: category, subcategory: subcategory)) {
                            Text(subcategory.name)
                        }
                    }
                }
            }
        }
        .navigationTitle("Checkliste")
    }
}

extension Int: Identifiable {
    public var id: Int { self }
}

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
            if let profileIndex = viewModel.profiles.firstIndex(where: { $0.id == viewModel.activeProfile?.id }),
               let categoryIndex = viewModel.profiles[profileIndex].checklists.firstIndex(where: { $0.id == category.id }),
               let subcategoryIndex = viewModel.profiles[profileIndex].checklists[categoryIndex].subcategories.firstIndex(where: { $0.id == subcategory.id }) {

                ForEach(viewModel.profiles[profileIndex].checklists[categoryIndex].subcategories[subcategoryIndex].items.indices, id: \.self) { index in
                    let binding = $viewModel.profiles[profileIndex].checklists[categoryIndex].subcategories[subcategoryIndex].items[index]
                    let item = binding.wrappedValue

                    HStack(spacing: 12) {
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

                        Text(item.name)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)

                        Spacer()

                        HStack() {
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
        .fullScreenCover(isPresented: $showImagePicker) {
            ImagePicker(sourceType: sourceType, selectedImage: $selectedImage, isPresented: $showImagePicker)
                .onDisappear {
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

    func isTapInsideButtonArea() -> Bool {
        false
    }
}

private extension UIViewController {
    @objc func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
}

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
            Section(header: Text("Kommentar")) {
                TextEditor(text: $item.comment)
                    .frame(minHeight: 100)
                    .onChange(of: item.comment) { _ in
                        viewModel.saveProfiles()
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
                                                fullScreenImagePath = path
                                                showingFullScreenImage = true
                                            }

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
        .fullScreenCover(isPresented: $showImagePicker) {
            ImagePicker(sourceType: sourceType, selectedImage: $selectedImage, isPresented: $showImagePicker)
                .onDisappear {
                    DispatchQueue.main.async {
                        if let image = selectedImage,
                           let path = viewModel.saveImage(image) {
                            item.images.append(path)
                            viewModel.saveProfiles()
                            selectedImage = nil
                        }
                    }
                }
        }
        .fullScreenCover(isPresented: $showingFullScreenImage) {
            if let path = fullScreenImagePath,
               let uiImage = UIImage(contentsOfFile: path) {
                FullScreenImageView(image: uiImage, isPresented: $showingFullScreenImage)
            }
        }
    }
}

struct LOPView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showAddLOP = false
    @State private var lopItemToDelete: LOPItem?
    @State private var showDeleteConfirmation = false

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
                        }
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
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Abbrechen") {
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
    @State private var platformToDelete: Platform?
    @State private var showDeleteConfirmation = false

    var body: some View {
        ZStack(alignment: .bottom) {
            List {
                ForEach(viewModel.activeProfile?.platforms ?? []) { platform in
                    NavigationLink(destination: PlatformDetailView(platform: platform)) {
                        Text(platform.name)
                            .font(.headline)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            platformToDelete = platform
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

            Button(action: {
                showAddPlatform = true
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
        .sheet(isPresented: $showAddPlatform) {
            AddPlatformView()
                .environmentObject(viewModel)
        }
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("Plattform löschen"),
                message: Text("Möchtest du die Plattform wirklich löschen?"),
                primaryButton: .destructive(Text("Löschen")) {
                    if let platform = platformToDelete {
                        deletePlatform(platform)
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }

    private func deletePlatform(_ platform: Platform) {
        guard let profileIndex = viewModel.profiles.firstIndex(where: { $0.id == viewModel.activeProfile?.id }),
              let platformIndex = viewModel.profiles[profileIndex].platforms.firstIndex(where: { $0.id == platform.id }) else {
            return
        }

        if let imagePath = viewModel.profiles[profileIndex].platforms[platformIndex].image {
            viewModel.deleteImage(at: imagePath)
        }

        viewModel.profiles[profileIndex].platforms.remove(at: platformIndex)
        viewModel.saveProfiles()
    }
}

struct AddPlatformView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var name = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Name")) {
                    TextField("Plattform-Name", text: $name)
                }
            }
            .navigationTitle("Neue Plattform")
            .navigationBarItems(
                leading: Button("Abbrechen") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.white),
                trailing: Button("Speichern") {
                    addPlatform()
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.white)
                .disabled(name.isEmpty)
            )
        }
    }

    private func addPlatform() {
        guard let profile = viewModel.activeProfile,
              let profileIndex = viewModel.profiles.firstIndex(where: { $0.id == profile.id }) else { return }

        let imagePath = selectedImage.flatMap { viewModel.saveImage($0) }

        let platform = Platform(name: name, image: imagePath)
        viewModel.profiles[profileIndex].platforms.append(platform)
        viewModel.activeProfile = viewModel.profiles[profileIndex]
        viewModel.saveProfiles()
        viewModel.objectWillChange.send()
    }
}

struct PlatformDetailView: View {
    @EnvironmentObject var viewModel: AppViewModel
    let platform: Platform

    @State private var selectedItemIndex: Int? = nil
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var navigationTargetIndex: Int? = nil

    var body: some View {
        List {
            if let profileIndex = viewModel.profiles.firstIndex(where: { $0.id == viewModel.activeProfile?.id }),
               let platformIndex = viewModel.profiles[profileIndex].platforms.firstIndex(where: { $0.id == platform.id }) {

                ForEach(viewModel.profiles[profileIndex].platforms[platformIndex].items.indices, id: \.self) { index in
                    let binding = $viewModel.profiles[profileIndex].platforms[platformIndex].items[index]
                    let item = binding.wrappedValue

                    HStack(spacing: 12) {
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

                        Text(item.name)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()

                        HStack {
                            Button(action: {
                                sourceType = .camera
                                selectedItemIndex = index
                                showImagePicker = true
                            }) {
                                Image(systemName: "camera")
                            }

                            Button(action: {
                                navigationTargetIndex = index
                            }) {
                                Image(systemName: "info.circle")
                            }
                            .buttonStyle(BorderlessButtonStyle())

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
        .navigationTitle(platform.name)
        .fullScreenCover(isPresented: $showImagePicker) {
            ImagePicker(sourceType: sourceType, selectedImage: $selectedImage, isPresented: $showImagePicker)
                .onDisappear {
                    if let index = selectedItemIndex,
                       let image = selectedImage,
                       let profileIndex = viewModel.profiles.firstIndex(where: { $0.id == viewModel.activeProfile?.id }),
                       let platformIndex = viewModel.profiles[profileIndex].platforms.firstIndex(where: { $0.id == platform.id }) {

                        viewModel.profiles[profileIndex].platforms[platformIndex].items[index].images.append(viewModel.saveImage(image) ?? "")
                        viewModel.saveProfiles()
                        selectedImage = nil
                    }
                }
        }
    }

    private func detailView(for index: Int) -> some View {
        if let profileIndex = viewModel.profiles.firstIndex(where: { $0.id == viewModel.activeProfile?.id }),
           let platformIndex = viewModel.profiles[profileIndex].platforms.firstIndex(where: { $0.id == platform.id }) {
            let binding = $viewModel.profiles[profileIndex].platforms[platformIndex].items[index]

            return AnyView(ChecklistItemDetailView(
                category: .init(name: platform.name, subcategories: []),
                subcategory: .init(name: "", items: []),
                itemIndex: index,
                item: binding
            ).environmentObject(viewModel))
        }
        return AnyView(EmptyView())
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
}
