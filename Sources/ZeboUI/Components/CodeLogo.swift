import AppKit
import SwiftUI
import ZeboCore

/// Le vrai logo d'un langage ou d'un genre de projet (dessins vectoriels de Devicon, licence MIT).
struct CodeLogo: View {
    private let resourceName: String
    /// Logo noir, invisible sur fond sombre : on le dessine en blanc.
    private let isDark: Bool
    /// Si le logo manque : des initiales sur cette couleur.
    private let fallbackText: String
    private let fallbackColor: Color
    private let size: CGFloat

    init(language: Language, size: CGFloat = 38) {
        resourceName = language.rawValue
        isDark = language == .rust
        fallbackText = String(language.shortName.prefix(2))
        fallbackColor = language.color
        self.size = size
    }

    init(kind: ProjectKind, size: CGFloat = 38) {
        resourceName = kind.logoName
        isDark = kind == .rust
        fallbackText = String(kind.name.prefix(2))
        fallbackColor = .gray
        self.size = size
    }

    var body: some View {
        if let image = Self.image(named: resourceName, isTemplate: isDark) {
            Image(nsImage: image)
                .renderingMode(isDark ? .template : .original)
                .resizable()
                .scaledToFit()
                .foregroundStyle(.white)
                .frame(width: size, height: size)
        } else {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(fallbackColor.gradient)
                .frame(width: size, height: size)
                .overlay(
                    Text(fallbackText)
                        .font(.system(size: size * 0.36, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white))
        }
    }

    /// Les logos déjà chargés (ils resservent souvent : grilles, aperçu, notch).
    @MainActor private static var cache: [String: NSImage] = [:]

    @MainActor private static func image(named name: String, isTemplate: Bool) -> NSImage? {
        if let image = cache[name] { return image }
        guard
            let url = ZeboUIResources.bundle.url(forResource: name, withExtension: "svg", subdirectory: "Languages"),
            let image = NSImage(contentsOf: url)
        else { return nil }
        image.isTemplate = isTemplate
        cache[name] = image
        return image
    }
}
