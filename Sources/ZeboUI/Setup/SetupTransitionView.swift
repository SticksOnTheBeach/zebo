import SwiftUI

/// La notch se détache et rejoint le centre de l'écran en devenant une fenêtre,
/// pendant que Zebo voyage jusqu'à sa place en haut à gauche. À l'envers, la fenêtre
/// se rétracte dans la notch et Zebo retourne à sa place.
/// Vit dans une fenêtre plein écran transparente ; tous les cadres sont dans son repère
/// (origine en haut à gauche de l'écran).
public struct SetupTransitionView: View {
    private let notchFrame: CGRect
    private let windowFrame: CGRect
    private let zeboStart: CGRect
    private let notchBottomRadius: CGFloat
    private let isReversed: Bool
    private let onFinished: () -> Void

    /// 0 = la notch, 1 = la fenêtre.
    @State private var progress: CGFloat

    /// - Parameters:
    ///   - notchFrame: la notch ouverte, au moment du clic.
    ///   - windowFrame: la fenêtre de configuration, au centre de l'écran.
    ///   - zeboStart: Zebo dans la notch.
    ///   - notchBottomRadius: arrondi du bas de la notch (28 ouverte, 12 fermée).
    ///   - isReversed: de la fenêtre vers la notch.
    ///   - onFinished: appelé quand l'animation est finie.
    public init(
        notchFrame: CGRect, windowFrame: CGRect, zeboStart: CGRect, notchBottomRadius: CGFloat = 28,
        isReversed: Bool = false, onFinished: @escaping () -> Void
    ) {
        self.notchFrame = notchFrame
        self.windowFrame = windowFrame
        self.zeboStart = zeboStart
        self.notchBottomRadius = notchBottomRadius
        self.isReversed = isReversed
        self.onFinished = onFinished
        _progress = State(initialValue: isReversed ? 1 : 0)
    }

    public var body: some View {
        let zebo = zeboFrame(at: progress)
        ZStack(alignment: .topLeading) {
            NotchToWindowShape(
                from: notchFrame, to: windowFrame, progress: progress, notchBottomRadius: notchBottomRadius
            )
            .fill(.black)
            ZeboCharacter()
                .frame(width: zebo.width, height: zebo.height)
                .position(x: zebo.midX, y: zebo.midY)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            // Vers le centre, un ressort un peu rebondi : la fenêtre « se pose ».
            // Vers la notch, sans rebond : elle ne doit pas devenir plus petite que la notch.
            let animation: Animation =
                isReversed ? .spring(duration: 0.6, bounce: 0) : .spring(duration: 0.75, bounce: 0.18)
            withAnimation(animation) {
                progress = isReversed ? 0 : 1
            } completion: {
                onFinished()
            }
        }
    }

    /// Zebo glisse de sa place dans la notch à sa place dans la fenêtre : en grand au centre
    /// quand elle s'ouvre (l'accueil), en haut à gauche quand elle se referme (le récapitulatif).
    private func zeboFrame(at p: CGFloat) -> CGRect {
        let inWindow = isReversed ? SetupWindowLayout.zeboFrame : SetupWindowLayout.welcomeZeboFrame
        let end = inWindow.offsetBy(dx: windowFrame.minX, dy: windowFrame.minY)
        return CGRect(
            x: lerp(zeboStart.minX, end.minX, p), y: lerp(zeboStart.minY, end.minY, p),
            width: lerp(zeboStart.width, end.width, p), height: lerp(zeboStart.height, end.height, p))
    }
}
