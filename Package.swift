// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LumiThemePack",
    defaultLocalization: "en",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "LumiThemePack", targets: ["LumiThemePack"])
    ],
    dependencies: [
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.7.0"),
        .package(url: "https://github.com/CofficLab/LumiProviders.git", from: "1.0.2")
    ],
    targets: [
        .target(
            name: "LumiThemePack",
            dependencies: [
                .product(name: "LumiUI", package: "LumiUI"),
                .product(name: "ProviderTheme", package: "LumiProviders")
            ],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "LumiThemePackTests",
            dependencies: [
                "LumiThemePack",
                .product(name: "ProviderTheme", package: "LumiProviders")
            ],
            path: "Tests/LumiThemePackTests"
        )
    ]
)
