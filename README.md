# aws-xray-sdk-swift

![CI](https://github.com/pokryfka/aws-xray-sdk-swift/workflows/CI/badge.svg)
[![codecov](https://codecov.io/gh/pokryfka/aws-xray-sdk-swift/branch/master/graph/badge.svg)](https://codecov.io/gh/pokryfka/aws-xray-sdk-swift)

Unofficial AWS X-Ray SDK for Swift.

## Project status

Functional beta.

aws-xray-sdk-swift follows [SemVer](https://semver.org). Until version 1.0.0 breaking changes may be introduced on minor version number changes.

## Documentation

- [API documentation](https://github.com/pokryfka/aws-xray-sdk-swift/wiki)

## Getting started

### Adding the dependency

Add the package dependency to your package [Swift Package Manager](https://swift.org/package-manager/) manifest file `Package.swift`:

```swift
.package(url: "https://github.com/pokryfka/aws-xray-sdk-swift.git", upToNextMinor(from: "0.6.0"))
```

and `AWSXRaySDK` library to your target (here `AWSXRaySDKExample`):

```swift
.target(name: "AWSXRaySDKExample", dependencies: [
    .product(name: "AWSXRaySDK", package: "aws-xray-sdk-swift"),
])
```

### Recording

Create an instance of `XRayRecorder` and new context:

```swift
import AWSXRaySDK

let recorder = XRayRecorder()

let context = XRayContext()
```

Begin and end (sub)segments explicitly:

```swift
let segment = recorder.beginSegment(name: "Segment 1", context: context)
usleep(100_000)
segment.end()
```

use closures for convenience:

```swift
recorder.segment(name: "Segment 2", context: context) { segment in
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

#### Errors and exceptions

You can record [errors and exceptions](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html#api-segmentdocuments-errors):

```swift
segment.addError(ExampleError.test)
segment.addException(message: "Test Exception")
```

Note that `Error`s rethrown in the closures are recorded.

#### HTTP request data

You can record details about an HTTP request that your application served or made to a downstream HTTP API, see [HTTP request data](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html#api-segmentdocuments-http):

```swift
segment.setHTTPRequest(method: .POST, url: "http://www.example.com/api/user")
segment.setHTTPResponse(status: .ok)
```

#### Annotations and Metadata

Segments and subsegments can include [annotations](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html#api-segmentdocuments-annotations):

```swift
segment.setAnnotation(98101, forKey: "zip_code")
```

and [metadata](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html#api-segmentdocuments-metadata):

```swift
segment.setMetadata(["debug": ["test": "Metadata string"]])
```

### Emitting

Events are emitted as soon as they end.

Subsegments have to be created before the parent segment ended.

Subsegments may end after their parent segment ended, in which case they will be presented as *Pending* until they end.

Make sure to flush the recorder before program exits:

```swift
recorder.shutdown()
```

or, if using [SwiftNIO](https://github.com/apple/swift-nio), on provided `EventLoop`:

```swift
try recorder.flush(on: eventLoop).wait()
```

Result in [AWS X-Ray console](https://console.aws.amazon.com/xray/home):

![Screenshot of the AWS X-Ray console](./images/example.png?raw=true)

See [`AWSXRaySDKExample/main.swift`](./Examples/Sources/AWSXRaySDKExample/main.swift) for a complete example.

#### Custom emitter

By default events are sent as UDP to [AWS X-Ray daemon](https://docs.aws.amazon.com/xray/latest/devguide/xray-daemon.html) which buffers and relays it to [AWS X-Ray API](https://docs.aws.amazon.com/xray/latest/devguide/xray-api.html).

A custom emitter has to implement `XRayEmitter` protocol:

```swift
public protocol XRayEmitter {
    func send(_ segment: XRayRecorder.Segment)
    func flush(_ callback: @escaping (Error?) -> Void)
}
```

it may also implement `XRayNIOEmitter`:

```swift
public protocol XRayNIOEmitter: XRayEmitter {
    func flush(on eventLoop: EventLoop?) -> EventLoopFuture<Void>
}
```

The emitter has to be provided when creating an instance of `XRayRecorder`:

```swift
let recorder = XRayRecorder(emitter: XRayNoOpEmitter())
```

## Configuration

The libraries behavior can be configured using environment variables:

- `AWS_XRAY_SDK_ENABLED` - set `false` to disable tracing, enabled by default.
- `AWS_XRAY_DAEMON_ADDRESS` - the IP address and port of the X-Ray daemon listener, `127.0.0.1:2000` by default.
- `AWS_XRAY_CONTEXT_MISSING` - configures how the SDK handles missing context:
    - `RUNTIME_ERROR` - Indicate that a precondition was violated.
    - `LOG_ERROR` - Log an error and continue (default).
- `XRAY_RECORDER_LOG_LEVEL` - recorder [swift-log](https://github.com/apple/swift-log) logging level, `info` by default.
- `XRAY_EMITTER_LOG_LEVEL` - emitter [swift-log](https://github.com/apple/swift-log) logging level, `info` by default.

Alternatively `XRayRecorder` can be configured using `XRayRecorder.Config` which will **override** environment variables:

```swift
let recorder = XRayRecorder(config: .init(enabled: true, logLevel: .debug))              
```

## Testing

 You can run the AWS X-Ray daemon locally or in a Docker container, see [Running the X-Ray daemon locally](https://docs.aws.amazon.com/xray/latest/devguide/xray-daemon-local.html)

You can use `XRayLogEmitter` from `AWSXRayTesting` to "emit" segments to the console:

```swift
import AWSXRaySDK
import AWSXRayTesting

let recorder = XRayRecorder(emitter: XRayLogEmitter())
```

## Contributing

### Code Formatting

Format code using [swiftformat](https://github.com/nicklockwood/SwiftFormat):

```
swiftformat .
```

Consider creating [Git pre-commit hook](https://github.com/nicklockwood/SwiftFormat#git-pre-commit-hook)

```
echo 'swiftformat --lint .' > .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

## Examples

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

See [`AWSXRaySDKExampleLambda/main.swift`](./Examples/Sources/AWSXRaySDKExampleLambda/main.swift) for a complete example.
