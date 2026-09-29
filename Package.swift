// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-email-standard",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(
            name: "Email Standard",
            targets: ["Email Standard"]
        ),
        .library(
            name: "Email Foundation Integration",
            targets: ["Email Foundation Integration"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-standards/swift-emailaddress-standard.git",
            branch: "main"
        ),
        .package(url: "https://github.com/swift-ietf/swift-rfc-2045.git", branch: "main"),
        .package(url: "https://github.com/swift-ietf/swift-rfc-2045-coder.git", branch: "main"),
        .package(url: "https://github.com/swift-ietf/swift-rfc-2046.git", branch: "main"),
        .package(url: "https://github.com/swift-ietf/swift-rfc-2046-coder.git", branch: "main"),
        .package(url: "https://github.com/swift-ietf/swift-rfc-4648.git", branch: "main"),
        .package(url: "https://github.com/swift-ietf/swift-rfc-5322.git", branch: "main"),
        .package(url: "https://github.com/swift-ietf/swift-rfc-5322-coder.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-ascii.git", branch: "main", traits: ["Coder", "Parser", "Serializer"]),
        .package(url: "https://github.com/swift-atoms/swift-byte.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-binary.git", branch: "main", traits: ["Serializer"]),
    ],
    targets: [
        .target(
            name: "Email Standard",
            dependencies: [
                .product(name: "EmailAddress Standard", package: "swift-emailaddress-standard"),
                .product(name: "RFC 2045", package: "swift-rfc-2045"),
                .product(name: "RFC 2045 Coder", package: "swift-rfc-2045-coder"),
                .product(name: "RFC 2046", package: "swift-rfc-2046"),
                .product(name: "RFC 2046 Coder", package: "swift-rfc-2046-coder"),
                .product(name: "RFC 4648", package: "swift-rfc-4648"),
                .product(name: "RFC 5322", package: "swift-rfc-5322"),
                .product(name: "ASCII", package: "swift-ascii"),
                .product(name: "Byte", package: "swift-byte"),
            ]
        ),
        .target(
            name: "Email Foundation Integration",
            dependencies: [
                .target(name: "Email Standard"),
                .product(name: "EmailAddress Standard", package: "swift-emailaddress-standard"),
                .product(
                    name: "EmailAddress Foundation Integration",
                    package: "swift-emailaddress-standard"
                ),
                .product(name: "RFC 2045", package: "swift-rfc-2045"),
                .product(name: "RFC 2045 Foundation Integration", package: "swift-rfc-2045"),
                .product(name: "RFC 2046", package: "swift-rfc-2046"),
                .product(name: "RFC 2046 Foundation Integration", package: "swift-rfc-2046"),
                .product(name: "RFC 5322", package: "swift-rfc-5322"),
                .product(name: "RFC 5322 Foundation Integration", package: "swift-rfc-5322"),
                .product(name: "Byte", package: "swift-byte"),
            ]
        ),
        .testTarget(
            name: "Email Standard Tests",
            dependencies: [
                .target(name: "Email Standard"),
                .product(name: "EmailAddress Standard", package: "swift-emailaddress-standard"),
                .product(name: "RFC 2046", package: "swift-rfc-2046"),
                .product(name: "RFC 5322", package: "swift-rfc-5322"),
                .product(name: "RFC 5322 Coder", package: "swift-rfc-5322-coder"),
                .product(name: "Byte", package: "swift-byte"),
                .product(name: "Byte", package: "swift-byte"),
                .product(name: "Binary", package: "swift-binary"),
            ]
        ),
        .testTarget(
            name: "Email Foundation Integration Tests",
            dependencies: [
                .target(name: "Email Standard"),
                .target(name: "Email Foundation Integration"),
                .product(name: "EmailAddress Standard", package: "swift-emailaddress-standard"),
                .product(name: "RFC 2046", package: "swift-rfc-2046"),
                .product(name: "RFC 5322", package: "swift-rfc-5322"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
