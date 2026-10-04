// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Zebo",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "Zebo", path: "Sources/Zebo")
    ]
)
