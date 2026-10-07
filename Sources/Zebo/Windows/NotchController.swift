import AppKit
import SwiftUI
import ZeboCore
import ZeboUI

/// Crée la notch, la bulle de dialogue et la fenêtre de chute, les place sur le bon écran
/// et ouvre/ferme la notch selon la position de la souris. Lance aussi la configuration de Zebo.
@MainActor
final class NotchController: NSObject {
    private let model = NotchModel()
    private let speech = ZeboSpeech()
    private let behavior: ZeboBehavior
    private let setup = SetupFlow(store: UserDefaultsSetupStore())
    private let settings = ZeboSettings(store: UserDefaultsPreferencesStore())
    private let commits = CommitActivity(counter: GitCommitCounter())
    private let keyStore = KeychainAPIKeyStore()
    /// La fenêtre « Nouveau projet », et les projets créés avec Zebo.
    private let newProject = DetachedWindowFlow()
    private let projects = ProjectsLibrary(store: UserDefaultsProjectsStore())
    /// La discussion avec Zebo (onglet IA), qui dure tant que l'app tourne.
    private let chat = ZeboChat()
    private let projectWindow: ProjectWindowController
    private let settingsWindow: SettingsWindowController
    /// Recompte les commits du jour de temps en temps.
    private var commitsTimer: Timer?
    private let panel: OverlayPanel
    /// Fenêtre de la bulle : juste sous la notch, ne capte jamais les clics.
    private let bubblePanel: OverlayPanel
    /// Fenêtre plein écran où Zebo tombe quand il est éjecté ; affichée seulement pendant la chute.
    private let fallPanel: OverlayPanel
    private let mouse = MouseMonitor()
    private let setupWindow: SetupWindowController
    /// Les initiatives de Zebo, proposées sous la notch.
    private let initiativeWindow: InitiativeWindowController

    override init() {
        behavior = ZeboBehavior(placement: model, speech: speech)
        let settingsWindow = SettingsWindowController(
            settings: settings, commits: commits, keyStore: keyStore, setup: setup, reset: Self.devReset)
        self.settingsWindow = settingsWindow
        // Ouvrir un projet retient l'éditeur choisi pour la prochaine fois.
        let library = projects
        let openProject: (ZeboProject, ProjectOpenTarget) -> Void = { project, target in
            ProjectOpener.open(project, with: target)
            library.remember(target, for: project)
        }
        panel = OverlayPanel(
            rootView: NotchView(
                model: model, speech: speech, behavior: behavior, setup: setup, settings: settings,
                commits: commits, newProject: newProject, projects: projects, chat: chat,
                onOpenProject: openProject, onOpenSettings: { settingsWindow.show() }, onReset: Self.devReset))
        bubblePanel = OverlayPanel(rootView: SpeechBubbleView(model: model, speech: speech))
        // Sous la notch : les points qui dépassent vers Zebo passent derrière elle.
        bubblePanel.level = .mainMenu + 2
        fallPanel = OverlayPanel(rootView: FallingZeboView(behavior: behavior))
        // Au-dessus de la notch : Zebo en sort par-dessus.
        fallPanel.level = .mainMenu + 4
        setupWindow = SetupWindowController(
            flow: setup, model: model, settings: settings, commits: commits, keyStore: keyStore)
        projectWindow = ProjectWindowController(
            flow: newProject, model: model, settings: settings, library: projects, keyStore: keyStore)
        initiativeWindow = InitiativeWindowController(initiatives: chat.initiatives, model: model)
        super.init()

        // Dans la discussion, Zebo peut ouvrir des éditeurs et des projets, et en créer.
        chat.actions = MacActions(settings: settings, library: projects)
        // Zebo veut créer un projet : la notch s'ouvre sur sa fiche, prête à recevoir le nom.
        chat.onProjectDraftChange = { [weak self] draft in
            guard let self, draft != nil, isNotchAvailable else { return }
            model.selectedTab = .ai
            setOpen(true)
            panel.makeKey()
        }

        setup.onPhaseChange = { [weak self] phase in self?.setupPhaseDidChange(phase) }
        newProject.onPhaseChange = { [weak self] phase in self?.projectPhaseDidChange(phase) }
        settingsWindow.onPreferencesChange = { [weak self] in self?.applyPreferences() }
        // Les projets supprimés ou déplacés depuis la dernière fois sont oubliés.
        projects.forgetMissing()
        applyPreferences()
        commitsTimer = Timer.scheduledTimer(withTimeInterval: 5 * 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refreshCommits() }
        }

        behavior.onFlightChange = { [weak self] isFlying in
            guard let self else { return }
            if isFlying {
                fallPanel.setFrame(model.screenFrame, display: true)
                fallPanel.orderFrontRegardless()
            } else {
                fallPanel.orderOut(nil)
            }
        }

        reposition()
        bubblePanel.orderFrontRegardless()
        panel.orderFrontRegardless()
        mouse.start { [weak self] in self?.mouseDidMove() }
        playLaunch()

        // Branchement/débranchement d'écran, changement de résolution…
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reposition),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        // On a cliqué ailleurs pendant qu'on écrivait à Zebo.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(panelDidResignKey),
            name: NSWindow.didResignKeyNotification,
            object: panel
        )
    }

    @objc private func reposition() {
        guard let screen = NSScreen.notchScreen else { return }
        let notch = screen.notchSize
        model.hardwareNotchSize = notch

        // Les deux fenêtres sont centrées sur la notch et collées en haut de l'écran.
        func topCentered(_ size: CGSize) -> CGRect {
            CGRect(
                x: screen.frame.midX - size.width / 2, y: screen.frame.maxY - size.height,
                width: size.width, height: size.height)
        }
        panel.setFrame(topCentered(NotchModel.largestOpenSize), display: true)
        bubblePanel.setFrame(topCentered(SpeechBubbleView.windowSize), display: true)
        model.panelFrame = panel.frame
        model.screenFrame = screen.frame
        initiativeWindow.reposition()
        model.mouseLocation = NSEvent.mouseLocation
    }

    /// Remise à zéro, en développement seulement.
    private static var devReset: (() -> Void)? {
        #if DEBUG
            return DevReset.resetAndRelaunch
        #else
            return nil
        #endif
    }

    // MARK: - Configuration

    private func setupPhaseDidChange(_ phase: SetupFlow.Phase) {
        // D'abord l'animation, qui part de la notch encore ouverte…
        setupWindow.phaseDidChange(to: phase)
        // Configuration terminée : Zebo parle désormais selon ses nouveaux réglages.
        if phase == .returning { applyPreferences() }
        if phase == .detaching { notchDidDetach() }
    }

    private func projectPhaseDidChange(_ phase: DetachedWindowFlow.Phase) {
        // D'abord l'animation, qui part de la notch encore ouverte…
        projectWindow.phaseDidChange(to: phase)
        if phase == .detaching { notchDidDetach() }
    }

    /// …pendant que la notch, masquée, se referme : c'est elle qui part vers le centre de l'écran.
    /// Elle sera fermée quand elle reviendra. Zebo se tait : sa bulle ne reste pas seule à l'écran.
    private func notchDidDetach() {
        speech.silence()
        setOpen(false)
    }

    /// Aucune fenêtre n'est née de la notch (configuration, nouveau projet).
    private var isNotchAvailable: Bool {
        setup.isNotchAvailable && newProject.isIdle
    }

    /// Ouvre la fenêtre de paramètres (ou la ramène devant).
    func showSettings() {
        settingsWindow.show()
    }

    /// Une fois configuré, Zebo t'appelle par ton prénom, compte tes commits du jour
    /// et discute grâce à l'IA choisie (s'il a sa clé).
    private func applyPreferences() {
        guard setup.isComplete else { return }
        let preferences = settings.preferences
        speech.lineSource = CannedLines(preferences: preferences)
        chat.userName = preferences.name
        chat.alwaysAllowed = preferences.alwaysAllowed
        chat.client = preferences.aiProvider.flatMap { provider in
            keyStore.readKey(for: provider).map { key in
                provider.makeClient(
                    apiKey: key, model: preferences.model(for: provider), transport: URLSessionTransport())
            }
        }
        refreshCommits()
    }

    /// Recompte les commits du jour, si le widget des commits est affiché.
    private func refreshCommits() {
        let preferences = settings.preferences
        guard setup.isComplete, preferences.shows(.commits) else { return }
        let folder = preferences.projectsFolder.map { URL(fileURLWithPath: $0) } ?? ProjectsFolder.guessOnThisMac()
        guard let folder else { return }
        Task { await commits.refresh(in: folder) }
    }

    // MARK: - Lancement

    /// Zebo fait son entrée : la notch s'agrandit, il surgit et dit bonjour, puis elle se referme
    /// et il retourne dans son lit.
    private func playLaunch() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self, isNotchAvailable else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.72)) { model.isLaunching = true }
            initiativeWindow.reposition()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) { [weak self] in
                guard let self else { return }
                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { model.isLaunching = false }
                initiativeWindow.reposition()
            }
        }
    }

    // MARK: - Survol

    private func mouseDidMove() {
        // Zebo suit la souris des yeux, notch ouverte ou fermée.
        model.mouseLocation = NSEvent.mouseLocation
        // Pendant la configuration (ou l'entrée en scène), la notch reste comme elle est.
        guard isNotchAvailable, !model.isLaunching else { return }

        // +1 en haut : la souris collée au bord de l'écran est pile sur maxY.
        func contains(_ area: CGRect) -> Bool {
            area.insetBy(dx: 0, dy: -1).contains(NSEvent.mouseLocation)
        }

        // Ouverte, elle se referme quand la souris s'en va, sauf si l'on est en train d'écrire.
        // La fenêtre est taillée pour le plus grand onglet : seule la notch visible compte.
        if model.isOpen {
            if !contains(notchFrame(size: model.openSize)), !model.isTyping, chat.projectDraft == nil {
                setOpen(false)
            }
            return
        }
        // Fermée, elle grandit un peu au survol ; un clic l'ouvrira (voir NotchView).
        // Une fois survolée, on garde sa taille agrandie comme zone, pour ne pas clignoter au bord.
        setPeeking(contains(notchFrame(size: model.isPeeking ? model.peekSize : model.closedSize)))
    }

    private func setPeeking(_ isPeeking: Bool) {
        guard isPeeking != model.isPeeking else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            model.isPeeking = isPeeking
        }
        // Survolée, elle capte les clics (pour s'ouvrir) ; sinon ils vont à la barre des menus.
        panel.ignoresMouseEvents = !isPeeking
    }

    private func setOpen(_ isOpen: Bool) {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
            model.isOpen = isOpen
            model.isPeeking = false
        }
        // Fermée, la fenêtre laisse passer les clics vers la barre des menus.
        panel.ignoresMouseEvents = !isOpen
        // Une initiative affichée suit le bas de la notch.
        initiativeWindow.reposition()
        // …et rend le clavier à l'app de devant, s'il était resté dans la notch.
        if !isOpen, panel.isKeyWindow {
            model.isTyping = false
            panel.orderOut(nil)
            panel.orderFrontRegardless()
        }
    }

    /// Un clic ailleurs : on n'écrit plus à Zebo, et la notch se ferme si la souris n'y est pas.
    @objc private func panelDidResignKey() {
        model.isTyping = false
        if model.isOpen, chat.projectDraft == nil,
            !notchFrame(size: model.openSize).insetBy(dx: 0, dy: -1).contains(NSEvent.mouseLocation)
        {
            setOpen(false)
        }
    }

    /// La notch visible (fermée, survolée ou ouverte), en coordonnées écran.
    private func notchFrame(size: CGSize) -> CGRect {
        CGRect(
            x: panel.frame.midX - size.width / 2,
            y: panel.frame.maxY - size.height,
            width: size.width,
            height: size.height)
    }
}
