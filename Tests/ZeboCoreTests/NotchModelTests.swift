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

    @Test("Notch fermée, Zebo dort sous l'encoche physique", arguments: [24, 32, 38] as [CGFloat])
    func closedZeboIsBelowHardwareNotch(notchHeight: CGFloat) {
        let model = makeModel(isOpen: false, notchHeight: notchHeight)
        #expect(model.zeboFrame.minY >= notchHeight)
        #expect(model.zeboFrame.maxY <= model.closedSize.height)
    }

    @Test("Notch fermée, Zebo est au milieu")
    func closedZeboIsCentered() {
        let model = makeModel(isOpen: false)
        #expect(abs(model.zeboFrame.midX - model.closedSize.width / 2) < 0.001)
    }

    @Test("Notch fermée, le bandeau s'ajoute sous l'encoche")
    func closedNotchAddsSleepBand() {
        let model = makeModel(isOpen: false)
        #expect(model.closedSize.height == 32 + NotchModel.sleepBandHeight)
    }

    @Test("Notch ouverte, Zebo est sous l'encoche physique")
    func openZeboIsBelowPhysicalNotch() {
        let model = makeModel(isOpen: true)
        #expect(model.zeboFrame.minY >= model.hardwareNotchSize.height)
        #expect(model.zeboFrame.maxY <= model.openSize.height)
    }
}
