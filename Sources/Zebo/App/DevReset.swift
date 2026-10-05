#if DEBUG
    import AppKit

    /// Outil de développement : efface tout ce que Zebo a enregistré (configuration, préférences)
    /// et le relance, comme au premier lancement. Absent des versions publiées.
    @MainActor
    enum DevReset {
        static func resetAndRelaunch() {
            if let identifier = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: identifier)
            }
            relaunch()
        }

        /// Relance l'app un instant après qu'elle s'est fermée. Hors d'un `.app` (`swift run`), elle se ferme seulement.
        private static func relaunch() {
            let bundlePath = Bundle.main.bundlePath
            if bundlePath.hasSuffix(".app") {
                let relauncher = Process()
                relauncher.executableURL = URL(fileURLWithPath: "/bin/sh")
                relauncher.arguments = ["-c", "sleep 0.5; /usr/bin/open \"$0\"", bundlePath]
                try? relauncher.run()
            }
            NSApp.terminate(nil)
        }
    }
#endif
