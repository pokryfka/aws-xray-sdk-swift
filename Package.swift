// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "aws-xray-sdk-swift",
    platforms: [
        .macOS(.v10_13),
    ],
    products: [
        .library(name: "AWSXRayRecorder", targets: ["AWSXRayRecorder"]),
        .library(name: "AWSXRayRecorderLambda", targets: ["AWSXRayRecorderLambda"]),
        // Examples
        .executable(name: "AWSXRayRecorderExample", targets: ["AWSXRayRecorderExample"]),
        .executable(name: "AWSXRayRecorderExampleSDK", targets: ["AWSXRayRecorderExampleSDK"]),
        .executable(name: "AWSXRayRecorderExampleLambda", targets: ["AWSXRayRecorderExampleLambda"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-aws/aws-sdk-swift.git", .upToNextMinor(from: "5.0.0-alpha.4")),
        .package(url: "https://github.com/swift-server/async-http-client.git", .upToNextMinor(from: "1.0.0")),
        .package(url: "https://github.com/apple/swift-log.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/apple/swift-nio.git", .upToNextMajor(from: "2.17.0")),
        .package(url: "https://github.com/Flight-School/AnyCodable", from: "0.2.3"),
        .package(url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", .upToNextMajor(from: "0.2.0")),
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
        // Examples
        .target(
            name: "AWSXRayRecorderExample",
            dependencies: [
                .byName(name: "AWSXRayRecorder"),
            ]
        ),
        .target(
            name: "AWSXRayRecorderExampleSDK",
            dependencies: [
                .byName(name: "AWSXRayRecorder"),
                .product(name: "AWSS3", package: "aws-sdk-swift"),
            ]
        ),
        .target(
            name: "AWSXRayRecorderExampleLambda",
            dependencies: [
                .byName(name: "AWSXRayRecorderLambda"),
                .product(name: "AWSLambdaEvents", package: "swift-aws-lambda-runtime"),
                .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
            ]
        ),
    ]
)
