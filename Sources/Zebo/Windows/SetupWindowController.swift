import AppKit
import SwiftUI
import ZeboCore
import ZeboUI

/// Montre la configuration de Zebo : la notch qui se détache et rejoint le centre de l'écran,
/// puis une vraie fenêtre d'application à sa place, qui retourne dans la notch une fois terminée.
/// Le temps de la configuration, Zebo a une icône dans le Dock comme n'importe quelle app.
@MainActor
final class SetupWindowController: NSObject, NSWindowDelegate {
    private let flow: SetupFlow
    private let model: NotchModel
    private let settings: ZeboSettings
    private let commits: CommitActivity
    /// Fenêtre plein écran transparente, le temps de l'animation.
    private var transitionPanel: OverlayPanel?
    private var window: NSWindow?

    init(flow: SetupFlow, model: NotchModel, settings: ZeboSettings, commits: CommitActivity) {
        self.flow = flow
        self.model = model
        self.settings = settings
        self.commits = commits
    }

    func phaseDidChange(to phase: SetupFlow.Phase) {
        switch phase {
        case .detaching: showTransition()
        case .configuring: showWindow()
        case .returning: showReturn()
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
        // Fenêtre en verre, aux coins très arrondis et sans boutons, comme Alcove : c'est la vue
        // qui dessine sa forme ; l'ombre de la fenêtre suit cette forme.
        window.isOpaque = false
        window.backgroundColor = .clear
        for button in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
            window.standardWindowButton(button)?.isHidden = true
        }
        window.appearance = NSAppearance(named: .darkAqua)
        window.isReleasedWhenClosed = false
        // On part des réglages actuels : une reconfiguration les retrouve tels quels.
        let wizard = SetupWizard(draft: settings.preferences, locator: WorkspaceApplicationLocator())
        // Le dossier de projets est deviné, et les commits du jour comptés pour l'aperçu.
        if wizard.draft.projectsFolder == nil {
            wizard.draft.projectsFolder = ProjectsFolder.guessOnThisMac()?.path
        }
        if let folder = wizard.draft.projectsFolder {
            Task { await commits.refresh(in: URL(fileURLWithPath: folder)) }
        }
        let content = NSHostingView(
            rootView: SetupView(
                wizard: wizard, commits: commits,
                onFinish: { [weak self] in
                    self?.settings.preferences = wizard.preferences
                    self?.flow.complete()
                },
                onClose: { [weak window] in window?.close() }))
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

    /// La fenêtre (là où elle est, même déplacée) se rétracte dans la notch fermée.
    private func showReturn() {
        guard let window else { return tearDown() }
        let notch = overlayRect(closedNotchFrame)
        let view = SetupTransitionView(
            notchFrame: notch,
            windowFrame: overlayRect(window.frame),
            zeboStart: model.zeboFrame.offsetBy(dx: notch.minX, dy: notch.minY),
            notchBottomRadius: 12,
            isReversed: true,
            onFinished: { [weak self] in self?.flow.finishReturning() }
        )
        let panel = OverlayPanel(rootView: view)
        panel.level = .mainMenu + 4
        panel.setFrame(model.screenFrame, display: true)
        // L'animation se pose par-dessus la fenêtre avant qu'elle disparaisse : pas de saut.
        panel.orderFrontRegardless()
        transitionPanel = panel

        self.window = nil
        window.delegate = nil
        window.orderOut(nil)
        window.close()
        NSApp.setActivationPolicy(.accessory)
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
