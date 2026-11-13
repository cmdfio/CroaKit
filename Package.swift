// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CroaKit",
    defaultLocalization: "fr",
    platforms: [.iOS(.v18), .macOS(.v15), .visionOS(.v2)],
    products: [.library(name: "CroaKit", targets: ["CroaKit"])],
    targets: [
        .target(name: "CroaKit", resources: [.process("Resources")]),
        .testTarget(name: "CroaKitTests", dependencies: ["CroaKit"])
    ]
)
