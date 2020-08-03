# XRayRecorder

XRay tracer.

``` swift
public class XRayRecorder
```

`XRayRecorder` allows to create new `XRayRecorder.Segment`s and sends them using provided `XRayEmitter`.

# References

  - [AWS X-Ray concepts](https:​//docs.aws.amazon.com/xray/latest/devguide/xray-concepts.html#xray-concepts-segments)

  - [Sending trace data to AWS X-Ray](https:​//docs.aws.amazon.com/xray/latest/devguide/xray-api-sendingdata.html)

## Initializers

### `init(emitter:​config:​)`

Creates an instance of `XRayRecorder`.

``` swift
public convenience init(emitter:​ XRayEmitter, config:​ Config = Config())
```

#### Parameters

  - emitter:​ - emitter:​ emitter used to send `XRayRecorder.Segment`s.
  - config:​ - config:​ configuration, **overrides** enviromental variables.

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

Creates new segment.

``` swift
@inlinable public func segment<T>(name:​ String, context:​ TraceContext, metadata:​ XRayRecorder.Segment.Metadata? = nil, body:​ (Segment) throws -> T) rethrows -> T
```

#### Parameters

  - name:​ - name:​ segment name
  - context:​ - context:​ the trace context
  - metadata:​ - metadata:​ segment metadata
  - body:​ - body:​ segment body

### `segment(name:​baggage:​metadata:​body:​)`

Creates new segment.

``` swift
@inlinable public func segment<T>(name:​ String, baggage:​ BaggageContext, metadata:​ XRayRecorder.Segment.Metadata? = nil, body:​ (Segment) throws -> T) rethrows -> T
```

Extracts the trace context from the baggage.
Creates new one if the baggage does not contain a valid `XRayContext`.

Depending on the context missing strategy configuration will log an error or fail if the context is missing.

#### Parameters

  - name:​ - name:​ segment name
  - baggage:​ - baggage:​ baggage with the trace context
  - metadata:​ - metadata:​ segment metadata
  - body:​ - body:​ segment body

### `flush(on:​)`

Flushes the emitter in `SwiftNIO` future.

``` swift
public func flush(on eventLoop:​ EventLoop) -> EventLoopFuture<Void>
```

#### Parameters

  - eventLoop:​ - eventLoop:​ `EventLoop` used to "do the flushing".

### `segment(name:​context:​metadata:​body:​)`

Creates new segment.

``` swift
@inlinable public func segment<T>(name:​ String, context:​ TraceContext, metadata:​ Segment.Metadata? = nil, body:​ () -> EventLoopFuture<T>) -> EventLoopFuture<T>
```

#### Parameters

  - name:​ - name:​ segment name
  - context:​ - context:​ the trace context
  - metadata:​ - metadata:​ segment metadata
  - body:​ - body:​ segment body

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

``` swift
public func beginSegment(name:​ String, baggage:​ BaggageContext, metadata:​ Segment.Metadata? = nil) -> XRayRecorder.Segment
```

Extracts the trace context from the baggage.
Creates new one if the baggage does not contain a valid `XRayContext`.

Depending on the context missing strategy configuration will log an error or fail if the context is missing.

#### Parameters

  - name:​ - name:​ segment name
  - baggage:​ - baggage:​ baggage with the trace context
  - metadata:​ - metadata:​ segment metadata

#### Returns

new segment

### `wait(_:​)`

Flushes the emitter.
May be blocking.

``` swift
public func wait(_ callback:​ ((Error?) -> Void)? = nil)
```

#### Parameters

  - callback:​ - callback:​ callback with error if the operation failed.
