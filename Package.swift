// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "TeslaCamProcessor",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "TeslaCamProcessor", targets: ["TeslaCamProcessor"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "TeslaCamProcessor",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            linkerSettings: [
                .linkedFramework("Vision"),
                .linkedFramework("CoreML"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("CoreImage"),
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("CloudKit")
            ]
        ),
    ]
)