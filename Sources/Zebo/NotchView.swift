import AppKit
import SwiftUI

struct NotchView: View {
    var body: some View {
        NotchShape()
            .fill(.black)
            .overlay(alignment: .leading) {
                // Emplacement provisoire : Zebo viendra se loger ici.
                Text("👀")
                    .font(.system(size: 13))
                    .padding(.leading, NotchShape.topRadius + 8)
            }
            .contextMenu {
                Button("Quitter Zebo") { NSApp.terminate(nil) }
            }
    }
}

/// Forme d'encoche : petits arrondis concaves en haut, coins arrondis en bas.
struct NotchShape: Shape {
    static let topRadius: CGFloat = 6
    var bottomRadius: CGFloat = 12

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
