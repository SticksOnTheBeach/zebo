import SwiftUI

/// Zebo éjecté de la notch, qui tombe en tournoyant à travers tout l'écran.
/// Vit dans une fenêtre plein écran transparente, affichée seulement pendant la chute.
struct FallingZeboView: View {
    let behavior: ZeboBehavior

    var body: some View {
        if let flight = behavior.flight {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSince(flight.start)
                let position = flight.position(at: t)

                ZeboCharacter(dizzy: true, dizzySpin: .degrees(t * 720))
                    .frame(width: flight.size, height: flight.size)
                    .rotationEffect(.degrees(flight.spinSpeed * t))
                    .opacity(flight.opacity(at: position.y))
                    .position(position)
            }
        }
    }
}
