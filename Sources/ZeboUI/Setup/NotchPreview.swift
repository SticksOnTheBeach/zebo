import SwiftUI

/// Aperçu de la notch fermée, vue de près sur un bout d'écran : Zebo (endormi dans son lit
/// ou éveillé) à gauche, l'heure à droite si elle est affichée.
struct NotchPreview: View {
    var showsClock: Bool
    var sleeps: Bool

    var body: some View {
        ZStack(alignment: .top) {
            // Un bout de fond d'écran, et la barre des menus.
            LinearGradient(
                colors: [Color(red: 0.22, green: 0.2, blue: 0.48), Color(red: 0.78, green: 0.42, blue: 0.6)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
            Rectangle()
                .fill(.black.opacity(0.25))
                .frame(height: 44)
            notch
        }
        .frame(height: 96)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.white.opacity(0.08)))
    }

    private var notch: some View {
        NotchShape(bottomRadius: 14)
            .fill(.black)
            .frame(width: 380, height: 44)
            .overlay(alignment: .leading) {
                InBed(isAsleep: sleeps) {
                    ZeboCharacter(mood: sleeps ? .sleeping : .calm)
                }
                .overlay { SleepingZs(isActive: sleeps) }
                .frame(width: 58, height: 38)
                .padding(.leading, 12)
            }
            .overlay(alignment: .trailing) {
                if showsClock {
                    Text("09:41")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .padding(.trailing, 18)
                        .transition(.opacity)
                }
            }
    }
}
