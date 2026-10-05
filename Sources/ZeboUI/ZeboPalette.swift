import SwiftUI

/// Couleurs de Zebo, partagées par toutes les vues.
enum ZeboPalette {
    /// Dégradé du nuage, du haut vers le bas.
    static let cloudTop = Color(red: 1.00, green: 0.91, blue: 0.95)
    static let cloudBottom = Color(red: 0.99, green: 0.78, blue: 0.87)
    /// Traits du visage et texte de la bulle.
    static let ink = Color(red: 0.24, green: 0.13, blue: 0.20)
    /// Bonnet de nuit : bleu nuit, revers et pompon blancs.
    static let nightcap = Color(red: 0.36, green: 0.45, blue: 0.90)
    static let nightcapTrim = Color.white
    /// Étoiles qui tournent quand il est sonné.
    static let star = Color(red: 1.0, green: 0.84, blue: 0.3)
}
