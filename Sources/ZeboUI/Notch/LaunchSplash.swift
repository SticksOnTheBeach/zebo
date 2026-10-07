import SwiftUI

/// L'entrée en scène de Zebo au démarrage, dans la notch agrandie : il surgit avec un rebond,
/// son nom glisse à côté de lui, il dit bonjour et fait un clin d'œil. Puis il va se coucher.
struct LaunchSplash: View {
    /// Le prénom, pour dire bonjour (vide : pas encore configuré).
    let name: String

    @Environment(\.showsFinalAppearance) private var showsFinalAppearance
    @State private var hasPopped = false
    @State private var showsName = false
    @State private var showsGreeting = false
    @State private var isWinking = false

    var body: some View {
        HStack(spacing: 14) {
            ZeboCharacter(isWinking: isWinking)
                .frame(width: 64, height: 64)
                .scaleEffect(hasPopped ? 1 : 0.2)
                .rotationEffect(.degrees(hasPopped ? 0 : -25))
                .opacity(hasPopped ? 1 : 0)
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(ZeboPalette.star)
                        .scaleEffect(isWinking ? 1 : 0.1)
                        .opacity(isWinking ? 1 : 0)
                        .offset(x: 6, y: -2)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text("Zebo")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .offset(x: showsName ? 0 : -16)
                    .opacity(showsName ? 1 : 0)
                Text(greeting)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(ZeboPalette.cloudBottom)
                    .lineLimit(1)
                    .offset(y: showsGreeting ? 0 : 6)
                    .opacity(showsGreeting ? 1 : 0)
            }
        }
        .background {
            SparkleField(count: 18)
                .frame(width: 300, height: 100)
                .opacity(hasPopped ? 0.7 : 0)
        }
        .task { await play() }
    }

    private var greeting: String {
        name.isEmpty ? "Ton compagnon de code" : "Salut \(name), on code ?"
    }

    private func play() async {
        if showsFinalAppearance {
            hasPopped = true
            showsName = true
            showsGreeting = true
            return
        }
        try? await Task.sleep(for: .milliseconds(150))
        withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) { hasPopped = true }
        try? await Task.sleep(for: .milliseconds(300))
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { showsName = true }
        try? await Task.sleep(for: .milliseconds(250))
        withAnimation(.easeOut(duration: 0.35)) { showsGreeting = true }
        try? await Task.sleep(for: .milliseconds(450))
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { isWinking = true }
        try? await Task.sleep(for: .milliseconds(450))
        withAnimation(.easeOut(duration: 0.2)) { isWinking = false }
    }
}
