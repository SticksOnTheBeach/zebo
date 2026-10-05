import CoreGraphics

/// Mise en page de la fenêtre de configuration, partagée par l'animation de détachement
/// (qui doit arriver pile au même endroit) et par l'app (qui crée la vraie fenêtre).
public enum SetupWindowLayout {
    public static let size = CGSize(width: 640, height: 440)
    /// Arrondi des coins, proche de celui d'une fenêtre macOS.
    public static let cornerRadius: CGFloat = 16
    /// Place de Zebo, en haut à gauche, sous les boutons de la fenêtre (origine en haut à gauche).
    public static let zeboFrame = CGRect(x: 28, y: 44, width: 84, height: 84)
}
