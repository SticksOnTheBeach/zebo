import SwiftUI

/// Une ligne de réglage : une icône sur sa couleur, un titre, une explication, et à droite
/// ce qui se règle (un bouton, un interrupteur…).
struct SettingsRow<Accessory: View>: View {
    let symbol: String
    let color: Color
    let title: String
    let detail: String
    @ViewBuilder var accessory: Accessory

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(color.gradient))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.system(size: 11.5, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            accessory
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

/// Des lignes de réglage regroupées sur un même fond, séparées par un trait fin.
struct SettingsGroup<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.white.opacity(0.07)))
    }
}

/// Le trait entre deux lignes, aligné sur les titres.
struct SettingsDivider: View {
    var body: some View {
        Divider()
            .overlay(.white.opacity(0.06))
            .padding(.leading, 58)
    }
}
