import SwiftUI
import ZeboCore

/// La fenêtre « Nouveau projet » : Zebo en haut à gauche, l'étape en cours, la navigation en bas.
/// Même style et mêmes transitions que la configuration.
public struct NewProjectView: View {
    private let wizard: NewProjectWizard
    /// Crée le projet ; renvoie le problème rencontré, ou `nil` si tout s'est bien passé.
    private let onCreate: () -> String?
    private let onClose: () -> Void

    @State private var displayedStep: NewProjectWizard.Step = .kind
    @State private var isMovingForward = true
    @State private var error: String?
    /// Le projet est créé : Zebo quitte la fenêtre (une autre vue le ramène à la notch).
    @State private var hasZeboLeft = false

    public init(wizard: NewProjectWizard, onCreate: @escaping () -> String?, onClose: @escaping () -> Void) {
        self.wizard = wizard
        self.onCreate = onCreate
        self.onClose = onClose
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            SetupBackground(
                glowCenter: CGPoint(x: zeboFrame.midX, y: zeboFrame.midY), glowSize: zeboFrame.width * 2.6)

            AnimatedZebo(mouse: gaze, center: .zero, isAwake: true, hopTrigger: displayedStep.rawValue)
                .frame(width: zeboFrame.width, height: zeboFrame.height)
                .offset(x: zeboFrame.minX, y: zeboFrame.minY)
                .opacity(hasZeboLeft ? 0 : 1)

            ZStack {
                step(displayedStep)
                    .id(displayedStep)
                    .transition(stepTransition)
            }

            footer

            // Sans bouton de fermeture, Échap ferme la fenêtre.
            Button("", action: onClose)
                .keyboardShortcut(.cancelAction)
                .opacity(0)
                .allowsHitTesting(false)
        }
        .frame(width: SetupWindowLayout.size.width, height: SetupWindowLayout.size.height)
        .clipShape(RoundedRectangle(cornerRadius: SetupWindowLayout.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SetupWindowLayout.cornerRadius, style: .continuous)
                .strokeBorder(.white.opacity(0.14), lineWidth: 1)
        )
        .onChange(of: wizard.step) { _, newStep in
            isMovingForward = wizard.isMovingForward
            error = nil
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
                    displayedStep = newStep
                }
            }
        }
    }

    // MARK: - Étapes

    @ViewBuilder
    private func step(_ step: NewProjectWizard.Step) -> some View {
        switch step {
        case .kind: ProjectKindStep(wizard: wizard)
        case .name: ProjectNameStep(wizard: wizard)
        case .workspace: WorkspaceStep(wizard: wizard)
        case .editor: EditorStep(wizard: wizard, error: error)
        }
    }

    private var stepTransition: AnyTransition {
        let shift: CGFloat = isMovingForward ? 60 : -60
        return .asymmetric(
            insertion: .offset(x: shift).combined(with: .opacity),
            removal: .offset(x: -shift).combined(with: .opacity))
    }

    // MARK: - Zebo

    private var zeboFrame: CGRect { SetupWindowLayout.zeboFrame }

    /// Où regarde Zebo : vers la grille, vers le champ, vers les dossiers…
    private var gaze: CGPoint {
        switch displayedStep {
        case .kind, .editor: CGPoint(x: 20, y: -120)
        case .name: CGPoint(x: 70, y: -90)
        case .workspace: CGPoint(x: 40, y: -110)
        }
    }

    // MARK: - Navigation

    private var footer: some View {
        ZStack {
            PageDots(count: NewProjectWizard.Step.allCases.count, current: wizard.step.rawValue)

            HStack {
                Button(action: wizard.goBack) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(ZeboButtonStyle(shape: .icon))
                .opacity(wizard.canGoBack ? 1 : 0)
                .disabled(!wizard.canGoBack)

                Spacer()

                if wizard.isLastStep {
                    Button("Créer le projet", action: create)
                        .buttonStyle(ZeboButtonStyle(kind: .primary))
                        .keyboardShortcut(.defaultAction)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                } else {
                    Button(action: wizard.advance) {
                        Image(systemName: "arrow.right")
                    }
                    .buttonStyle(ZeboButtonStyle(kind: .primary, shape: .icon))
                    .disabled(!wizard.canAdvance)
                    // Dans le champ du nom, Entrée est gérée par le champ lui-même.
                    .keyboardShortcut(wizard.step == .name ? nil : .defaultAction)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: wizard.step)
        .appearing(order: 3)
    }

    private func create() {
        if let problem = onCreate() {
            withAnimation { error = problem }
        } else {
            hasZeboLeft = true
        }
    }
}
