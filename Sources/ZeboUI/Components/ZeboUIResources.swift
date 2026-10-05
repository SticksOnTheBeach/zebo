import Foundation

/// Les ressources du module (logos des langages…).
enum ZeboUIResources {
    /// Dans `Zebo.app`, elles sont rangées dans `Contents/Resources` ; ailleurs (tests, `swift run`),
    /// on se rabat sur l'emplacement prévu par SwiftPM.
    static let bundle: Bundle = {
        if let url = Bundle.main.url(forResource: "Zebo_ZeboUI", withExtension: "bundle"),
            let bundle = Bundle(url: url)
        {
            return bundle
        }
        return .module
    }()
}
