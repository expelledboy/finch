// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Finch",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Finch",
            path: "Sources/Finch",
            linkerSettings: [
                .linkedFramework("JavaScriptCore"),
                .linkedFramework("AppKit"),
            ]
        )
    ]
)
