// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CroaKit",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [.library(name: "CroaKit", targets: ["CroaKit"])],
    targets: [
        .target(name: "CroaKit", resources: [.process("Resources")]),
        .testTarget(name: "CroaKitTests", dependencies: ["CroaKit"])
    ]
)
