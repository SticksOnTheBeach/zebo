import AppKit
import ZeboCore
import ZeboUI

/// La petite fenêtre des initiatives de Zebo, juste sous la notch (ouverte ou fermée).
/// Elle prend le clavier le temps d'une proposition : maintenir Y accepte, N refuse, Échap refuse.
@MainActor
final class InitiativeWindowController {
    private let initiatives: ZeboInitiatives
    private let model: NotchModel
    private let panel: InitiativePanel

    init(initiatives: ZeboInitiatives, model: NotchModel) {
        self.initiatives = initiatives
        self.model = model
        panel = InitiativePanel(rootView: InitiativeView(initiatives: initiatives))
        // Sous la notch : la carte a l'air d'en sortir.
        panel.level = .mainMenu + 2
        panel.onKey = { [weak self] event in self?.handle(event) ?? false }
        initiatives.onChange = { [weak self] proposal in self?.proposalDidChange(proposal) }
    }

    /// Colle la fenêtre sous la notch, à sa taille du moment.
    func reposition() {
        guard let screen = NSScreen.notchScreen else { return }
        let size = InitiativeView.windowSize
        let top = screen.frame.maxY - model.notchSize.height
        let frame = CGRect(
            x: screen.frame.midX - size.width / 2, y: top - size.height, width: size.width, height: size.height)
        panel.setFrame(frame, display: true, animate: panel.isVisible)
    }

    private func proposalDidChange(_ proposal: ZeboInitiatives.Proposal?) {
        if proposal != nil {
            reposition()
            panel.ignoresMouseEvents = false
            // Le clavier vient à Zebo (sans activer l'app), pour Y et N.
            panel.makeKeyAndOrderFront(nil)
        } else {
            panel.ignoresMouseEvents = true
            // On laisse la carte s'en aller, puis on rend le clavier à l'app de devant.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                guard let self, initiatives.current == nil else { return }
                panel.orderOut(nil)
            }
        }
    }

    /// Y et N (maintenues), Échap ; toute autre touche rend le clavier à l'app de devant.
    private func handle(_ event: NSEvent) -> Bool {
        guard initiatives.current != nil else { return false }
        if event.type == .keyDown, event.keyCode == 53 {
            initiatives.choose(.refuse)
            return true
        }
        let isPlainKey = event.modifierFlags.intersection([.command, .control, .option]).isEmpty
        let choice: ZeboInitiatives.Choice? =
            switch event.charactersIgnoringModifiers?.lowercased() {
            case "y" where isPlainKey: .accept
            case "n" where isPlainKey: .refuse
            default: nil
            }
        guard let choice else {
            // On tapait ailleurs : la carte reste, mais le clavier repart (un clic dessus le reprend).
            if event.type == .keyDown { giveKeyboardBack() }
            return true
        }
        if event.type == .keyDown {
            if !event.isARepeat { initiatives.press(choice) }
        } else {
            initiatives.release(choice)
        }
        return true
    }

    private func giveKeyboardBack() {
        panel.orderOut(nil)
        panel.orderFrontRegardless()
    }
}

/// La fenêtre des initiatives : elle intercepte les touches avant SwiftUI.
final class InitiativePanel: OverlayPanel {
    /// Renvoie `true` si la touche a été traitée.
    var onKey: ((NSEvent) -> Bool)?

    override func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown || event.type == .keyUp, onKey?(event) == true { return }
        super.sendEvent(event)
    }
}
