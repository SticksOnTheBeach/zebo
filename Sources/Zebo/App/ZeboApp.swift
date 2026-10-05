import AppKit

/// Point d'entrée : une app AppKit sans fenêtre classique. Zebo vit dans la notch,
/// et n'a de fenêtre (et d'icône dans le Dock) que le temps de sa configuration.
@main
@MainActor
enum ZeboApp {
    /// Gardé ici : `NSApplication.delegate` n'est qu'une référence faible.
    private static let delegate = AppDelegate()

    static func main() {
        let app = NSApplication.shared
        app.delegate = delegate
        app.mainMenu = MainMenu.make()
        app.run()
    }
}
