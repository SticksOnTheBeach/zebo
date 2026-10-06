import SwiftUI

/// La fin de la configuration : seul Zebo quitte la fenêtre, file au centre de l'écran,
/// fait un clin d'œil, puis rejoint la notch en faisant un salto.
/// Vit dans une fenêtre plein écran transparente ; tous les cadres sont dans son repère
/// (origine en haut à gauche de l'écran).
public struct SetupFinaleView: View {
    private let start: CGRect
    private let end: CGRect
    private let screenSize: CGSize
    private let onFinished: () -> Void

    @State private var frame: CGRect
    @State private var isWinking = false
    @State private var spin: Angle = .zero
    @State private var squash: CGFloat = 1
    @State private var opacity: Double = 1

    /// Taille de Zebo au centre de l'écran.
    private static let centerSide: CGFloat = 170

    /// - Parameters:
    ///   - start: Zebo dans la fenêtre de configuration.
    ///   - end: sa place dans la notch fermée.
    ///   - screenSize: taille de l'écran, pour trouver son centre.
    ///   - onFinished: appelé quand Zebo est arrivé dans la notch.
    public init(start: CGRect, end: CGRect, screenSize: CGSize, onFinished: @escaping () -> Void) {
        self.start = start
        self.end = end
        self.screenSize = screenSize
        self.onFinished = onFinished
        _frame = State(initialValue: start)
    }

    public var body: some View {
        ZeboCharacter(isWinking: isWinking)
            .frame(width: frame.width, height: frame.height)
            .scaleEffect(x: 1 / squash, y: squash, anchor: .bottom)
            .rotationEffect(spin)
            .opacity(opacity)
            .position(x: frame.midX, y: frame.midY)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .task { await play() }
    }

    private var center: CGRect {
        CGRect(
            x: (screenSize.width - Self.centerSide) / 2, y: (screenSize.height - Self.centerSide) / 2,
            width: Self.centerSide, height: Self.centerSide)
    }

    private func play() async {
        // 1. Il quitte la fenêtre et file au centre de l'écran.
        withAnimation(.spring(duration: 0.7, bounce: 0.25)) { frame = center }
        await pause(0.85)

        // 2. Un clin d'œil.
        withAnimation(.easeOut(duration: 0.08)) { isWinking = true }
        await pause(0.5)
        withAnimation(.easeIn(duration: 0.1)) { isWinking = false }
        await pause(0.25)

        // 3. Il prend son élan…
        withAnimation(.easeOut(duration: 0.15)) { squash = 0.85 }
        await pause(0.15)

        // 4. …et rejoint la notch en faisant un salto.
        withAnimation(.easeInOut(duration: 0.8)) {
            squash = 1
            spin = .degrees(-360)
            frame = end
        }
        await pause(0.65)
        withAnimation(.easeIn(duration: 0.15)) { opacity = 0 }
        await pause(0.15)
        onFinished()
    }

    private func pause(_ seconds: Double) async {
        try? await Task.sleep(for: .seconds(seconds))
    }
}
