import AppKit
import SwiftUI
import ZeboCore
import ZeboUI

/// Une fenêtre qui naît de la notch : la notch se détache et rejoint le centre de l'écran, puis une
/// vraie fenêtre d'application (en verre, sans boutons) prend le relais. À la fin, seul Zebo quitte
/// la fenêtre, fait un clin d'œil et rejoint la notch en salto. Le temps que la fenêtre existe,
/// Zebo a une icône dans le Dock comme n'importe quelle app.
@MainActor
final class DetachedWindowController: NSObject, NSWindowDelegate {
    /// Ce que montre la fenêtre, construit à chaque ouverture.
    struct Content {
        let title: String
        let view: AnyView
        /// Où est Zebo dans la fenêtre quand elle arrive, et quand il la quitte
        /// (repère de la fenêtre, origine en haut à gauche).
        let zeboOnArrival: CGRect
        let zeboOnDeparture: CGRect
    }

    private let flow: DetachedWindowFlow
    private let model: NotchModel
    /// Construit le contenu ; reçoit de quoi fermer la fenêtre (Échap).
    private let makeContent: (_ close: @escaping () -> Void) -> Content

    private var content: Content?
    /// Fenêtre plein écran transparente, le temps des animations.
    private var transitionPanel: OverlayPanel?
    private var window: NSWindow?

    init(
        flow: DetachedWindowFlow, model: NotchModel,
        makeContent: @escaping (_ close: @escaping () -> Void) -> Content
    ) {
        self.flow = flow
        self.model = model
        self.makeContent = makeContent
    }

    func phaseDidChange(to phase: DetachedWindowFlow.Phase) {
        switch phase {
        case .detaching: showTransition()
        case .presenting: showWindow()
        case .returning: showReturn()
        case .idle: tearDown()
        }
    }

    // MARK: - Étapes

    /// À appeler pendant que la notch est encore ouverte : l'animation part de sa forme ouverte.
    private func showTransition() {
        let content = makeContent { [weak self] in self?.window?.close() }
        self.content = content
        let notch = overlayRect(model.panelFrame)
        let view = SetupTransitionView(
            notchFrame: notch,
            windowFrame: overlayRect(windowFrame),
            zeboStart: model.zeboFrame.offsetBy(dx: notch.minX, dy: notch.minY),
            zeboInWindow: content.zeboOnArrival,
            onFinished: { [weak self] in self?.flow.finishDetaching() }
        )
        showPanel(view)
    }

    private func showWindow() {
        guard let content else { return }
        let window = NSWindow(
            contentRect: windowFrame,
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = content.title
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        // Fenêtre en verre, aux coins très arrondis et sans boutons, comme Alcove : c'est la vue
        // qui dessine sa forme ; l'ombre de la fenêtre suit cette forme.
        window.isOpaque = false
        window.backgroundColor = .clear
        for button in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
            window.standardWindowButton(button)?.isHidden = true
        }
        window.appearance = NSAppearance(named: .darkAqua)
        window.isReleasedWhenClosed = false
        let hosting = NSHostingView(rootView: content.view)
        // La fenêtre garde la taille prévue, sans s'ajuster au contenu.
        hosting.sizingOptions = []
        window.contentView = hosting
        // Pile à l'endroit où l'animation s'est arrêtée.
        window.setFrame(windowFrame, display: true)
        window.delegate = self
        self.window = window

        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
        // Au premier plan même si macOS n'a pas (encore) activé Zebo.
        window.orderFrontRegardless()
        window.makeKey()

        // La fenêtre est en place : l'animation peut disparaître sans saut.
        hidePanel()
    }

    /// Seul Zebo quitte la fenêtre (là où elle est, même déplacée) : il passe par le centre
    /// de l'écran, fait un clin d'œil, puis rejoint la notch en salto. La fenêtre s'efface.
    private func showReturn() {
        guard let window, let content else { return tearDown() }
        let notch = overlayRect(closedNotchFrame)
        let windowFrame = overlayRect(window.frame)
        showPanel(
            SetupFinaleView(
                start: content.zeboOnDeparture.offsetBy(dx: windowFrame.minX, dy: windowFrame.minY),
                end: model.zeboFrame.offsetBy(dx: notch.minX, dy: notch.minY),
                screenSize: model.screenFrame.size,
                onFinished: { [weak self] in self?.flow.finishReturning() }
            ))

        self.window = nil
        window.delegate = nil
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.35
            window.animator().alphaValue = 0
        } completionHandler: {
            // AppKit rappelle sur le fil principal.
            MainActor.assumeIsolated {
                window.orderOut(nil)
                window.close()
            }
        }
        NSApp.setActivationPolicy(.accessory)
    }

    private func tearDown() {
        hidePanel()
        content = nil
        if let window {
            self.window = nil
            window.delegate = nil
            window.close()
        }
        // Zebo redevient discret : plus d'icône dans le Dock.
        NSApp.setActivationPolicy(.accessory)
    }

    private func showPanel(_ view: some View) {
        hidePanel()
        let panel = OverlayPanel(rootView: view)
        // Au-dessus de la notch et de la fenêtre.
        panel.level = .mainMenu + 4
        panel.setFrame(model.screenFrame, display: true)
        panel.orderFrontRegardless()
        transitionPanel = panel
    }

    private func hidePanel() {
        transitionPanel?.orderOut(nil)
        transitionPanel = nil
    }

    // MARK: - NSWindowDelegate

    /// Fermée avant la fin : la notch revient tout de suite.
    func windowWillClose(_ notification: Notification) {
        window = nil
        flow.close()
    }

    // MARK: - Géométrie

    /// La fenêtre au centre de l'écran, en coordonnées écran (origine en bas à gauche).
    private var windowFrame: CGRect {
        let area = NSScreen.notchScreen?.visibleFrame ?? model.screenFrame
        let size = SetupWindowLayout.size
        return CGRect(
            x: (area.midX - size.width / 2).rounded(), y: (area.midY - size.height / 2).rounded(),
            width: size.width, height: size.height)
    }

    /// La notch fermée, en coordonnées écran : centrée en haut de la fenêtre de la notch.
    private var closedNotchFrame: CGRect {
        let size = model.closedSize
        return CGRect(
            x: model.panelFrame.midX - size.width / 2, y: model.panelFrame.maxY - size.height,
            width: size.width, height: size.height)
    }

    /// D'un cadre écran (origine en bas à gauche) au repère de la fenêtre plein écran (origine en haut à gauche).
    private func overlayRect(_ rect: CGRect) -> CGRect {
        let screen = model.screenFrame
        return CGRect(
            x: rect.minX - screen.minX, y: screen.maxY - rect.maxY,
            width: rect.width, height: rect.height)
    }
}
