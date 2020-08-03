// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "aws-xray-sdk-swift-examples",
    platforms: [
        .macOS(.v10_14),
    ],
    products: [
        .executable(name: "AWSXRaySDKExample", targets: ["AWSXRaySDKExample"]),
        .executable(name: "AWSXRaySDKExampleAWS", targets: ["AWSXRaySDKExampleAWS"]),
        .executable(name: "AWSXRaySDKExampleLambda", targets: ["AWSXRaySDKExampleLambda"]),
    ],
    dependencies: [
        .package(name: "aws-xray-sdk-swift", path: ".."),
        .package(url: "https://github.com/swift-aws/aws-sdk-swift.git", .upToNextMinor(from: "5.0.0-alpha.5")),
        .package(url: "https://github.com/swift-server/async-http-client.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", .upToNextMajor(from: "0.2.0")),
    ],
    targets: [
        .target(
            name: "AWSXRaySDKExample",
            dependencies: [
                .product(name: "AWSXRaySDK", package: "aws-xray-sdk-swift"),
//                .product(name: "AWSXRayTesting", package: "aws-xray-sdk-swift"),
            ]
        ),
        .target(
            name: "AWSXRaySDKExampleAWS",
            dependencies: [
                .product(name: "AWSXRaySDK", package: "aws-xray-sdk-swift"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "AWSS3", package: "aws-sdk-swift"),
            ]
        ),
        .target(
            name: "AWSXRaySDKExampleLambda",
            dependencies: [
                .product(name: "AWSXRaySDK", package: "aws-xray-sdk-swift"),
                .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
                .product(name: "AWSLambdaEvents", package: "swift-aws-lambda-runtime"),
            ]
        ),
    ]
)
