import AppKit
import SwiftUI

struct NotchView: View {
    let model: NotchModel

    private var size: CGSize { model.isOpen ? model.openSize : model.closedSize }
    private var bottomRadius: CGFloat { model.isOpen ? 28 : 12 }

    var body: some View {
        NotchShape(bottomRadius: bottomRadius)
            .fill(.black)
            .frame(width: size.width, height: size.height)
            .overlay(alignment: .topLeading) {
                ZStack(alignment: .topLeading) {
                    if model.isOpen {
                        openText
                            .transition(.opacity.combined(with: .offset(x: -12)))
                    }

                    // Un seul Zebo : il glisse et grandit de l'aile gauche jusqu'à sa place.
                    AnimatedZebo(mouse: model.mouseLocation, center: zeboScreenCenter, isAwake: model.isOpen)
                        .frame(width: zeboFrame.width, height: zeboFrame.height)
                        .offset(x: zeboFrame.minX, y: zeboFrame.minY)
                }
            }
            .clipShape(NotchShape(bottomRadius: bottomRadius))
            .contextMenu {
                Button("Quitter Zebo") { NSApp.terminate(nil) }
            }
            // La fenêtre est plus grande que la notch : on colle le dessin en haut.
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    /// Place de Zebo dans la notch : petit dans l'aile gauche, grand à gauche une fois ouverte.
    private var zeboFrame: CGRect {
        let closedHeight = model.closedSize.height
        if model.isOpen {
            let side: CGFloat = 96
            let y = closedHeight + (model.openSize.height - closedHeight - side) / 2
            return CGRect(x: 32, y: y, width: side, height: side)
        } else {
            let side: CGFloat = 22
            return CGRect(x: NotchShape.topRadius + 4, y: (closedHeight - side) / 2,
                          width: side, height: side)
        }
    }

    /// Centre de Zebo en coordonnées écran, pour savoir dans quelle direction regarder.
    private var zeboScreenCenter: CGPoint {
        // La notch est centrée en haut de la fenêtre.
        let notchMinX = model.panelFrame.midX - size.width / 2
        return CGPoint(x: notchMinX + zeboFrame.midX,
                       y: model.panelFrame.maxY - zeboFrame.midY)
    }

    /// Texte provisoire à droite de Zebo : le chat viendra ici.
    private var openText: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Salut, moi c'est Zebo !")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Bientôt on pourra discuter 👋")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        // Le haut est caché par l'encoche physique : on démarre en dessous.
        .padding(.top, model.closedSize.height)
        .padding(.leading, 32 + 96 + 20)
    }
}

/// Forme d'encoche : petits arrondis concaves en haut, coins arrondis en bas.
struct NotchShape: Shape {
    static let topRadius: CGFloat = 6
    var bottomRadius: CGFloat = 12

    // Permet à SwiftUI d'animer l'arrondi pendant l'ouverture.
    var animatableData: CGFloat {
        get { bottomRadius }
        set { bottomRadius = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let top = Self.topRadius
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.minX + top, y: rect.minY + top),
                       control: CGPoint(x: rect.minX + top, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX + top, y: rect.maxY - bottomRadius))
        p.addQuadCurve(to: CGPoint(x: rect.minX + top + bottomRadius, y: rect.maxY),
                       control: CGPoint(x: rect.minX + top, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX - top - bottomRadius, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX - top, y: rect.maxY - bottomRadius),
                       control: CGPoint(x: rect.maxX - top, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX - top, y: rect.minY + top))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY),
                       control: CGPoint(x: rect.maxX - top, y: rect.minY))
        p.closeSubpath()
        return p
    }
}
