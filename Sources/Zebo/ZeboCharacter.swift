import SwiftUI

/// Le personnage, dessiné en formes SwiftUI.
/// Il s'adapte à la taille qu'on lui donne (tout est calculé sur une grille de 100 × 100).
struct ZeboCharacter: View {
    /// Direction du regard, de -1 à 1 sur chaque axe (0,0 = regarde droit devant).
    var look: CGPoint = .zero
    /// 1 = yeux grands ouverts, 0 = fermés.
    var eyeOpenness: CGFloat = 1
    /// Inclinaison de la tête (pivote autour du menton).
    var headTilt: Angle = .zero

    private static let skinTop = Color(red: 0.56, green: 0.95, blue: 0.79)
    private static let skinBottom = Color(red: 0.25, green: 0.76, blue: 0.63)
    private static let ink = Color(red: 0.10, green: 0.12, blue: 0.16)

    var body: some View {
        GeometryReader { geo in
            // 1 unité = 1/100 de la taille disponible.
            let u = min(geo.size.width, geo.size.height) / 100

            ZStack {
                ear(u).offset(x: -30 * u, y: -38 * u)
                ear(u).offset(x: 30 * u, y: -38 * u)

                RoundedRectangle(cornerRadius: 40 * u, style: .continuous)
                    .fill(LinearGradient(colors: [Self.skinTop, Self.skinBottom],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: 96 * u, height: 84 * u)
                    .offset(y: 6 * u)

                // Le visage glisse vers le regard : la tête a l'air de tourner.
                ZStack {
                    cheek(u).offset(x: -31 * u, y: 21 * u)
                    cheek(u).offset(x: 31 * u, y: 21 * u)

                    eye(u).offset(x: -19 * u)
                    eye(u).offset(x: 19 * u)

                    Smile()
                        .stroke(Self.ink, style: StrokeStyle(lineWidth: 3 * u, lineCap: .round))
                        .frame(width: 12 * u, height: 5 * u)
                        .offset(y: 27 * u)
                }
                .offset(x: look.x * 4 * u, y: look.y * 3 * u)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .rotationEffect(headTilt, anchor: .bottom)
        }
    }

    private func ear(_ u: CGFloat) -> some View {
        Circle()
            .fill(Self.skinBottom)
            .frame(width: 22 * u, height: 22 * u)
    }

    private func cheek(_ u: CGFloat) -> some View {
        Ellipse()
            .fill(Color.pink.opacity(0.55))
            .frame(width: 13 * u, height: 7 * u)
    }

    private func eye(_ u: CGFloat) -> some View {
        ZStack {
            eyeball(u)
                // Clignement : l'œil s'écrase verticalement…
                .scaleEffect(x: 1, y: max(eyeOpenness, 0.05))
                .opacity(eyeOpenness < 0.15 ? 0 : 1)

            // …et devient un petit trait une fois fermé.
            Capsule()
                .fill(Self.ink)
                .frame(width: 20 * u, height: 3.5 * u)
                .opacity(eyeOpenness < 0.15 ? 1 : 0)
        }
    }

    private func eyeball(_ u: CGFloat) -> some View {
        ZStack {
            Ellipse()
                .fill(.white)
                .frame(width: 26 * u, height: 30 * u)

            // Pupille + petit reflet, déplacés selon le regard.
            Circle()
                .fill(Self.ink)
                .frame(width: 14 * u, height: 14 * u)
                .overlay {
                    Circle()
                        .fill(.white)
                        .frame(width: 4 * u, height: 4 * u)
                        .offset(x: 2.5 * u, y: -2.5 * u)
                }
                .offset(x: look.x * 5 * u, y: look.y * 7 * u)
        }
        // La pupille ne sort jamais du blanc de l'œil.
        .clipShape(Ellipse())
    }
}

/// Petit sourire en arc.
private struct Smile: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY),
                       control: CGPoint(x: rect.midX, y: rect.maxY * 2))
        return p
    }
}
