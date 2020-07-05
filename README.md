# aws-xray-sdk-swift

![CI](https://github.com/pokryfka/aws-xray-sdk-swift/workflows/CI/badge.svg)

Unofficial AWS X-Ray Recorder SDK for Swift.

## Getting started

### Installation

Add a dependency using [Swift Package Manager](https://swift.org/package-manager/).

```swift
dependencies: [
    .package(url: "https://github.com/pokryfka/aws-xray-sdk-swift.git", from: "0.2.1")
]
```

### Recording

Create an instance of `XRayRecorder`:

```swift
let recorder = XRayRecorder()
```

Begin and end (sub)segments explicitly:

```swift
let segment = recorder.beginSegment(name: "Segment 1")
usleep(100_000)
segment.end()
```

use closures for convenience:

```swift
recorder.segment(name: "Segment 2") { segment in
    try? segment.subsegment(name: "Subsegment 2.1") { segment in
        _ = segment.subsegment(name: "Subsegment 2.1.1 with Result") { _ -> String in
            usleep(100_000)
            return "Result"
        }
        try segment.subsegment(name: "Subsegment 2.1.1 with Error") { _ in
            usleep(200_000)
            throw ExampleError.test
        }
    }
}
```

Make sure all segments are sent before program exits.

```swift
try recorder.flush().wait()
```

Result in [AWS X-Ray console](https://console.aws.amazon.com/xray/home):

![Screenshot of the AWS X-Ray console](./images/example.png?raw=true)

See [`AWSXRayRecorderExample/main.swift`](./Sources/AWSXRayRecorderExample/main.swift) for a complete example.

### [Annotations](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html#api-segmentdocuments-annotations)

> Segments and subsegments can include an annotations object containing one or more fields that X-Ray indexes for use with filter expressions. (...)

```swift
segment.setAnnotation("zip_code", value: 98101)
```

### [Metadata](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html#api-segmentdocuments-metadata)

> Segments and subsegments can include a metadata object containing one or more fields with values of any type, including objects and arrays. X-Ray does not index metadata (...)

```swift
segment.setMetadata(["debug": ["test": "Metadata string"]])
```

### AWS SDK

Record [AWSClient](https://github.com/swift-aws/aws-sdk-swift) requests with `XRayMiddleware`:

```swift
let s3 = S3(middlewares: [XRayMiddleware(recorder: recorder, name: "S3")],
            httpClientProvider: .createNew)
```

and/or recording [SwiftNIO futures](https://github.com/apple/swift-nio):

```swift
recorder.segment(name: "List Buckets") {
    s3.listBuckets()
}
```

Result in [AWS X-Ray console](https://console.aws.amazon.com/xray/home):

![Screenshot of the AWS X-Ray console](./images/example_sdk.png?raw=true)

See [`AWSXRayRecorderExampleSDK/main.swift`](./Sources/AWSXRayRecorderExampleSDK/main.swift) for a complete example.

### AWS Lambda

See [`AWSXRayRecorderExampleLambda/main.swift`](./Sources/AWSXRayRecorderExampleLambda/main.swift) for [AWS Lambda](https://aws.amazon.com/lambda/) function example.

Enable tracing as described in [Using AWS Lambda with AWS X-Ray](https://docs.aws.amazon.com/lambda/latest/dg/services-xray.html)

Check [swift-aws-lambda-template](https://github.com/pokryfka/swift-aws-lambda-template) for more examples and a template for deploying Lambda functions.

## Configuration

The library’s behavior can be configured using environment variables:

- `AWS_XRAY_TRACING_ENABLED`: set `false` to disable tracing, enabled by default.
- `XRAY_RECORDER_LOG_LEVEL`: [swift-log](https://github.com/apple/swift-log) logging level, `info` by default.
- `AWS_XRAY_DAEMON_ADDRESS` – the IP address and port of the X-Ray daemon, `127.0.0.1:2000` by default; prefix with `http` to use `HTTP` rather than `UDP`.

## References

- [Sending trace data to AWS X-Ray](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-sendingdata.html)
- [Running the X-Ray daemon locally](https://docs.aws.amazon.com/xray/latest/devguide/xray-daemon-local.html)
- [AWS SDK Swift](https://github.com/swift-aws/aws-sdk-swift)
- [Swift AWS Lambda Runtime](https://github.com/swift-server/swift-aws-lambda-runtime)
