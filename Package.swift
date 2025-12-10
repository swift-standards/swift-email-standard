// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-email-standard",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26)
    ],
    products: [
        .library(
            name: "Email Standard",
            targets: ["Email Standard"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swift-standards/swift-emailaddress-standard", from: "0.4.0"),
        .package(url: "https://github.com/swift-standards/swift-rfc-2045", from: "0.3.0"),
        .package(url: "https://github.com/swift-standards/swift-rfc-2046", from: "0.3.0"),
        .package(url: "https://github.com/swift-standards/swift-rfc-4648", from: "0.3.0"),
        .package(url: "https://github.com/swift-standards/swift-rfc-5322", from: "0.6.0")
    ],
    targets: [
        .target(
            name: "Email Standard",
            dependencies: [
                .product(name: "EmailAddress Standard", package: "swift-emailaddress-standard"),
                .product(name: "RFC 2045", package: "swift-rfc-2045"),
                .product(name: "RFC 2046", package: "swift-rfc-2046"),
                .product(name: "RFC 4648", package: "swift-rfc-4648"),
                .product(name: "RFC 5322", package: "swift-rfc-5322")
            ]
        ),
        .testTarget(
            name: "Email Standard".tests,
            dependencies: ["Email Standard"]
        )
    ],
    swiftLanguageModes: [.v6]
)

extension String {
    var tests: Self { self + " Tests" }
    var foundation: Self { self + " Foundation" }
}

for target in package.targets where ![.system, .binary, .plugin].contains(target.type) {
    let existing = target.swiftSettings ?? []
    target.swiftSettings = existing + [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility")
    ]
}
