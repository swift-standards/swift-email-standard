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
        .package(path: "../swift-emailaddress-standard"),
        .package(path: "../swift-rfc-2045"),
        .package(path: "../swift-rfc-2046"),
        .package(path: "../swift-rfc-4648"),
        .package(path: "../swift-rfc-5322")
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
        )
    ],
    swiftLanguageModes: [.v6]
)

extension String {
    var tests: Self { self + " Tests" }
    var foundation: Self { self + " Foundation" }
}

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableExperimentalFeature("SuppressedAssociatedTypesWithDefaults"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
