// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Zebo",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Zebo", targets: ["Zebo"])
    ],
    targets: [
        // Logique pure et état observable : ni SwiftUI ni AppKit.
        .target(name: "ZeboCore"),
        // Vues SwiftUI : le personnage, la notch, la bulle, la chute.
        .target(
            name: "ZeboUI",
            dependencies: ["ZeboCore"],
            // Logos des langages (Devicon, licence MIT).
            resources: [.copy("Resources/Languages")]
        ),
        // L'app : fenêtres AppKit, souris, écrans.
        .executableTarget(name: "Zebo", dependencies: ["ZeboCore", "ZeboUI"]),
        .testTarget(name: "ZeboCoreTests", dependencies: ["ZeboCore"]),
    ]
)
