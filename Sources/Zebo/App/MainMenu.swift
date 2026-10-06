import AppKit

/// Barre des menus, visible quand Zebo est une app « normale » (quand une de ses fenêtres est ouverte).
@MainActor
enum MainMenu {
    static func make() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(submenu: appMenu())
        menu.addItem(submenu: editMenu())
        menu.addItem(submenu: windowMenu())
        return menu
    }

    private static func appMenu() -> NSMenu {
        let menu = NSMenu(title: "Zebo")
        menu.addItem(withTitle: "Réglages…", action: #selector(AppDelegate.showSettings(_:)), keyEquivalent: ",")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Masquer Zebo", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quitter Zebo", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        return menu
    }

    /// Sans lui, ⌘C, ⌘V… n'atteignent pas les champs de texte (une clé d'API se colle, elle ne se tape pas).
    private static func editMenu() -> NSMenu {
        let menu = NSMenu(title: "Édition")
        menu.addItem(withTitle: "Annuler", action: Selector(("undo:")), keyEquivalent: "z")
        menu.addItem(withTitle: "Rétablir", action: Selector(("redo:")), keyEquivalent: "Z")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Couper", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        menu.addItem(withTitle: "Copier", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        menu.addItem(withTitle: "Coller", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        menu.addItem(withTitle: "Tout sélectionner", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        return menu
    }

    private static func windowMenu() -> NSMenu {
        let menu = NSMenu(title: "Fenêtre")
        menu.addItem(withTitle: "Réduire", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        menu.addItem(withTitle: "Fermer", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        return menu
    }
}

extension NSMenu {
    fileprivate func addItem(submenu: NSMenu) {
        let item = NSMenuItem(title: submenu.title, action: nil, keyEquivalent: "")
        item.submenu = submenu
        addItem(item)
    }
}
