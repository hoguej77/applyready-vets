// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ApplyReadyVetsCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "ApplyReadyVetsCore", targets: ["ApplyReadyVetsCore"]),
    ],
    targets: [
        .target(name: "ApplyReadyVetsCore"),
        .testTarget(name: "ApplyReadyVetsCoreTests", dependencies: ["ApplyReadyVetsCore"]),
    ]
)
