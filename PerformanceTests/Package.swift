// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "aws-xray-sdk-swift-performance",
    products: [
    ],
    dependencies: [
        .package(name: "aws-xray-sdk-swift", path: ".."),
        .package(url: "https://github.com/Ikiga/IkigaJSON.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/fabianfett/pure-swift-json.git", .upToNextMinor(from: "0.4.0")),
        .package(name: "JSONSchema", url: "https://github.com/kylef/JSONSchema.swift.git", .upToNextMinor(from: "0.5.0")),
    ],
    targets: [
        .target(
            name: "AWSXRayJSON",
            dependencies: [
            ],
            path: "./AWSXRayJSON"
        ),
        .testTarget(
            name: "AWSXRayJSONTests",
            dependencies: [
                .product(name: "AWSXRayRecorder", package: "aws-xray-sdk-swift"),
                .product(name: "AWSXRayUDPEmitter", package: "aws-xray-sdk-swift"),
                .product(name: "IkigaJSON", package: "IkigaJSON"),
                .product(name: "PureSwiftJSON", package: "pure-swift-json"),
                .product(name: "JSONSchema", package: "JSONSchema"),
            ],
            path: "./AWSXRayJSONTests"
        ),
    ]
)
