import SwiftUI

@main
struct ZeboApp: App {
    var body: some Scene {
        WindowGroup {
            VStack(spacing: 12) {
                Text("👀")
                    .font(.system(size: 64))
                Text("Salut, moi c'est Zebo !")
                    .font(.title2)
            }
            .frame(width: 320, height: 200)
        }
    }
}
