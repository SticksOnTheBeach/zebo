import SwiftUI
import ZeboCore

/// La fenêtre de configuration : Zebo (en grand sur l'accueil, puis en haut à gauche),
/// l'étape en cours, et la navigation en bas.
/// À chaque étape, le contenu part d'un côté et le suivant arrive de l'autre, élément par élément.
public struct SetupView: View {
    private let wizard: SetupWizard
    private let commits: CommitActivity
    private let onFinish: () -> Void
    private let onClose: () -> Void

    /// L'étape affichée suit celle de l'assistant avec un temps de retard,
    /// pour que l'étape qui s'en va connaisse déjà le sens du déplacement.
    @State private var displayedStep: SetupWizard.Step = .welcome
    @State private var isMovingForward = true
    /// « C'est parti » : Zebo quitte la fenêtre (une autre vue le fait voyager jusqu'à la notch).
    @State private var hasZeboLeft = false

    /// - Parameters:
    ///   - onFinish: « C'est parti » : enregistrer et retourner dans la notch.
    ///   - onClose: Échap : fermer la fenêtre sans rien enregistrer.
    public init(
        wizard: SetupWizard, commits: CommitActivity, onFinish: @escaping () -> Void,
        onClose: @escaping () -> Void = {}
    ) {
        self.wizard = wizard
        self.commits = commits
        self.onFinish = onFinish
        self.onClose = onClose
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            SetupBackground(
                glowCenter: CGPoint(x: zeboFrame.midX, y: zeboFrame.midY), glowSize: zeboFrame.width * 2.6)

            zebo

            ZStack {
                step(displayedStep)
                    .id(displayedStep)
                    .transition(stepTransition)
            }

            footer

            // Sans bouton de fermeture (comme Alcove), Échap ferme la fenêtre.
            Button("", action: onClose)
                .keyboardShortcut(.cancelAction)
                .opacity(0)
                .allowsHitTesting(false)
        }
        .frame(width: SetupWindowLayout.size.width, height: SetupWindowLayout.size.height)
        .clipShape(RoundedRectangle(cornerRadius: SetupWindowLayout.cornerRadius, style: .continuous))
        .overlay(
            // Un liseré de lumière sur le bord du verre.
            RoundedRectangle(cornerRadius: SetupWindowLayout.cornerRadius, style: .continuous)
                .strokeBorder(.white.opacity(0.14), lineWidth: 1)
        )
        .onChange(of: wizard.step) { _, newStep in
            isMovingForward = wizard.isMovingForward
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
                    displayedStep = newStep
                }
            }
        }
    }

    // MARK: - Étapes

    @ViewBuilder
    private func step(_ step: SetupWizard.Step) -> some View {
        switch step {
        case .welcome: WelcomeStep(onStart: wizard.advance)
        case .name: NameStep(wizard: wizard)
        case .language: LanguageStep(wizard: wizard)
        case .ide: IDEStep(wizard: wizard)
        case .notch: NotchStep(wizard: wizard, commits: commits)
        case .ready: ReadyStep(wizard: wizard)
        }
    }

    /// En avant, l'étape arrive de la droite et la précédente part vers la gauche ; en arrière, l'inverse.
    private var stepTransition: AnyTransition {
        let shift: CGFloat = isMovingForward ? 60 : -60
        return .asymmetric(
            insertion: .offset(x: shift).combined(with: .opacity),
            removal: .offset(x: -shift).combined(with: .opacity))
    }

    // MARK: - Zebo

    /// Il saute à chaque étape et regarde ce qui l'intéresse.
    private var zebo: some View {
        AnimatedZebo(mouse: gaze, center: .zero, isAwake: true, hopTrigger: displayedStep.rawValue)
            .frame(width: zeboFrame.width, height: zeboFrame.height)
            .offset(x: zeboFrame.minX, y: zeboFrame.minY)
            .opacity(hasZeboLeft ? 0 : 1)
    }

    /// Où est Zebo : en grand au centre pour l'accueillir, puis à sa place en haut à gauche.
    private var zeboFrame: CGRect {
        displayedStep == .welcome ? SetupWindowLayout.welcomeZeboFrame : SetupWindowLayout.zeboFrame
    }

    /// Où regarde Zebo (y vers le haut, comme à l'écran) : vers le champ du prénom, vers les cartes,
    /// vers la notch… ou droit devant.
    private var gaze: CGPoint {
        switch displayedStep {
        case .welcome, .ready: .zero
        case .name: CGPoint(x: 70, y: -90)
        case .language, .ide: CGPoint(x: 20, y: -120)
        case .notch: CGPoint(x: 30, y: 120)
        }
    }

    // MARK: - Navigation

    private var footer: some View {
        ZStack {
            PageDots(count: SetupWizard.Step.allCases.count, current: wizard.step.rawValue)

            HStack {
                Button(action: wizard.goBack) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(ZeboButtonStyle(shape: .icon))
                .opacity(wizard.canGoBack ? 1 : 0)
                .disabled(!wizard.canGoBack)

                Spacer()

                if wizard.isLastStep {
                    Button("C'est parti") {
                        hasZeboLeft = true
                        onFinish()
                    }
                    .buttonStyle(ZeboButtonStyle(kind: .primary))
                    .keyboardShortcut(.defaultAction)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                } else {
                    Button(action: wizard.advance) {
                        Image(systemName: "arrow.right")
                    }
                    .buttonStyle(ZeboButtonStyle(kind: .primary, shape: .icon))
                    .disabled(!wizard.canAdvance)
                    // Dans le champ du prénom, Entrée est gérée par le champ lui-même.
                    .keyboardShortcut(wizard.step == .name ? nil : .defaultAction)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: wizard.step)
        // L'accueil a son propre bouton « Commencer », au centre.
        .opacity(displayedStep == .welcome ? 0 : 1)
        .allowsHitTesting(displayedStep != .welcome)
        .animation(.easeOut(duration: 0.3), value: displayedStep == .welcome)
        .appearing(order: 3)
    }
}
