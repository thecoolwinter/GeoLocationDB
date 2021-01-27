// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GeoLocationDB",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(
            name: "GeoLocationDB",
            targets: ["GeoLocationDB"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/redis.git", from: "4.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "GeoLocationDB",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Redis", package: "redis")
            ]),
        .testTarget(
            name: "GeoLocationDBTests",
            dependencies: ["GeoLocationDB"]),
    ]
)
