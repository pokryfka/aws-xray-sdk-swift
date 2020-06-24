// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "aws-xray-sdk-swift",
    platforms: [
        .macOS(.v10_13),
    ],
    products: [
        .library(name: "AWSXRayRecorder", targets: ["AWSXRayRecorder"]),
        .executable(name: "AWSXRayRecorderExample", targets: ["AWSXRayRecorderExample"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-aws/aws-sdk-swift.git", .upToNextMinor(from: "5.0.0-alpha.4")),
        .package(url: "https://github.com/swift-server/async-http-client.git", .upToNextMinor(from: "1.0.0")),
        .package(url: "https://github.com/apple/swift-log.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/apple/swift-nio.git", .upToNextMajor(from: "2.17.0")),
        .package(url: "https://github.com/Flight-School/AnyCodable", from: "0.2.3"),
    ],
    targets: [
        .target(
            name: "AWSXRayRecorder",
            dependencies: [
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "AWSXRay", package: "aws-sdk-swift"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOConcurrencyHelpers", package: "swift-nio"),
                .product(name: "AnyCodable", package: "AnyCodable"),
            ]
        ),
        .testTarget(
            name: "AWSXRayRecorderTests",
            dependencies: ["AWSXRayRecorder"]
        ),
        .target(
            name: "AWSXRayRecorderExample",
            dependencies: [
                .byName(name: "AWSXRayRecorder"),
            ]
        ),
    ]
)
