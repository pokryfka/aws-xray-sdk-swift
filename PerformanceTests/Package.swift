// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "aws-xray-sdk-swift-performance",
    platforms: [
        .macOS(.v10_14),
    ],
    products: [
    ],
    dependencies: [
        .package(name: "aws-xray-sdk-swift", path: ".."),
        .package(url: "https://github.com/Ikiga/IkigaJSON.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/fabianfett/pure-swift-json.git", .upToNextMinor(from: "0.4.0")),
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
                .product(name: "IkigaJSON", package: "IkigaJSON"),
                .product(name: "PureSwiftJSON", package: "pure-swift-json"),
            ],
            path: "./AWSXRayJSONTests"
        ),
    ]
)
