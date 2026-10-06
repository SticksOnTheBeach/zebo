import SwiftUI

/// La fin de la configuration : seul Zebo quitte la fenêtre, file au centre de l'écran,
/// fait un clin d'œil (une étoile jaillit au coin de l'œil), puis rejoint la notch en faisant un salto.
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
    /// L'étoile du clin d'œil : 0 = cachée, 1 = posée, un peu plus = scintillement.
    @State private var starScale: CGFloat = 0
    @State private var starRotation: Angle = .degrees(-90)

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
            .overlay { star }
            .scaleEffect(x: 1 / squash, y: squash, anchor: .bottom)
            .rotationEffect(spin)
            .opacity(opacity)
            .position(x: frame.midX, y: frame.midY)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .task { await play() }
    }

    /// Une étoile à quatre branches au coin de l'œil qui cligne, avec un halo doré.
    private var star: some View {
        let side = frame.width * 0.26
        return Image(systemName: "sparkle")
            .resizable()
            .scaledToFit()
            .foregroundStyle(
                LinearGradient(
                    colors: [.white, Color(red: 1, green: 0.85, blue: 0.35)], startPoint: .top, endPoint: .bottom)
            )
            .shadow(color: Color(red: 1, green: 0.8, blue: 0.3).opacity(0.9), radius: side * 0.3)
            .frame(width: side, height: side)
            .scaleEffect(starScale)
            .rotationEffect(starRotation)
            .opacity(starScale > 0.05 ? 1 : 0)
            // Au coin de l'œil droit, au bord du nuage, pour bien se détacher.
            .offset(x: frame.width * 0.38, y: -frame.height * 0.2)
            .allowsHitTesting(false)
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

        // 2. Un clin d'œil, et une étoile jaillit au coin de l'œil…
        withAnimation(.easeOut(duration: 0.08)) { isWinking = true }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.45)) {
            starScale = 1
            starRotation = .zero
        }
        await pause(0.3)
        // …qui scintille une fois…
        withAnimation(.easeInOut(duration: 0.12)) { starScale = 1.25 }
        await pause(0.12)
        withAnimation(.easeInOut(duration: 0.12)) { starScale = 1 }
        await pause(0.15)
        // …puis s'éteint en tournant quand il rouvre l'œil.
        withAnimation(.easeIn(duration: 0.1)) { isWinking = false }
        withAnimation(.easeIn(duration: 0.25)) {
            starScale = 0
            starRotation = .degrees(90)
        }
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
