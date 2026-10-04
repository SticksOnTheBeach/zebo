import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: NotchPanel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        panel = NotchPanel()
        panel?.reposition()
        panel?.orderFrontRegardless()

        // Branchement/débranchement d'écran, changement de résolution…
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    @objc private func screensDidChange() {
        panel?.reposition()
    }
}
