import AppKit
import SwiftUI
import ZeboCore
import ZeboUI

/// La fenêtre de paramètres, en dehors de la notch. Une seule à la fois : la rouvrir la ramène devant.
@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
    /// Appelé après chaque changement de préférences (pour les appliquer : répliques, commits…).
    var onPreferencesChange: (() -> Void)?

    private let settings: ZeboSettings
    private let commits: CommitActivity
    private let keyStore: any APIKeyStore
    private let setup: SetupFlow
    private let reset: (() -> Void)?
    private var window: NSWindow?

    init(
        settings: ZeboSettings, commits: CommitActivity, keyStore: any APIKeyStore, setup: SetupFlow,
        reset: (() -> Void)?
    ) {
        self.settings = settings
        self.commits = commits
        self.keyStore = keyStore
        self.setup = setup
        self.reset = reset
    }

    func show() {
        if let window {
            NSApp.activate()
            window.makeKeyAndOrderFront(nil)
            return
        }
        let window = NSWindow(
            contentRect: CGRect(origin: .zero, size: SettingsView.size),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Paramètres de Zebo"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        // Le verre de la vue laisse voir ce qu'il y a derrière la fenêtre.
        window.isOpaque = false
        window.backgroundColor = .clear
        window.appearance = NSAppearance(named: .darkAqua)
        window.isReleasedWhenClosed = false
        let hosting = NSHostingView(rootView: makeView(closing: window))
        hosting.sizingOptions = []
        window.contentView = hosting
        window.center()
        window.delegate = self
        self.window = window

        AppPresence.windowDidOpen()
        window.makeKeyAndOrderFront(nil)
    }

    private func makeView(closing window: NSWindow) -> SettingsView {
        let wizard = SetupWizard(draft: settings.preferences, locator: WorkspaceApplicationLocator())
        wizard.providersWithStoredKey = Set(AIProvider.allCases.filter { keyStore.readKey(for: $0) != nil })
        if wizard.draft.projectsFolder == nil {
            wizard.draft.projectsFolder = ProjectsFolder.guessOnThisMac()?.path
        }
        if let folder = wizard.draft.projectsFolder {
            Task { await commits.refresh(in: URL(fileURLWithPath: folder)) }
        }
        let actions = SettingsView.Actions(
            preferencesDidChange: { [weak self] preferences in
                self?.settings.preferences = preferences
                self?.onPreferencesChange?()
            },
            saveKey: { [keyStore] key, provider in
                do {
                    try keyStore.saveKey(key, for: provider)
                    return nil
                } catch {
                    return "Je n'ai pas pu ranger la clé dans le trousseau."
                }
            },
            deleteKey: { [keyStore] provider in keyStore.deleteKey(for: provider) },
            reconfigure: { [weak self, weak window] in
                window?.close()
                self?.setup.reconfigure()
            },
            quit: { NSApp.terminate(nil) },
            reset: reset)
        return SettingsView(wizard: wizard, commits: commits, actions: actions)
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        window = nil
        AppPresence.windowDidClose()
    }
}
