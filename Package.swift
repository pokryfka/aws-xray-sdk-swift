// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "aws-xray-sdk-swift",
    platforms: [
        .macOS(.v10_14),
    ],
    products: [
        .library(name: "AWSXRayRecorder", targets: ["AWSXRayRecorder"]),
        .library(name: "AWSXRayRecorderLambda", targets: ["AWSXRayRecorderLambda"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", .upToNextMajor(from: "2.17.0")),
        .package(url: "https://github.com/apple/swift-log.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/Flight-School/AnyCodable.git", .upToNextMajor(from: "0.3.0")),
        .package(name: "swift-baggage-context", url: "https://github.com/slashmo/gsoc-swift-baggage-context.git", .upToNextMinor(from: "0.1.0")),
        .package(url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", .upToNextMajor(from: "0.2.0")),
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
        .target(
            name: "AWSXRayRecorderLambda",
            dependencies: [
                .byName(name: "AWSXRayRecorder"),
                .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
            ]
        ),
        .testTarget(
            name: "AWSXRayRecorderTests",
            dependencies: ["AWSXRayRecorder"]
        ),
    ]
)
