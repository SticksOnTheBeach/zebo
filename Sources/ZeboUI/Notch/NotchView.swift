import AppKit
import SwiftUI
import ZeboCore

public struct NotchView: View {
    private let model: NotchModel
    private let speech: ZeboSpeech
    private let behavior: ZeboBehavior

    public init(model: NotchModel, speech: ZeboSpeech, behavior: ZeboBehavior) {
        self.model = model
        self.speech = speech
        self.behavior = behavior
    }

    private var size: CGSize { model.notchSize }
    private var zeboFrame: CGRect { model.zeboFrame }
    private var bottomRadius: CGFloat { model.isOpen ? 28 : 12 }

    public var body: some View {
        NotchShape(bottomRadius: bottomRadius)
            .fill(.black)
            .frame(width: size.width, height: size.height)
            .overlay(alignment: .topLeading) {
                ZStack(alignment: .topLeading) {
                    if model.isOpen {
                        openText
                            .transition(.opacity.combined(with: .offset(x: -12)))
                    }

                    // Un seul Zebo : il glisse et grandit de l'aile gauche jusqu'à sa place.
                    AnimatedZebo(
                        mouse: model.mouseLocation, center: model.zeboScreenCenter,
                        isAwake: model.isOpen, hopTrigger: speech.lineID,
                        mood: mood
                    )
                    .frame(width: zeboFrame.width, height: zeboFrame.height)
                    // Éjecté : il disparaît de la notch, puis revient avec un « pop ».
                    .scaleEffect(behavior.isHome ? 1 : 0.01)
                    .opacity(behavior.isHome ? 1 : 0)
                    // Il disparaît d'un coup, mais revient avec un rebond.
                    .animation(
                        behavior.isHome ? .spring(response: 0.5, dampingFraction: 0.55) : nil,
                        value: behavior.isHome
                    )
                    .contentShape(Rectangle())
                    // Un clic sur Zebo : il parle (et trop de clics l'assomment).
                    .onTapGesture { behavior.poke() }
                    .offset(x: zeboFrame.minX, y: zeboFrame.minY)
                }
            }
            .clipShape(NotchShape(bottomRadius: bottomRadius))
            .contextMenu {
                Button("Quitter Zebo") { NSApp.terminate(nil) }
            }
            // La fenêtre est plus grande que la notch : on colle le dessin en haut.
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    /// Sonné avant tout ; sinon, quand il parle, il prend un air pensif 🤔.
    private var mood: ZeboMood {
        if behavior.state == .dizzy { return .dizzy }
        return speech.line != nil ? .thinking : .calm
    }

    /// Texte provisoire à droite de Zebo : le chat viendra ici.
    private var openText: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Salut, moi c'est Zebo !")
                .font(.headline)
                .foregroundStyle(.white)
            Text("SOON... In progress…")
                .fontWidth(Font.Width.expanded)
                .fontWeight(Font.Weight.bold)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        // Le haut est caché par l'encoche physique : on démarre en dessous.
        .padding(.top, model.closedSize.height)
        .padding(.leading, 32 + 96 + 20)
    }
}
