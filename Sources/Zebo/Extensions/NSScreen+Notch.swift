import AppKit

extension NSScreen {
    /// L'écran qui a une encoche (l'écran intégré du MacBook), sinon l'écran principal.
    static var notchScreen: NSScreen? {
        screens.first { $0.hasNotch } ?? main
    }

    var hasNotch: Bool {
        safeAreaInsets.top > 0
    }

    /// Taille de l'encoche physique, ou d'une fausse notch si l'écran n'en a pas.
    var notchSize: CGSize {
        guard hasNotch,
              let left = auxiliaryTopLeftArea,
              let right = auxiliaryTopRightArea
        else {
            let menuBarHeight = frame.maxY - visibleFrame.maxY
            return CGSize(width: 190, height: max(menuBarHeight, 24))
        }
        return CGSize(width: frame.width - left.width - right.width,
                      height: safeAreaInsets.top)
    }
}
