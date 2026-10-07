import Foundation

/// Les garde-fous de Zebo quand il code : il reste dans le dossier du projet, et certaines commandes
/// sont refusées quoi qu'il arrive. Ce n'est pas un bac à sable : les commandes demandent ton accord,
/// sauf si tu les autorises dans les paramètres.
public enum CodingSafety {
    /// Un chemin relatif au projet, qui ne peut pas en sortir.
    public static func checkedPath(_ path: String, allowsRoot: Bool = false) throws(ZeboActionError) -> String {
        var path = path.trimmingCharacters(in: .whitespacesAndNewlines)
        while path.hasPrefix("./") { path.removeFirst(2) }
        if path == "." { path = "" }
        if path.isEmpty {
            guard allowsRoot else { throw ZeboActionError("Il me faut le chemin du fichier.") }
            return ""
        }
        let components = path.split(separator: "/", omittingEmptySubsequences: true)
        guard !path.hasPrefix("/"), !path.hasPrefix("~"), !components.contains("..") else {
            throw ZeboActionError("« \(path) » sort du projet : je reste dans son dossier.")
        }
        return components.joined(separator: "/")
    }

    /// Ce qu'aucune commande de Zebo ne fait, même autorisée.
    static let forbidden: [(pattern: String, reason: String)] = [
        (#"(^|[\s;&|(])sudo\s"#, "sudo"),
        (#"rm\s+(-[a-zA-Z]*\s+)*(/|~|\$HOME)(\s|$|/\*)"#, "effacer le disque ou ton dossier personnel"),
        (#"(^|[\s;&|])(shutdown|reboot|halt|mkfs|diskutil\s+erase)"#, "toucher au système"),
        (#":\(\)\s*\{"#, "une bombe à processus"),
        (#">\s*/dev/(disk|rdisk)"#, "écrire sur un disque"),
        (
            #"(^|[\s;&|])(npm|pnpm|yarn|bun)\s+(run\s+)?(dev|start|serve|preview)(\s|$)"#,
            "un serveur qui ne s'arrête jamais (lance-le toi-même)"
        ),
    ]

    public static func checkedCommand(_ command: String) throws(ZeboActionError) -> String {
        let command = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !command.isEmpty else { throw ZeboActionError("Il me faut une commande à lancer.") }
        for rule in forbidden where command.range(of: rule.pattern, options: .regularExpression) != nil {
            throw ZeboActionError("Je ne lance pas ça : \(rule.reason).")
        }
        return command
    }
}
