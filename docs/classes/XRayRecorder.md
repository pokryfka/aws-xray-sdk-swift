**CLASS**

# `XRayRecorder`

```swift
public class XRayRecorder
```

# References
- [Sending trace data to AWS X-Ray](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-sendingdata.html)

## Properties
### `traceId`

```swift
@Synchronized public var traceId = TraceID()
```

## Methods
### `init(emitter:config:)`

```swift
public init(emitter: XRayEmitter, config: Config = Config())
```

### `beginSegment(name:parentId:aws:metadata:)`

```swift
public func beginSegment(name: String, parentId: String? = nil,
                         aws: Segment.AWS? = nil, metadata: Segment.Metadata? = nil) -> Segment
```

### `beginSubsegment(name:parentId:aws:metadata:)`

```swift
public func beginSubsegment(name: String, parentId: String,
                            aws: Segment.AWS? = nil, metadata: Segment.Metadata? = nil) -> Segment
```

### `wait()`

```swift
public func wait()
```

### `flush(on:)`

```swift
public func flush(on eventLoop: EventLoop) -> EventLoopFuture<Void>
```
