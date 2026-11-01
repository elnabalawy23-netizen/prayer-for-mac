// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "PrayerNotch",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/batoulapps/adhan-swift", from: "1.4.0")
    ],
    targets: [
        .executableTarget(
            name: "PrayerNotch",
            dependencies: [
                .product(name: "Adhan", package: "adhan-swift")
            ],
            path: "Sources/PrayerNotch"
        )
    ]
)
