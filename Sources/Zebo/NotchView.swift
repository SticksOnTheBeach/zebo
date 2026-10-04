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
            .overlay {
                if model.isOpen {
                    openContent
                        .transition(.opacity.combined(with: .scale(scale: 0.85, anchor: .top)))
                } else {
                    closedContent
                        .transition(.opacity)
                }
            }
            .clipShape(NotchShape(bottomRadius: bottomRadius))
            .contextMenu {
                Button("Quitter Zebo") { NSApp.terminate(nil) }
            }
            // La fenêtre est plus grande que la notch : on colle le dessin en haut.
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    /// Notch fermée : juste un petit indice dans l'aile gauche.
    private var closedContent: some View {
        Text("👀")
            .font(.system(size: 13))
            .padding(.leading, NotchShape.topRadius + 8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Notch ouverte : provisoire, le personnage et le chat viendront ici.
    private var openContent: some View {
        VStack(spacing: 8) {
            Text("👀")
                .font(.system(size: 48))
            Text("Salut, moi c'est Zebo !")
                .font(.headline)
                .foregroundStyle(.white)
        }
        // Le haut est caché par l'encoche physique : on démarre en dessous.
        .padding(.top, model.closedSize.height)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
