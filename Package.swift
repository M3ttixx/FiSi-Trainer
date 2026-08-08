// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SysAdminLearn",
    platforms: [.macOS(.v14)],
    targets: [
        .target(
            name: "LearnCore",
            resources: [.copy("Content/Resources")]
        ),
        .executableTarget(
            name: "SysAdminLearn",
            dependencies: ["LearnCore"]
        ),
        .testTarget(
            name: "LearnCoreTests",
            dependencies: ["LearnCore"]
        ),
    ]
)
