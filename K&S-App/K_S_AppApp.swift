import SwiftUI

// Haupt-Einstiegspunkt der App (SwiftUI Lifecycle)
@main
struct K_S_AppApp: App {
    // Das zentrale ViewModel wird als StateObject gehalten und für alle Unteransichten bereitgestellt
    @StateObject private var viewModel = AppViewModel()

    // Initialisierung für globale UI-Einstellungen (NavigationBar etc.)
    init() {
        // Konfiguration des Aussehens der Navigationsleiste (Farbe, Schrift etc.)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(named: "KSBlue") // Eigene App-Farbe für NavigationBar
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]      // Titel weiß
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white] // Großer Titel weiß
        
        // Eigenes Symbol für Zurück-Button, ebenfalls weiß
        let backImage = UIImage(systemName: "chevron.backward")?.withTintColor(.white, renderingMode: .alwaysOriginal)
        appearance.setBackIndicatorImage(backImage, transitionMaskImage: backImage)
        
        // Auch den Text im Zurück-Button weiß machen
        let backButtonAppearance = UIBarButtonItemAppearance()
        backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.backButtonAppearance = backButtonAppearance

        // Übernimmt das Erscheinungsbild für verschiedene Zustände der NavigationBar
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().compactScrollEdgeAppearance = appearance

        // Auch Icons/Titelfarbe von Buttons in der NavigationBar auf weiß setzen
        UINavigationBar.appearance().tintColor = .white
    }

    var body: some Scene {
        // Definiert das Hauptfenster der App und stellt das zentrale ViewModel zur Verfügung
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)     // ViewModel wird global verfügbar gemacht
                .preferredColorScheme(.light)     // App läuft nur im Light-Mode
        }
    }
}
