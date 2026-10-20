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
        // iOS 外观页用到 LumiUI 1.11.0 新增的设置组件（AppSettingCheckmarkRow
        // 等）与语义色，低于该版本无法编译。
        .package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.11.0"),
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
