import AppKit
import SwiftUI
import ZeboCore

public struct NotchView: View {
    private let model: NotchModel
    private let speech: ZeboSpeech
    private let behavior: ZeboBehavior
    private let setup: SetupFlow
    private let settings: ZeboSettings
    private let commits: CommitActivity
    /// La fenêtre « Nouveau projet », qui naît de la notch.
    private let newProject: DetachedWindowFlow
    private let projects: ProjectsLibrary
    /// Ouvre un projet (dans son éditeur, ou dans le Finder).
    private let onOpenProject: (ZeboProject) -> Void
    /// Remise à zéro complète, proposée au clic droit (versions de développement seulement).
    private let onReset: (() -> Void)?

    public init(
        model: NotchModel, speech: ZeboSpeech, behavior: ZeboBehavior, setup: SetupFlow, settings: ZeboSettings,
        commits: CommitActivity, newProject: DetachedWindowFlow, projects: ProjectsLibrary,
        onOpenProject: @escaping (ZeboProject) -> Void, onReset: (() -> Void)? = nil
    ) {
        self.model = model
        self.speech = speech
        self.behavior = behavior
        self.setup = setup
        self.settings = settings
        self.commits = commits
        self.newProject = newProject
        self.projects = projects
        self.onOpenProject = onOpenProject
        self.onReset = onReset
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
                    } else if !preferences.displayableWidgets.isEmpty {
                        widgets
                            .transition(.opacity)
                    }

                    // Un seul Zebo : il glisse et grandit de son lit, dans l'aile gauche, jusqu'à sa place.
                    InBed(isAsleep: mood == .sleeping) {
                        AnimatedZebo(
                            mouse: model.mouseLocation, center: model.zeboScreenCenter,
                            isAwake: model.isOpen, hopTrigger: speech.lineID,
                            mood: mood
                        )
                        // Éjecté ou parti dans la fenêtre de configuration : il disparaît de la notch
                        // (le lit reste), puis revient avec un « pop ».
                        .scaleEffect(isZeboHere ? 1 : 0.01)
                        .opacity(isZeboHere ? 1 : 0)
                        // Il disparaît d'un coup, mais revient avec un rebond.
                        .animation(
                            isZeboHere ? .spring(response: 0.5, dampingFraction: 0.55) : nil,
                            value: isZeboHere
                        )
                    }
                    .overlay { SleepingZs(isActive: mood == .sleeping && isZeboHere) }
                    .frame(width: zeboFrame.width, height: zeboFrame.height)
                    .contentShape(Rectangle())
                    // Notch ouverte, un clic sur Zebo le fait parler (et trop de clics l'assomment) ;
                    // fermée, il ouvre la notch, comme partout ailleurs sur elle.
                    .onTapGesture {
                        if model.isOpen { behavior.poke() } else { open() }
                    }
                    .offset(x: zeboFrame.minX, y: zeboFrame.minY)
                }
            }
            .clipShape(NotchShape(bottomRadius: bottomRadius))
            // Comme Alcove : la notch survolée grandit un peu, et s'ouvre au clic.
            .contentShape(NotchShape(bottomRadius: bottomRadius))
            .onTapGesture {
                if !model.isOpen { open() }
            }
            .contextMenu {
                Button("Reconfigurer Zebo…") { setup.reconfigure() }
                if let onReset {
                    Button("Réinitialiser Zebo", action: onReset)
                }
                Divider()
                Button("Quitter Zebo") { NSApp.terminate(nil) }
            }
            // Pendant la configuration, la notch est devenue la fenêtre : elle n'est plus là.
            // Elle disparaît d'un coup (l'animation prend sa place) et revient en fondu.
            .opacity(isAvailable ? 1 : 0)
            .animation(isAvailable ? .easeOut(duration: 0.35) : nil, value: isAvailable)
            // La fenêtre est plus grande que la notch : on colle le dessin en haut.
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var preferences: ZeboPreferences { settings.preferences }

    /// Ouvre la notch (elle se refermera quand la souris s'en ira).
    private func open() {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
            model.isOpen = true
            model.isPeeking = false
        }
    }

    /// Zebo est dans la notch : ni éjecté, ni parti dans la fenêtre de configuration.
    private var isZeboHere: Bool { behavior.isHome && isAvailable }

    /// Aucune fenêtre n'est née de la notch (configuration, nouveau projet) : elle est là.
    private var isAvailable: Bool { setup.isNotchAvailable && newProject.isIdle }

    /// Sonné avant tout ; sinon, quand il parle, il prend un air pensif 🤔 ;
    /// et quand la notch est fermée, il dort (s'il fait la sieste).
    private var mood: ZeboMood {
        if behavior.state == .dizzy { return .dizzy }
        if speech.line != nil { return .thinking }
        if model.isOpen || !preferences.sleepsWhenClosed { return .calm }
        return .sleeping
    }

    /// Les widgets choisis (l'heure, la date…), centrés dans l'aile droite de la notch fermée.
    private var widgets: some View {
        NotchWidgetsView(
            widgets: preferences.displayableWidgets, interval: preferences.widgetRotationInterval,
            language: preferences.favoriteLanguage, commitCount: commits.todayCount
        )
        .frame(width: NotchModel.wingWidth - NotchModel.topCornerRadius, height: model.hardwareNotchSize.height)
        .offset(x: size.width - NotchModel.wingWidth)
    }

    /// À droite de Zebo : le bouton de configuration tant qu'il n'est pas configuré,
    /// sinon les onglets (Accueil, Projets).
    private var openText: some View {
        Group {
            if setup.needsSetup {
                SetupPrompt { setup.start() }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    NotchTabBar(selection: Bindable(model).selectedTab)
                    Group {
                        switch model.selectedTab {
                        case .home: comingSoon
                        case .projects:
                            ProjectsTabView(library: projects, onOpen: onOpenProject) { newProject.open() }
                        }
                    }
                    .transition(.opacity.combined(with: .offset(y: 6)))
                    .id(model.selectedTab)
                }
                .padding(.top, 8)
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.trailing, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        // Le haut est caché par l'encoche physique : on démarre en dessous.
        .padding(.top, model.hardwareNotchSize.height)
        .padding(.leading, 32 + 96 + 20)
    }

    private var comingSoon: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(preferences.name.isEmpty ? "Salut, moi c'est Zebo !" : "Salut, \(preferences.name) !")
                .font(.headline)
                .foregroundStyle(.white)
            Text("SOON... In progress…")
                .fontWidth(Font.Width.expanded)
                .fontWeight(Font.Weight.bold)
                .foregroundStyle(.white)
        }
    }
}
