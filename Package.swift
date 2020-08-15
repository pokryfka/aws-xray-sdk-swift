// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "aws-xray-sdk-swift",
    products: [
        // the main library including the recorder, the UDP emitter and a JSON encoder; no dependency on Foundation
        .library(name: "AWSXRaySDK", targets: ["AWSXRaySDK"]),
        // X-Ray recorder without emitter, no dependency on Foundation
        .library(name: "AWSXRayRecorder", targets: ["AWSXRayRecorder"]),
        // UDP emitter without JSON encoder, no dependency on Foundation
        .library(name: "AWSXRayUDPEmitter", targets: ["AWSXRayUDPEmitter"]),
        // for testing only, may have dependency on Foundation
        .library(name: "AWSXRayTesting", targets: ["AWSXRayTesting"]),
        // XRay TracingInstrument
        .library(name: "AWSXRayInstrument", targets: ["AWSXRayInstrument"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", .upToNextMajor(from: "2.17.0")),
        .package(url: "https://github.com/apple/swift-log.git", .upToNextMajor(from: "1.0.0")),
        .package(name: "swift-baggage-context", url: "https://github.com/slashmo/gsoc-swift-baggage-context.git", .upToNextMinor(from: "0.2.0")),
        .package(url: "https://github.com/fabianfett/pure-swift-json.git", .upToNextMinor(from: "0.4.0")),
        .package(url: "https://github.com/slashmo/gsoc-swift-tracing.git", .revision("8e483480a9994563219d6380247aa8c4897fb9cb")),
    ],
    targets: [
        .target(
            name: "AWSXRaySDK",
            dependencies: [
                .target(name: "AWSXRayRecorder"),
                .target(name: "AWSXRayUDPEmitter"),
                .product(name: "PureSwiftJSON", package: "pure-swift-json"),
            ]
        ),
        .testTarget(
            name: "AWSXRaySDKTests",
            dependencies: [.target(name: "AWSXRaySDK")]
        ),
        .target(
            name: "AWSXRayRecorder",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Baggage", package: "swift-baggage-context"),
            ]
        ),
        .testTarget(
            name: "AWSXRayRecorderTests",
            dependencies: [.target(name: "AWSXRayRecorder")]
        ),
        .target(
            name: "AWSXRayUDPEmitter",
            dependencies: [
                .target(name: "AWSXRayRecorder"),
            ]
        ),
        .testTarget(
            name: "AWSXRayUDPEmitterTests",
            dependencies: [.target(name: "AWSXRayUDPEmitter")]
        ),
        .target(
            name: "AWSXRayTesting",
            dependencies: [
                .target(name: "AWSXRayRecorder"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "Logging", package: "swift-log"),
            ]
        ),
        .testTarget(
            name: "AWSXRayTestingTests",
            dependencies: [.target(name: "AWSXRayTesting")]
        ),
        .target(
            name: "AWSXRayInstrument",
            dependencies: [
                .target(name: "AWSXRayRecorder"),
                .product(name: "TracingInstrumentation", package: "gsoc-swift-tracing"),
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
