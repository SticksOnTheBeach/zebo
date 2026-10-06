import SwiftUI

/// La notch se détache et rejoint le centre de l'écran en devenant une fenêtre,
/// pendant que Zebo voyage jusqu'à sa place dans la fenêtre.
/// Vit dans une fenêtre plein écran transparente ; tous les cadres sont dans son repère
/// (origine en haut à gauche de l'écran).
public struct SetupTransitionView: View {
    private let notchFrame: CGRect
    private let windowFrame: CGRect
    private let zeboStart: CGRect
    private let zeboInWindow: CGRect
    private let onFinished: () -> Void

    /// 0 = la notch, 1 = la fenêtre.
    @State private var progress: CGFloat = 0

    /// - Parameters:
    ///   - notchFrame: la notch ouverte, au moment du clic.
    ///   - windowFrame: la fenêtre de configuration, au centre de l'écran.
    ///   - zeboStart: Zebo dans la notch.
    ///   - zeboInWindow: sa place dans la fenêtre (repère de la fenêtre).
    ///   - onFinished: appelé quand la fenêtre est arrivée.
    public init(
        notchFrame: CGRect, windowFrame: CGRect, zeboStart: CGRect, zeboInWindow: CGRect,
        onFinished: @escaping () -> Void
    ) {
        self.notchFrame = notchFrame
        self.windowFrame = windowFrame
        self.zeboStart = zeboStart
        self.zeboInWindow = zeboInWindow
        self.onFinished = onFinished
    }

    public var body: some View {
        let zebo = zeboFrame(at: progress)
        ZStack(alignment: .topLeading) {
            NotchToWindowShape(from: notchFrame, to: windowFrame, progress: progress)
                .fill(.black)
            ZeboCharacter()
                .frame(width: zebo.width, height: zebo.height)
                .position(x: zebo.midX, y: zebo.midY)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            // Un ressort un peu rebondi : la fenêtre « se pose » au centre.
            withAnimation(.spring(duration: 0.75, bounce: 0.18)) {
                progress = 1
            } completion: {
                onFinished()
            }
        }
    }

    /// Zebo glisse de sa place dans la notch à sa place dans la fenêtre.
    private func zeboFrame(at p: CGFloat) -> CGRect {
        let end = zeboInWindow.offsetBy(dx: windowFrame.minX, dy: windowFrame.minY)
        return CGRect(
            x: lerp(zeboStart.minX, end.minX, p), y: lerp(zeboStart.minY, end.minY, p),
            width: lerp(zeboStart.width, end.width, p), height: lerp(zeboStart.height, end.height, p))
    }
}
