// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Kalk",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "KalkMath", resources: [.copy("Resources/math.min.js")]),
        .executableTarget(name: "Kalk", dependencies: ["KalkMath"], resources: [.copy("Web")]),
        .testTarget(name: "KalkMathTests", dependencies: ["KalkMath"]),
    ]
)
