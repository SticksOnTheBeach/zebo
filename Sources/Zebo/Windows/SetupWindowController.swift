import AppKit
import SwiftUI
import ZeboCore
import ZeboUI

/// Montre la configuration de Zebo : la notch qui se détache et rejoint le centre de l'écran,
/// puis une vraie fenêtre d'application à sa place. Le temps de la configuration,
/// Zebo a une icône dans le Dock comme n'importe quelle app.
@MainActor
final class SetupWindowController: NSObject, NSWindowDelegate {
    private let flow: SetupFlow
    private let model: NotchModel
    /// Fenêtre plein écran transparente, le temps de l'animation.
    private var transitionPanel: OverlayPanel?
    private var window: NSWindow?

    init(flow: SetupFlow, model: NotchModel) {
        self.flow = flow
        self.model = model
    }

    func phaseDidChange(to phase: SetupFlow.Phase) {
        switch phase {
        case .detaching: showTransition()
        case .configuring: showWindow()
        case .idle: tearDown()
        }
    }

    // MARK: - Étapes

    /// À appeler pendant que la notch est encore ouverte : l'animation part de sa forme ouverte.
    private func showTransition() {
        let notch = overlayRect(model.panelFrame)
        let view = SetupTransitionView(
            notchFrame: notch,
            windowFrame: overlayRect(windowFrame),
            zeboStart: model.zeboFrame.offsetBy(dx: notch.minX, dy: notch.minY),
            onFinished: { [weak self] in self?.flow.finishDetaching() }
        )
        let panel = OverlayPanel(rootView: view)
        // Au-dessus de la notch : c'est elle qui s'en détache.
        panel.level = .mainMenu + 4
        panel.setFrame(model.screenFrame, display: true)
        panel.orderFrontRegardless()
        transitionPanel = panel
    }

    private func showWindow() {
        let window = NSWindow(
            contentRect: windowFrame,
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Configurer Zebo"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.backgroundColor = .black
        window.appearance = NSAppearance(named: .darkAqua)
        window.isReleasedWhenClosed = false
        let content = NSHostingView(rootView: SetupView())
        // La fenêtre garde la taille prévue, sans s'ajuster au contenu.
        content.sizingOptions = []
        window.contentView = content
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
        transitionPanel?.orderOut(nil)
        transitionPanel = nil
    }

    private func tearDown() {
        transitionPanel?.orderOut(nil)
        transitionPanel = nil
        if let window {
            self.window = nil
            window.delegate = nil
            window.close()
        }
        // Zebo redevient discret : plus d'icône dans le Dock.
        NSApp.setActivationPolicy(.accessory)
    }

    // MARK: - NSWindowDelegate

    /// Fermée avant la fin : la configuration pourra reprendre depuis la notch.
    func windowWillClose(_ notification: Notification) {
        window = nil
        flow.close()
    }

    // MARK: - Géométrie

    /// Fenêtre de configuration au centre de l'écran, en coordonnées écran (origine en bas à gauche).
    private var windowFrame: CGRect {
        let area = NSScreen.notchScreen?.visibleFrame ?? model.screenFrame
        let size = SetupWindowLayout.size
        return CGRect(
            x: (area.midX - size.width / 2).rounded(), y: (area.midY - size.height / 2).rounded(),
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
