import CoreGraphics
import Testing

@testable import ZeboCore

@MainActor
@Suite("Géométrie de la notch")
struct NotchModelTests {
    private func makeModel(isOpen: Bool, notchHeight: CGFloat = 32) -> NotchModel {
        let model = NotchModel()
        model.hardwareNotchSize = CGSize(width: 185, height: notchHeight)
        model.isOpen = isOpen
        return model
    }

    @Test("Notch fermée, Zebo tient dans l'aile gauche", arguments: [24, 32, 38] as [CGFloat])
    func closedZeboFitsInLeftWing(notchHeight: CGFloat) {
        let frame = makeModel(isOpen: false, notchHeight: notchHeight).zeboFrame
        #expect(frame.minX >= NotchModel.topCornerRadius)
        #expect(frame.maxX <= NotchModel.wingWidth)
        #expect(frame.minY >= 0)
        #expect(frame.maxY <= notchHeight)
    }

    @Test("Notch ouverte, Zebo est sous l'encoche physique")
    func openZeboIsBelowPhysicalNotch() {
        let model = makeModel(isOpen: true)
        #expect(model.zeboFrame.minY >= model.hardwareNotchSize.height)
        #expect(model.zeboFrame.maxY <= model.openSize.height)
    }

    @Test("La notch fermée, c'est l'encoche plus une aile de chaque côté")
    func closedSizeAddsWings() {
        let model = makeModel(isOpen: false)
        #expect(model.closedSize == CGSize(width: 185 + NotchModel.wingWidth * 2, height: 32))
    }

    @Test("La taille visible suit l'ouverture de la notch")
    func notchSizeFollowsIsOpen() {
        let model = makeModel(isOpen: false)
        #expect(model.notchSize == model.closedSize)
        model.isOpen = true
        #expect(model.notchSize == model.openSize)
    }

    @Test("Le centre de Zebo à l'écran tient compte de la notch centrée dans sa fenêtre")
    func zeboScreenCenterIsInScreenCoordinates() {
        let model = makeModel(isOpen: true)
        model.panelFrame = CGRect(x: 600, y: 900, width: 480, height: 180)
        let notchMinX = model.panelFrame.midX - model.openSize.width / 2
        #expect(model.zeboScreenCenter.x == notchMinX + model.zeboFrame.midX)
        // Origine de l'écran en bas : plus Zebo est bas dans la notch, plus y est petit.
        #expect(model.zeboScreenCenter.y == model.panelFrame.maxY - model.zeboFrame.midY)
    }

    @Test("Survolée, la notch fermée grandit un peu ; ouverte, elle prend toute sa taille")
    func peekingGrowsTheClosedNotch() {
        let model = makeModel(isOpen: false)
        model.isPeeking = true
        #expect(model.notchSize.width == model.closedSize.width + NotchModel.peekGrowth.width)
        #expect(model.notchSize.height == model.closedSize.height + NotchModel.peekGrowth.height)
        model.isOpen = true
        #expect(model.notchSize == model.openSize)
    }

    @Test("L'onglet IA agrandit la notch ouverte, sans dépasser sa fenêtre")
    func aiTabIsBigger() {
        let model = makeModel(isOpen: true)
        let standard = model.notchSize
        model.selectedTab = .ai
        #expect(model.notchSize.width > standard.width)
        #expect(model.notchSize.height > standard.height)
        #expect(model.notchSize.width <= NotchModel.largestOpenSize.width)
        #expect(model.notchSize.height <= NotchModel.largestOpenSize.height)
        #expect(model.zeboFrame.maxY <= model.openSize.height)
    }
}
