import CoreGraphics

/// Mise en page de la fenêtre de configuration, partagée par l'animation de détachement
/// (qui doit arriver pile au même endroit) et par l'app (qui crée la vraie fenêtre).
public enum SetupWindowLayout {
    public static let size = CGSize(width: 720, height: 560)
    /// Arrondi des coins, proche de celui d'une fenêtre macOS.
    public static let cornerRadius: CGFloat = 16
    /// Place de Zebo, en haut à gauche, sous les boutons de la fenêtre (origine en haut à gauche).
    public static let zeboFrame = CGRect(x: 28, y: 44, width: 84, height: 84)
    /// Sur l'accueil, Zebo est en grand, au centre : c'est là que la fenêtre s'ouvre.
    public static let welcomeZeboFrame = CGRect(x: (size.width - 140) / 2, y: 40, width: 140, height: 140)
}
