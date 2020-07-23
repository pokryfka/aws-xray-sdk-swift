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
        .library(name: "AWSXRayRecorderLambda", targets: ["AWSXRayRecorderLambda"]),
        .library(name: "AWSXRayRecorderSDK", targets: ["AWSXRayRecorderSDK"]), // TODO: remove
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", .upToNextMajor(from: "2.17.0")),
        .package(url: "https://github.com/apple/swift-log.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/Flight-School/AnyCodable.git", .upToNextMajor(from: "0.3.0")),
        .package(name: "swift-baggage-context", url: "https://github.com/slashmo/gsoc-swift-baggage-context.git", .upToNextMinor(from: "0.1.0")),
//        .package(url: "https://github.com/slashmo/gsoc-swift-tracing.git", .branch("main")),
        // "bleeding edge"
        .package(url: "https://github.com/slashmo/gsoc-swift-tracing.git", .revision("0d96630f614bda1bd88c9422cf05b077cf034886")),
        .package(url: "https://github.com/swift-aws/aws-sdk-swift-core.git", .upToNextMinor(from: "5.0.0-alpha.5")),
        .package(url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", .upToNextMajor(from: "0.2.0")),
    ],
    targets: [
        .target(
            name: "AWSXRayRecorder",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "AnyCodable", package: "AnyCodable"),
//                .product(name: "Baggage", package: "swift-baggage-context"),
            ]
        ),
        .testTarget(
            name: "AWSXRayRecorderTests",
            dependencies: [.target(name: "AWSXRayRecorder")]
        ),
        .target(
            name: "AWSXRayInstrument",
            dependencies: [
                .target(name: "AWSXRayRecorder"),
                .product(name: "Instrumentation", package: "gsoc-swift-tracing"),
                .product(name: "Baggage", package: "swift-baggage-context"),
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
        .target(
            name: "AWSXRayRecorderLambda",
            dependencies: [
                .target(name: "AWSXRayRecorder"),
                .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
            ]
        ),
        .target(
            name: "AWSXRayRecorderSDK",
            dependencies: [
                .target(name: "AWSXRayRecorder"),
                .product(name: "AWSSDKSwiftCore", package: "aws-sdk-swift-core"),
            ]
        ),
    ]
)
