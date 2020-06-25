# aws-xray-sdk-swift

![CI](https://github.com/pokryfka/aws-xray-sdk-swift/workflows/CI/badge.svg)

Unofficial AWS X-Ray Recorder SDK for Swift.

## Getting started

### Installation

Add a dependency using [Swift Package Manager](https://swift.org/package-manager/).

```
dependencies: [
    .package(url: "https://https://github.com/pokryfka/aws-xray-sdk-swift.git", from: "0.1.0")
]
```

### Recording

Create an instance of `XRayRecorder`:

```
let recorder = XRayRecorder()
```

Begin and end (sub)segments explicitly:

```
let segment = recorder.beginSegment(name: "Segment 1")
usleep(100_000)
segment.end()
```

use closures for convenience:

```
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

### Emitting

Emit recorded segments:

```
let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
let emmiter = XRayEmmiter(eventLoop: group.next())

try emmiter.send(segments: recorder.removeReady()).wait()

try group.syncShutdownGracefully()
```

Result in [AWS X-Ray console](https://console.aws.amazon.com/xray/home):

![Screenshot of the AWS X-Ray console](./images/example.png?raw=true)

See [`AWSXRayRecorderExample/main.swift`](./Sources/AWSXRayRecorderExample/main.swift) for a complete example.

### AWS SDK

Record [AWSClient](https://github.com/swift-aws/aws-sdk-swift) requests with `XRayMiddleware`:

```
let s3 = S3(middlewares: [XRayMiddleware(recorder: recorder, name: "S3")],
            httpClientProvider: .createNew)
```

and/or recording [SwiftNIO futures](https://github.com/apple/swift-nio):

```
recorder.segment(name: "List Buckets") {
    s3.listBuckets()
}
```

Result in [AWS X-Ray console](https://console.aws.amazon.com/xray/home):

![Screenshot of the AWS X-Ray console](./images/example_sdk.png?raw=true)

See [`AWSXRayRecorderExampleSDK/main.swift`](./Sources/AWSXRayRecorderExampleSDK/main.swift) for a complete example.

## References

- [Sending trace data to AWS X-Ray](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-sendingdata.html)
- [Running the X-Ray daemon locally](https://docs.aws.amazon.com/xray/latest/devguide/xray-daemon-local.html)
- [AWS SDK Swift](https://github.com/swift-aws/aws-sdk-swift)
