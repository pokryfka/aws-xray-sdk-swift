**CLASS**

# `XRayRecorder`

```swift
public class XRayRecorder
```

# References
- [AWS X-Ray concepts](https://docs.aws.amazon.com/xray/latest/devguide/xray-concepts.html#xray-concepts-segments)
- [Sending trace data to AWS X-Ray](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-sendingdata.html)

## Methods
### `init(emitter:config:)`

```swift
public init(emitter: XRayEmitter, config: Config = Config())
```

### `beginSegment(name:parentId:aws:metadata:)`

```swift
public func beginSegment(name: String, parentId: Segment.ID? = nil,
                         aws: Segment.AWS? = nil, metadata: Segment.Metadata? = nil) -> Segment
```

### `beginSubsegment(name:parentId:aws:metadata:)`

```swift
public func beginSubsegment(name: String, parentId: Segment.ID,
                            aws: Segment.AWS? = nil, metadata: Segment.Metadata? = nil) -> Segment
```

### `beginSegment(name:context:aws:metadata:)`

```swift
public func beginSegment(name: String, context: TraceContext,
                         aws: Segment.AWS? = nil, metadata: Segment.Metadata? = nil) -> Segment
```

### `wait(_:)`

```swift
public func wait(_ callback: ((Error?) -> Void)? = nil)
```
