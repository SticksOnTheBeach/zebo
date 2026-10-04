import SwiftUI

/// Le personnage : un petit nuage rose, dessiné en formes SwiftUI.
/// Il s'adapte à la taille qu'on lui donne (tout est calculé sur une grille de 100 × 100).
struct ZeboCharacter: View {
    /// Direction du regard, de -1 à 1 sur chaque axe (0,0 = regarde droit devant).
    var look: CGPoint = .zero
    /// 1 = yeux grands ouverts, 0 = fermés.
    var eyeOpenness: CGFloat = 1
    /// Inclinaison de la tête (pivote autour de la base du nuage).
    var headTilt: Angle = .zero

    private static let cloudTop = Color(red: 1.00, green: 0.91, blue: 0.95)
    private static let cloudBottom = Color(red: 0.99, green: 0.78, blue: 0.87)
    private static let blush = Color(red: 0.96, green: 0.42, blue: 0.60)
    private static let ink = Color(red: 0.24, green: 0.13, blue: 0.20)

    var body: some View {
        GeometryReader { geo in
            // 1 unité = 1/100 de la taille disponible.
            let u = min(geo.size.width, geo.size.height) / 100

            ZStack {
                CloudShape()
                    .fill(LinearGradient(colors: [Self.cloudTop, Self.cloudBottom],
                                         startPoint: .top, endPoint: .bottom))

                // Le visage glisse vers le regard : le nuage a l'air de tourner.
                ZStack {
                    cheek(u).offset(x: -29 * u, y: 24 * u)
                    cheek(u).offset(x: 29 * u, y: 24 * u)

                    eye(u).offset(x: -17 * u, y: 8 * u)
                    eye(u).offset(x: 17 * u, y: 8 * u)

                    Smile()
                        .stroke(Self.ink, style: StrokeStyle(lineWidth: 3 * u, lineCap: .round))
                        .frame(width: 11 * u, height: 4.5 * u)
                        .offset(y: 30 * u)
                }
                .offset(x: look.x * 4 * u, y: look.y * 3 * u)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .rotationEffect(headTilt, anchor: .bottom)
        }
    }

    private func cheek(_ u: CGFloat) -> some View {
        Ellipse()
            .fill(Self.blush.opacity(0.45))
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

/// Silhouette de nuage : un socle arrondi surmonté de bosses, fusionnés en une seule forme.
private struct CloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        // Mêmes coordonnées que le personnage : grille 100 × 100 centrée.
        let u = min(rect.width, rect.height) / 100
        let center = CGPoint(x: rect.midX, y: rect.midY)

        func circle(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat) -> CGRect {
            CGRect(x: center.x + (x - r) * u, y: center.y + (y - r) * u,
                   width: 2 * r * u, height: 2 * r * u)
        }

        var p = Path()
        // Socle
        p.addRoundedRect(in: CGRect(x: center.x - 46 * u, y: center.y - 4 * u,
                                    width: 92 * u, height: 46 * u),
                         cornerSize: CGSize(width: 23 * u, height: 23 * u),
                         style: .continuous)
        // Bosses (de gauche à droite)
        p.addEllipse(in: circle(-30, 2, 19))
        p.addEllipse(in: circle(-4, -14, 29))
        p.addEllipse(in: circle(27, -2, 21))
        return p
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
