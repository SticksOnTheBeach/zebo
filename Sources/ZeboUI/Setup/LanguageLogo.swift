import AppKit
import SwiftUI
import ZeboCore

/// Le vrai logo d'un langage (dessins vectoriels de Devicon, licence MIT).
struct LanguageLogo: View {
    let language: Language
    var size: CGFloat = 38

    var body: some View {
        if let image = Self.image(for: language) {
            Image(nsImage: image)
                .renderingMode(language.hasDarkLogo ? .template : .original)
                .resizable()
                .scaledToFit()
                .foregroundStyle(.white)
                .frame(width: size, height: size)
        } else {
            // Logo introuvable : ses initiales, à sa couleur.
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(language.color.gradient)
                .frame(width: size, height: size)
                .overlay(
                    Text(language.shortName.prefix(2))
                        .font(.system(size: size * 0.36, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white))
        }
    }

    /// Les logos déjà chargés (ils resservent souvent : grille, aperçu, notch).
    @MainActor private static var cache: [Language: NSImage] = [:]

    @MainActor private static func image(for language: Language) -> NSImage? {
        if let image = cache[language] { return image }
        guard
            let url = ZeboUIResources.bundle.url(
                forResource: language.rawValue, withExtension: "svg", subdirectory: "Languages"),
            let image = NSImage(contentsOf: url)
        else { return nil }
        image.isTemplate = language.hasDarkLogo
        cache[language] = image
        return image
    }
}

extension Language {
    /// Logo noir, invisible sur fond noir : on le dessine en blanc.
    var hasDarkLogo: Bool { self == .rust }
}
