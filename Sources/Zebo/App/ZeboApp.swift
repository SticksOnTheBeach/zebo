import SwiftUI

@main
struct ZeboApp: App {
    // AppKit gère la fenêtre de la notch, SwiftUI ne crée aucune fenêtre classique.
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}
