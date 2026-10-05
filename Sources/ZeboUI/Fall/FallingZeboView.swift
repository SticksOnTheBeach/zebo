import SwiftUI
import ZeboCore

/// Zebo éjecté de la notch, qui tombe en tournoyant à travers tout l'écran.
/// Vit dans une fenêtre plein écran transparente, affichée seulement pendant la chute.
public struct FallingZeboView: View {
    private let behavior: ZeboBehavior

    public init(behavior: ZeboBehavior) {
        self.behavior = behavior
    }

    public var body: some View {
        if let flight = behavior.flight {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSince(flight.start)
                let position = flight.position(at: t)

                ZeboCharacter(mood: .dizzy, dizzySpin: .degrees(t * 720))
                    .frame(width: flight.size, height: flight.size)
                    .rotationEffect(.degrees(flight.spinSpeed * t))
                    .opacity(flight.opacity(at: position.y))
                    .position(position)
            }
        }
    }
}
