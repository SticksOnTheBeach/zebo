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
    /// Étourdi : yeux en spirale et étoiles qui tournent autour de la tête.
    var dizzy = false
    /// Rotation des spirales et des étoiles (on la fait avancer pour les animer).
    var dizzySpin: Angle = .zero
    /// Pensif (quand il parle) : sourcils levés, comme l'émoji 🤔.
    var thinking = false

    private static let cloudTop = Color(red: 1.00, green: 0.91, blue: 0.95)
    private static let cloudBottom = Color(red: 0.99, green: 0.78, blue: 0.87)
    private static let cloudShade = Color(red: 0.93, green: 0.62, blue: 0.75)
    private static let ink = Color(red: 0.24, green: 0.13, blue: 0.20)

    var body: some View {
        GeometryReader { geo in
            // 1 unité = 1/100 de la taille disponible.
            let u = min(geo.size.width, geo.size.height) / 100

            ZStack {
                // Couche plus foncée derrière : donne du volume, et part un peu
                // à l'opposé du regard (effet de profondeur).
                CloudShape()
                    .fill(Self.cloudShade)
                    .offset(x: -look.x * 2 * u, y: 3 * u)

                CloudShape()
                    .fill(LinearGradient(colors: [Self.cloudTop, Self.cloudBottom],
                                         startPoint: .top, endPoint: .bottom))

                // Le visage glisse vers le regard : le nuage a l'air de tourner.
                ZStack {
                    // Pas de pupilles : ce sont les yeux entiers qui suivent le regard.
                    Group {
                        eye(u).offset(x: -13 * u, y: 10 * u)
                        eye(u).offset(x: 13 * u, y: 10 * u)

                        if thinking && !dizzy {
                            // Un sourcil bien haut, l'autre plus bas et penché : il se demande quelque chose.
                            Brow()
                                .stroke(Self.ink, style: StrokeStyle(lineWidth: 2.6 * u, lineCap: .round))
                                .frame(width: 10 * u, height: 4 * u)
                                .rotationEffect(.degrees(-14))
                                .offset(x: -13 * u, y: -7 * u)
                            Brow()
                                .stroke(Self.ink, style: StrokeStyle(lineWidth: 2.6 * u, lineCap: .round))
                                .frame(width: 10 * u, height: 1.5 * u)
                                .rotationEffect(.degrees(18))
                                .offset(x: 13 * u, y: 1 * u)
                        }
                    }
                    .offset(x: look.x * 5 * u, y: look.y * 4 * u)

                    if dizzy {
                        // Bouche en « o » : il est sonné.
                        Ellipse()
                            .stroke(Self.ink, lineWidth: 2.5 * u)
                            .frame(width: 7 * u, height: 8 * u)
                            .offset(y: 28 * u)
                    } else if thinking {
                        // Moue « hmm » un peu de travers.
                        Hmm()
                            .stroke(Self.ink, style: StrokeStyle(lineWidth: 3 * u, lineCap: .round))
                            .frame(width: 10 * u, height: 3 * u)
                            .rotationEffect(.degrees(-8))
                            .offset(x: -1 * u, y: 25.5 * u)

                        hand(u)
                    } else {
                        Smile()
                            .stroke(Self.ink, style: StrokeStyle(lineWidth: 3 * u, lineCap: .round))
                            .frame(width: 10 * u, height: 4 * u)
                            .offset(y: 27 * u)
                    }
                }
                .offset(x: look.x * 4 * u, y: look.y * 3 * u)

                if dizzy {
                    stars(u)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .rotationEffect(headTilt, anchor: .bottom)
        }
    }

    /// Petit œil ovale noir ; en clignant, il s'aplatit jusqu'à devenir un trait.
    /// Étourdi, il devient une spirale qui tourne.
    @ViewBuilder
    private func eye(_ u: CGFloat) -> some View {
        if dizzy {
            Spiral()
                .stroke(Self.ink, style: StrokeStyle(lineWidth: 2.2 * u, lineCap: .round))
                .frame(width: 15 * u, height: 15 * u)
                .rotationEffect(dizzySpin)
        } else {
            Capsule()
                .fill(Self.ink)
                .frame(width: 8 * u, height: max(13 * eyeOpenness, 2.5) * u)
        }
    }

    /// Petite main-nuage, comme l'émoji 🤔 : elle monte d'en bas à gauche, le pouce levé,
    /// trois doigts repliés et l'index en diagonale jusque sous le menton.
    private func hand(_ u: CGFloat) -> some View {
        ZStack {
            // Pouce : un petit bout replié sur le haut de la main.
            handPart(Capsule(), u)
                .frame(width: 5 * u, height: 7 * u)
                .rotationEffect(.degrees(40))
                .offset(x: -18.5 * u, y: 34.5 * u)
            // Dos de la main.
            handPart(RoundedRectangle(cornerRadius: 4.5 * u, style: .continuous), u)
                .frame(width: 10 * u, height: 13 * u)
                .rotationEffect(.degrees(-8))
                .offset(x: -21 * u, y: 40 * u)
            // Trois doigts repliés, empilés et de plus en plus courts.
            ForEach((0..<3).reversed(), id: \.self) { i in
                let row = CGFloat(i)
                handPart(Capsule(), u)
                    .frame(width: (10 - row * 1.5) * u, height: 4.2 * u)
                    .offset(x: (-15.5 - row) * u, y: (38 + row * 3.6) * u)
            }
            // Index tendu vers le menton.
            handPart(Capsule(), u)
                .frame(width: 17 * u, height: 4.6 * u)
                .rotationEffect(.degrees(-27))
                .offset(x: -9.5 * u, y: 34 * u)
        }
        // Un peu plus grande, en gardant le bout de l'index sous le menton
        // (le cadre 100 × 100 sert de repère à l'ancre).
        .frame(width: 100 * u, height: 100 * u)
        .scaleEffect(1.2, anchor: UnitPoint(x: 0.48, y: 0.8))
        .offset(y: -1.5 * u)
    }

    /// Un morceau de main : rempli comme le nuage, cerné de rose foncé.
    private func handPart(_ shape: some Shape, _ u: CGFloat) -> some View {
        shape
            .fill(LinearGradient(colors: [Self.cloudTop, Self.cloudBottom],
                                 startPoint: .top, endPoint: .bottom))
            .overlay(shape.stroke(Self.cloudShade, lineWidth: 1.3 * u))
    }

    /// Trois étoiles qui tournent en rond au-dessus de la tête.
    private func stars(_ u: CGFloat) -> some View {
        ForEach(0..<3, id: \.self) { i in
            let angle = dizzySpin.radians + Double(i) * 2 * .pi / 3
            // Plus petites quand elles passent « derrière » la tête : effet de perspective.
            let depth = 0.75 + 0.25 * sin(angle)
            StarShape()
                .fill(Color(red: 1.0, green: 0.84, blue: 0.3))
                .frame(width: 11 * u, height: 11 * u)
                .scaleEffect(depth)
                .offset(x: cos(angle) * 34 * u, y: (-44 + sin(angle) * 7) * u)
        }
    }
}

/// Spirale (yeux étourdis).
private struct Spiral: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let maxRadius = min(rect.width, rect.height) / 2
        let turns: CGFloat = 2.5
        let steps = 60
        var p = Path()
        for i in 0...steps {
            let f = CGFloat(i) / CGFloat(steps)
            let angle = f * turns * 2 * .pi
            let point = CGPoint(x: center.x + cos(angle) * f * maxRadius,
                                y: center.y + sin(angle) * f * maxRadius)
            if i == 0 { p.move(to: point) } else { p.addLine(to: point) }
        }
        return p
    }
}

/// Étoile à 5 branches.
private struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.45
        var p = Path()
        for i in 0..<10 {
            let radius = i.isMultiple(of: 2) ? outer : inner
            let angle = -CGFloat.pi / 2 + CGFloat(i) * .pi / 5
            let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            if i == 0 { p.move(to: point) } else { p.addLine(to: point) }
        }
        p.closeSubpath()
        return p
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

/// Sourcil : un arc bombé vers le haut.
private struct Brow: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY),
                       control: CGPoint(x: rect.midX, y: rect.minY - rect.height))
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

/// Moue pensive : un arc bombé vers le haut, plus marqué d'un côté.
private struct Hmm: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY - rect.height * 0.3),
                       control: CGPoint(x: rect.midX - rect.width * 0.15, y: rect.minY - rect.height * 0.6))
        return p
    }
}
