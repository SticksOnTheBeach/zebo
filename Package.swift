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
        .executableTarget(name: "Zebo", dependencies: ["ZeboCore"]),
    ]
)
