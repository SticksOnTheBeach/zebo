import SwiftUI
import ZeboCore

/// Une initiative de Zebo, dans une petite fenêtre qui descend de la notch : ce qu'il propose de faire,
/// et deux boutons, Refuser (N) et Accepter (Y). On clique, ou on maintient la touche.
public struct InitiativeView: View {
    /// La taille de la fenêtre : la carte, et un peu de place pour son ombre.
    public static let windowSize = CGSize(width: 460, height: 132)

    private let initiatives: ZeboInitiatives

    public init(initiatives: ZeboInitiatives) {
        self.initiatives = initiatives
    }

    public var body: some View {
        ZStack(alignment: .top) {
            if let proposal = initiatives.current {
                card(proposal)
                    .id(proposal.id)
                    // Elle sort de sous la notch, comme si la notch la laissait tomber.
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .scale(scale: 0.92, anchor: .top).combined(with: .opacity)))
            }
        }
        .frame(width: Self.windowSize.width, height: Self.windowSize.height, alignment: .top)
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: initiatives.current)
    }

    private func card(_ proposal: ZeboInitiatives.Proposal) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Il prend une liberté : un clin d'œil.
                ZeboCharacter(isWinking: true)
                    .frame(width: 34, height: 34)
                VStack(alignment: .leading, spacing: 3) {
                    Text("ZEBO PROPOSE")
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(ZeboPalette.cloudBottom)
                    Text(proposal.text)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                Text("Maintiens Y ou N")
                    .font(.system(size: 10.5, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
                Spacer()
                HoldToConfirmButton(
                    title: "Refuser", key: "N", isHeld: initiatives.held == .refuse,
                    holdDuration: initiatives.holdDuration
                ) { initiatives.choose(.refuse) }
                HoldToConfirmButton(
                    title: "Accepter", key: "Y", isHeld: initiatives.held == .accept,
                    holdDuration: initiatives.holdDuration, isProminent: true
                ) { initiatives.choose(.accept) }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.black))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(.white.opacity(0.1)))
        .shadow(color: .black.opacity(0.35), radius: 10, y: 4)
        .padding(.horizontal, 12)
        .padding(.top, 6)
    }
}
