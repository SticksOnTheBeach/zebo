import AppKit

/// Barre des menus, visible quand Zebo est une app « normale » (quand une de ses fenêtres est ouverte).
@MainActor
enum MainMenu {
    static func make() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(submenu: appMenu())
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
