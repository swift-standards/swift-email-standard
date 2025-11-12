// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "swift-email-type",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .tvOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "Email",
            targets: ["Email"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swift-standards/swift-emailaddress-type", from: "0.2.0"),
        .package(url: "https://github.com/swift-standards/swift-rfc-2045", from: "0.0.1"),
        .package(url: "https://github.com/swift-standards/swift-rfc-2046", from: "0.0.1")
    ],
    targets: [
        .target(
            name: "Email",
            dependencies: [
                .product(name: "EmailAddress", package: "swift-emailaddress-type"),
                .product(name: "RFC 2045", package: "swift-rfc-2045"),
                .product(name: "RFC 2046", package: "swift-rfc-2046")
            ]
        ),
        .testTarget(
            name: "Email Tests",
            dependencies: ["Email"]
        )
    ]
)

for target in package.targets {
    target.swiftSettings?.append(
        contentsOf: [
            .enableUpcomingFeature("MemberImportVisibility")
        ]
    )
}
