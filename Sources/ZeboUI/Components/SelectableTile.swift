import SwiftUI

/// Une tuile qu'on choisit d'un clic : une icône, un nom ; entourée et cochée quand elle est choisie.
struct SelectableTile<Icon: View>: View {
    let title: String
    let isSelected: Bool
    var accent: Color = ZeboPalette.cloudBottom
    var isDimmed = false
    let onSelect: () -> Void
    @ViewBuilder var icon: Icon

    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 7) {
            icon
                .frame(width: 38, height: 38)
                .scaleEffect(isSelected ? 1.08 : 1)
            Text(title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 82)
        .opacity(isDimmed && !isSelected ? 0.45 : 1)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white.opacity(isSelected ? 0.14 : (isHovered ? 0.09 : 0.05)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(isSelected ? accent : .white.opacity(0.07), lineWidth: isSelected ? 2 : 1)
        )
        .overlay(alignment: .topTrailing) {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(accent)
                    .padding(6)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .scaleEffect(isHovered && !isSelected ? 1.04 : 1)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isSelected)
    }
}
