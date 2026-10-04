import AppKit
import SwiftUI

/// Crée la notch, la place sur le bon écran et l'ouvre/ferme selon la position de la souris.
@MainActor
final class NotchController: NSObject {
    private let model = NotchModel()
    private let panel: NotchPanel
    private var mouseMonitors: [Any] = []

    override init() {
        panel = NotchPanel(model: model)
        super.init()

        reposition()
        panel.orderFrontRegardless()
        startMouseMonitoring()

        // Branchement/débranchement d'écran, changement de résolution…
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reposition),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    @objc private func reposition() {
        guard let screen = NSScreen.notchScreen else { return }
        let notch = screen.notchSize
        model.closedSize = CGSize(width: notch.width + NotchPanel.wingWidth * 2, height: notch.height)

        let size = model.openSize
        let origin = CGPoint(x: screen.frame.midX - size.width / 2,
                             y: screen.frame.maxY - size.height)
        panel.setFrame(CGRect(origin: origin, size: size), display: true)
    }

    // MARK: - Survol

    private func startMouseMonitoring() {
        let events: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged, .rightMouseDragged]

        // Souris au-dessus des autres apps (aucune permission requise pour la souris).
        if let global = NSEvent.addGlobalMonitorForEvents(matching: events, handler: { [weak self] _ in
            MainActor.assumeIsolated { self?.mouseDidMove() }
        }) {
            mouseMonitors.append(global)
        }
        // Souris au-dessus de notre propre fenêtre.
        if let local = NSEvent.addLocalMonitorForEvents(matching: events, handler: { [weak self] event in
            MainActor.assumeIsolated { self?.mouseDidMove() }
            return event
        }) {
            mouseMonitors.append(local)
        }
    }

    private func mouseDidMove() {
        // Fermée, seule la petite notch réagit ; ouverte, toute la fenêtre compte.
        let activeArea = model.isOpen ? panel.frame : closedFrame
        // +1 en haut : la souris collée au bord de l'écran est pile sur maxY.
        let isInside = activeArea.insetBy(dx: 0, dy: -1).contains(NSEvent.mouseLocation)
        guard isInside != model.isOpen else { return }

        withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
            model.isOpen = isInside
        }
        // Fermée, la fenêtre laisse passer les clics vers la barre des menus.
        panel.ignoresMouseEvents = !isInside
    }

    private var closedFrame: CGRect {
        let size = model.closedSize
        return CGRect(x: panel.frame.midX - size.width / 2,
                      y: panel.frame.maxY - size.height,
                      width: size.width,
                      height: size.height)
    }
}
