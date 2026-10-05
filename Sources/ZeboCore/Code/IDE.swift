import Foundation

/// Un éditeur de code que Zebo sait retrouver sur le Mac.
public struct IDE: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    /// Identifiants de l'app (plusieurs pour les éditions, ex. IntelliJ Ultimate et Community).
    public let bundleIdentifiers: [String]
    /// Noms du `.app`, pour le chercher dans les dossiers d'applications.
    public let appNames: [String]

    public init(id: String, name: String, bundleIdentifiers: [String], appNames: [String]) {
        self.id = id
        self.name = name
        self.bundleIdentifiers = bundleIdentifiers
        self.appNames = appNames
    }

    /// Les éditeurs proposés pendant la configuration.
    public static let catalog: [IDE] = [
        IDE(
            id: "vscode", name: "VS Code", bundleIdentifiers: ["com.microsoft.VSCode"],
            appNames: ["Visual Studio Code.app"]),
        IDE(
            id: "cursor", name: "Cursor", bundleIdentifiers: ["com.todesktop.230313mzl4w4u92"],
            appNames: ["Cursor.app"]),
        IDE(
            id: "windsurf", name: "Windsurf", bundleIdentifiers: ["com.exafunction.windsurf"],
            appNames: ["Windsurf.app"]),
        IDE(id: "xcode", name: "Xcode", bundleIdentifiers: ["com.apple.dt.Xcode"], appNames: ["Xcode.app"]),
        IDE(id: "zed", name: "Zed", bundleIdentifiers: ["dev.zed.Zed"], appNames: ["Zed.app"]),
        IDE(
            id: "sublime", name: "Sublime Text",
            bundleIdentifiers: ["com.sublimetext.4", "com.sublimetext.3"], appNames: ["Sublime Text.app"]),
        IDE(
            id: "intellij", name: "IntelliJ IDEA",
            bundleIdentifiers: ["com.jetbrains.intellij", "com.jetbrains.intellij.ce"],
            appNames: ["IntelliJ IDEA.app", "IntelliJ IDEA CE.app", "IntelliJ IDEA Ultimate.app"]),
        IDE(
            id: "webstorm", name: "WebStorm", bundleIdentifiers: ["com.jetbrains.WebStorm"],
            appNames: ["WebStorm.app"]),
        IDE(
            id: "pycharm", name: "PyCharm",
            bundleIdentifiers: ["com.jetbrains.pycharm", "com.jetbrains.pycharm.ce"],
            appNames: ["PyCharm.app", "PyCharm CE.app", "PyCharm Professional Edition.app"]),
        IDE(
            id: "rustrover", name: "RustRover", bundleIdentifiers: ["com.jetbrains.rustrover"],
            appNames: ["RustRover.app"]),
        IDE(id: "clion", name: "CLion", bundleIdentifiers: ["com.jetbrains.CLion"], appNames: ["CLion.app"]),
        IDE(
            id: "androidstudio", name: "Android Studio", bundleIdentifiers: ["com.google.android.studio"],
            appNames: ["Android Studio.app"]),
    ]
}

/// L'éditeur choisi, et où il se trouve.
public struct IDEChoice: Codable, Equatable, Sendable {
    /// Identifiant du catalogue, ou `custom` pour une app choisie à la main.
    public var id: String
    public var name: String
    /// Chemin du `.app`.
    public var path: String

    public static let customID = "custom"

    public init(id: String, name: String, path: String) {
        self.id = id
        self.name = name
        self.path = path
    }
}

/// Retrouve une application installée sur le Mac.
public protocol ApplicationLocator: Sendable {
    func locate(_ ide: IDE) -> URL?
}

/// Ne trouve jamais rien : quand on ne cherche pas d'éditeur (tests, aperçus).
public struct NoApplicationLocator: ApplicationLocator {
    public init() {}
    public func locate(_ ide: IDE) -> URL? { nil }
}
