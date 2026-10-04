import SwiftUI

/// Zebo vivant : suit la souris du regard, penche la tête, cligne des yeux et se balance doucement.
struct AnimatedZebo: View {
    /// Position de la souris et centre de Zebo, en coordonnées écran (origine en bas à gauche).
    var mouse: CGPoint
    var center: CGPoint
    /// Notch ouverte : Zebo se balance. Fermée, il reste immobile pour économiser le CPU.
    var isAwake: Bool
    /// Chaque changement fait faire un petit saut à Zebo (quand il se met à parler).
    var hopTrigger: Int = 0
    /// Sonné : yeux en spirale, étoiles, et il titube.
    var isDizzy = false

    @State private var eyeOpenness: CGFloat = 1

    var body: some View {
        // 30 images/s suffisent pour un balancement aussi lent ; en pause quand la notch est fermée.
        // Sonné, les spirales et les étoiles ont besoin de toutes les images.
        TimelineView(.animation(minimumInterval: isDizzy ? nil : 1 / 30, paused: !(isAwake || isDizzy))) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZeboCharacter(look: isDizzy ? .zero : look,
                          eyeOpenness: isDizzy ? 1 : eyeOpenness,
                          headTilt: isDizzy ? .zero : headTilt,
                          dizzy: isDizzy,
                          dizzySpin: .degrees(t * 300))
                // Le regard rattrape la souris avec un petit ressort.
                .animation(.spring(response: 0.3, dampingFraction: 0.65), value: look)
                .rotationEffect(.degrees(isAwake && !isDizzy ? sway(at: timeline.date) : 0), anchor: .bottom)
                // Sonné, il gigote vite de gauche à droite (environ 6 fois par seconde).
                .rotationEffect(.degrees(isDizzy ? sin(t * 38) * 14 : 0), anchor: .bottom)
                .offset(x: isDizzy ? sin(t * 38) * 5 : 0)
        }
        // Petit saut : il gonfle, s'écrase un peu, puis revient.
        .phaseAnimator([1.0, 1.15, 0.94, 1.0], trigger: hopTrigger) { content, scale in
            content.scaleEffect(scale, anchor: .bottom)
        } animation: { _ in
            .spring(response: 0.16, dampingFraction: 0.6)
        }
        .task { await blinkForever() }
    }

    /// Balancement de ±2° avec une période de 5,6 s.
    private func sway(at date: Date) -> Double {
        sin(date.timeIntervalSinceReferenceDate * 2 * .pi / 5.6) * 2
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

    /// La tête penche vers le côté où se trouve la souris (10° max).
    private var headTilt: Angle {
        .degrees(max(-1, min(1, delta.dx / 500)) * 10)
    }

    private func blinkForever() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(.random(in: 2.5...6)))
            await blink()
            // De temps en temps, un double clignement.
            if Double.random(in: 0...1) < 0.2 {
                try? await Task.sleep(for: .milliseconds(140))
                await blink()
            }
        }
    }

    private func blink() async {
        withAnimation(.easeIn(duration: 0.07)) { eyeOpenness = 0 }
        try? await Task.sleep(for: .milliseconds(110))
        withAnimation(.easeOut(duration: 0.12)) { eyeOpenness = 1 }
    }
}
