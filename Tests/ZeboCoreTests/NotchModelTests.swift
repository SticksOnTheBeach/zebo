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
}
