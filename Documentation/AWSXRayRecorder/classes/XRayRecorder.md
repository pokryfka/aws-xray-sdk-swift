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
public convenience init(emitter: XRayEmitter, config: Config = Config())
```

### `beginSegment(name:context:metadata:)`

```swift
public func beginSegment(name: String, context: TraceContext, metadata: Segment.Metadata? = nil) -> Segment
```

Creates new segment.
- Parameters:
  - name: segment name
  - context: the trace context
  - metadata: segment metadata
- Returns: new segment

#### Parameters

| Name | Description |
| ---- | ----------- |
| name | segment name |
| context | the trace context |
| metadata | segment metadata |

### `beginSegment(name:baggage:metadata:)`

```swift
public func beginSegment(name: String, baggage: BaggageContext, metadata: Segment.Metadata? = nil) -> XRayRecorder.Segment
```

Creates new segment.
Extracts the thre context from the baggage.
Creates new if the baggage does not contain a valid XRay Trace Context.
- Parameters:
  - name: segment name
  - baggage: baggage with the trace context
  - metadata: segment metadata
- Returns: new segment

#### Parameters

| Name | Description |
| ---- | ----------- |
| name | segment name |
| baggage | baggage with the trace context |
| metadata | segment metadata |

### `wait(_:)`

```swift
public func wait(_ callback: ((Error?) -> Void)? = nil)
```
