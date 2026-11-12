// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "JimakuCore",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "JimakuCore", targets: ["JimakuCore"])
    ],
    targets: [
        .target(name: "JimakuCore"),
        .testTarget(name: "JimakuCoreTests", dependencies: ["JimakuCore"]),
    ]
)
