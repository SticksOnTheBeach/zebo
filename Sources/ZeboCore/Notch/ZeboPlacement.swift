import CoreGraphics

/// Où se trouve Zebo à l'écran : de quoi calculer son éjection.
@MainActor
public protocol ZeboPlacement: AnyObject {
    /// Centre de Zebo, en coordonnées écran (origine en bas à gauche).
    var zeboScreenCenter: CGPoint { get }
    /// Place de Zebo dans la notch.
    var zeboFrame: CGRect { get }
    /// Écran qui porte la notch.
    var screenFrame: CGRect { get }
}

extension NotchModel: ZeboPlacement {}
