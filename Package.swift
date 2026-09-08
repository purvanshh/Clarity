// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Clarity",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Clarity", targets: ["Clarity"])
    ],
    targets: [
        .executableTarget(
            name: "Clarity",
            path: "Clarity",
            exclude: [
                "Info.plist",
                "Clarity.entitlements"
            ],
            resources: [
                .process("Assets.xcassets")
            ]
        )
    ]
)
