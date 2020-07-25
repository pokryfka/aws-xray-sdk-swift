// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "aws-xray-sdk-swift",
    platforms: [
        .macOS(.v10_14),
    ],
    products: [
        .library(name: "AWSXRayRecorder", targets: ["AWSXRayRecorder"]),
        .library(name: "AWSXRayInstrument", targets: ["AWSXRayInstrument"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", .upToNextMajor(from: "2.17.0")),
        .package(url: "https://github.com/apple/swift-log.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/Flight-School/AnyCodable.git", .upToNextMajor(from: "0.3.0")),
        .package(name: "swift-baggage-context", url: "https://github.com/slashmo/gsoc-swift-baggage-context.git", .upToNextMajor(from: "0.1.0")),
        .package(url: "https://github.com/slashmo/gsoc-swift-tracing.git", .revision("8c641d3efa0951433fe67acf2d6af92ea1e528ad")),
    ],
    targets: [
        .target(
            name: "AWSXRayRecorder",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "AnyCodable", package: "AnyCodable"),
                .product(name: "Baggage", package: "swift-baggage-context"),
            ]
        ),
        .testTarget(
            name: "AWSXRayRecorderTests",
            dependencies: [
                .target(name: "AWSXRayRecorder"),
            ]
        ),
        .target(
            name: "AWSXRayInstrument",
            dependencies: [
                .target(name: "AWSXRayRecorder"),
                .product(name: "Instrumentation", package: "gsoc-swift-tracing"),
            ]
        ),
        .testTarget(
            name: "AWSXRayInstrumentTests",
            dependencies: [
                .target(name: "AWSXRayInstrument"),
                .product(name: "NIOInstrumentation", package: "gsoc-swift-tracing"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
            ]
        ),
    ]
)
