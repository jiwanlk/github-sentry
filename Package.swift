// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GitHubSentry",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "GitHubSentry",
            path: "Sources"
        )
    ]
)
