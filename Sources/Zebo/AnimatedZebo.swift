import SwiftUI

/// Zebo vivant : suit la souris du regard.
struct AnimatedZebo: View {
    /// Position de la souris et centre de Zebo, en coordonnées écran (origine en bas à gauche).
    var mouse: CGPoint
    var center: CGPoint

    var body: some View {
        ZeboCharacter(look: look)
            // Le regard rattrape la souris avec un petit ressort.
            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: look)
    }

    /// Écart souris − Zebo ; dy > 0 quand la souris est en dessous.
    private var delta: CGVector {
        CGVector(dx: mouse.x - center.x, dy: center.y - mouse.y)
    }

    /// Direction du regard : vers la souris, moins appuyée quand elle est tout près.
    private var look: CGPoint {
        let distance = hypot(delta.dx, delta.dy)
        guard distance > 1 else { return .zero }
        let strength = min(distance / 120, 1)
        return CGPoint(x: delta.dx / distance * strength,
                       y: delta.dy / distance * strength)
    }
}
