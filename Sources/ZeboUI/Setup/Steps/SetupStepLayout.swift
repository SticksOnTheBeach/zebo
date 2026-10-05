import SwiftUI

/// Mise en page commune aux étapes : le titre (ce que dit Zebo) à droite de Zebo, un sous-titre,
/// puis le contenu de l'étape en dessous. Le titre arrive en premier, puis le sous-titre ;
/// le contenu fait arriver ses éléments à partir du rang 2.
struct SetupStepLayout<Content: View>: View {
    let title: String
    var subtitle: String?
    @ViewBuilder var content: Content

    private var zebo: CGRect { SetupWindowLayout.zeboFrame }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .appearing(order: 0)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(.white.opacity(0.65))
                        .appearing(order: 1)
                }
            }
            // Centré verticalement sur Zebo, comme s'il le disait.
            .frame(height: zebo.height, alignment: .leading)
            .padding(.leading, zebo.maxX + 20)
            .padding(.trailing, zebo.minX)
            .padding(.top, zebo.minY)

            content
                .padding(.horizontal, zebo.minX)
                .padding(.top, 28)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
