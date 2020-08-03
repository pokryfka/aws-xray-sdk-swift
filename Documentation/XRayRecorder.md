# XRayRecorder

``` swift
public class XRayRecorder
```

# References

  - [AWS X-Ray concepts](https:​//docs.aws.amazon.com/xray/latest/devguide/xray-concepts.html#xray-concepts-segments)

  - [Sending trace data to AWS X-Ray](https:​//docs.aws.amazon.com/xray/latest/devguide/xray-api-sendingdata.html)

## Initializers

### `init(emitter:​config:​)`

``` swift
public convenience init(emitter:​ XRayEmitter, config:​ Config = Config())
```

### `init(eventLoopGroupProvider:​config:​)`

Creates an instance of `XRayRecorder` with `XRayUDPEmitter`.

``` swift
public convenience init(eventLoopGroupProvider:​ XRayUDPEmitter.EventLoopGroupProvider = .createNew, config:​ Config = Config())
```

#### Parameters

  - eventLoopGroupProvider:​ - eventLoopGroupProvider:​ specifies how the `EventLoopGroup` used by `XRayUDPEmitter` will be created and establishes lifecycle ownership.
  - config:​ - config:​ configuration, **overrides** enviromental variables.

## Methods

### `segment(name:​context:​metadata:​body:​)`

``` swift
@inlinable public func segment<T>(name:​ String, context:​ TraceContext, metadata:​ XRayRecorder.Segment.Metadata? = nil, body:​ (Segment) throws -> T) rethrows -> T
```

### `segment(name:​baggage:​metadata:​body:​)`

``` swift
@inlinable public func segment<T>(name:​ String, baggage:​ BaggageContext, metadata:​ XRayRecorder.Segment.Metadata? = nil, body:​ (Segment) throws -> T) rethrows -> T
```

### `flush(on:​)`

``` swift
public func flush(on eventLoop:​ EventLoop) -> EventLoopFuture<Void>
```

### `segment(name:​context:​metadata:​body:​)`

``` swift
@inlinable public func segment<T>(name:​ String, context:​ TraceContext, metadata:​ Segment.Metadata? = nil, body:​ () -> EventLoopFuture<T>) -> EventLoopFuture<T>
```

### `beginSegment(name:​context:​metadata:​)`

Creates new segment.

``` swift
public func beginSegment(name:​ String, context:​ TraceContext, metadata:​ Segment.Metadata? = nil) -> Segment
```

#### Parameters

  - name:​ - name:​ segment name
  - context:​ - context:​ the trace context
  - metadata:​ - metadata:​ segment metadata

#### Returns

new segment

### `beginSegment(name:​baggage:​metadata:​)`

Creates new segment.
Extracts the thre context from the baggage.
Creates new if the baggage does not contain a valid XRay Trace Context.

``` swift
public func beginSegment(name:​ String, baggage:​ BaggageContext, metadata:​ Segment.Metadata? = nil) -> XRayRecorder.Segment
```

#### Parameters

  - name:​ - name:​ segment name
  - baggage:​ - baggage:​ baggage with the trace context
  - metadata:​ - metadata:​ segment metadata

#### Returns

new segment

### `wait(_:​)`

``` swift
public func wait(_ callback:​ ((Error?) -> Void)? = nil)
```
