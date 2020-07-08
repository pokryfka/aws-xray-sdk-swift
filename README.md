# aws-xray-sdk-swift

![CI](https://github.com/pokryfka/aws-xray-sdk-swift/workflows/CI/badge.svg)

Unofficial AWS X-Ray Recorder SDK for Swift.

## Getting started

### Installation

Add a dependency using [Swift Package Manager](https://swift.org/package-manager/).

```swift
dependencies: [
    .package(url: "https://github.com/pokryfka/aws-xray-sdk-swift.git", from: "0.3.0")
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
        try segment.subsegment(name: "Subsegment 2.1.2 with Error") { _ in
            usleep(200_000)
            throw ExampleError.test
        }
    }
}
```

### Emitting

Events are emitted after they end.

Subsegments may end after their parent segment end, in which case they will be presented as *Pending* until they end.

Make sure all segments are sent before program exits:

```swift
try recorder.wait()
```

Result in [AWS X-Ray console](https://console.aws.amazon.com/xray/home):

![Screenshot of the AWS X-Ray console](./images/example.png?raw=true)

See [`AWSXRayRecorderExample/main.swift`](./Examples/Sources/AWSXRayRecorderExample/main.swift) for a complete example.

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

### AWS SDK (WIP)

Record [AWSClient](https://github.com/swift-aws/aws-sdk-swift) requests with `XRayMiddleware`:

```swift
let awsClient = AWSClient(
    middlewares: [XRayMiddleware(recorder: recorder, name: "S3")],
    httpClientProvider: .shared(httpClient)
)
let s3 = S3(client: awsClient)
```

and/or recording [SwiftNIO futures](https://github.com/apple/swift-nio#promises-and-futures):

```swift
recorder.segment(name: "List Buckets") {
    s3.listBuckets()
}
```

Result in [AWS X-Ray console](https://console.aws.amazon.com/xray/home):

![Screenshot of the AWS X-Ray console](./images/example_sdk.png?raw=true)

See [`AWSXRayRecorderExampleSDK/main.swift`](./Examples/Sources/AWSXRayRecorderExampleSDK/main.swift) for a complete example.

### AWS Lambda using [Swift AWS Lambda Runtime](https://github.com/swift-server/swift-aws-lambda-runtime)

Enable tracing as described in [Using AWS Lambda with AWS X-Ray](https://docs.aws.amazon.com/lambda/latest/dg/services-xray.html).

Note [that](https://docs.aws.amazon.com/xray/latest/devguide/xray-daemon.html):

>  Lambda runs the daemon automatically any time a function is invoked for a sampled request.

Make sure to flush the recorder in each invocation:

```swift
private struct ExampleLambdaHandler: EventLoopLambdaHandler {
    typealias In = Cloudwatch.ScheduledEvent
    typealias Out = Void

    private let recorder = XRayRecorder()

    private func doWork(on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.submit { usleep(100_000) }.map { _ in }
    }

    func handle(context: Lambda.Context, event: In) -> EventLoopFuture<Void> {
        recorder.segment(name: "ExampleLambdaHandler", context: context) {
            self.doWork(on: context.eventLoop)
        }.flatMap {
            self.recorder.flush(on: context.eventLoop)
        }
    }
}
```

See [`AWSXRayRecorderExampleLambda/main.swift`](./Examples/Sources/AWSXRayRecorderExampleLambda/main.swift) for a complete example.

## Configuration

The library’s behavior can be configured using environment variables:

- `AWS_XRAY_SDK_DISABLED`: set `true` to disable tracing, enabled by default.
- `AWS_XRAY_DAEMON_ADDRESS` – the IP address and port of the X-Ray daemon, `127.0.0.1:2000` by default.
- `XRAY_RECORDER_LOG_LEVEL`: [swift-log](https://github.com/apple/swift-log) logging level, `info` by default.

Alternatively `XRayRecorder` can be configured using `XRayRecorder.Config` which will override environment variables:

```swift
let recorder = XRayRecorder(
    config: .init(enabled: true,
                  logLevel: .debug,
                  daemonEndpoint: "127.0.0.1:2000",
                  serviceVersion: "aws-xray-sdk-swift-example-sdk")
)                  
```

### SwiftNIO

Segments can be emitted on provided [SwiftNIO](https://github.com/apple/swift-nio#eventloops-and-eventloopgroups) `EventLoopGroup`:

```swift
let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
let eventLoop = group.next()
let recorder = XRayRecorder(eventLoopGroup: group)

// ...

try recorder.flush(on: eventLoop).wait()
```

### Custom emitter

By default events are sent as UDP to [AWS X-Ray daemon](https://docs.aws.amazon.com/xray/latest/devguide/xray-daemon.html) which buffers and relays it to [AWS X-Ray API](https://docs.aws.amazon.com/xray/latest/devguide/xray-api.html).

A custom emitter has to implement `XRayEmitter` protocol:

```swift
public protocol XRayEmitter {
    func send(_ segment: XRayRecorder.Segment)
    func flush(_ callback: @escaping (Error?) -> Void)
}
```

example:

```swift
let recorder = XRayRecorder(emitter: XRayNoopEmitter())
```

## References

- [Sending trace data to AWS X-Ray](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-sendingdata.html)
- [Running the X-Ray daemon locally](https://docs.aws.amazon.com/xray/latest/devguide/xray-daemon-local.html)
- [AWS SDK Swift](https://github.com/swift-aws/aws-sdk-swift)
- [Swift AWS Lambda Runtime](https://github.com/swift-server/swift-aws-lambda-runtime)
