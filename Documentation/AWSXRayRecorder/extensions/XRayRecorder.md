**EXTENSION**

# `XRayRecorder`
```swift
extension XRayRecorder
```

## Methods
### `segment(name:context:metadata:body:)`

```swift
public func segment<T>(name: String, context: TraceContext, metadata: XRayRecorder.Segment.Metadata? = nil,
                       body: (Segment) throws -> T)
    rethrows -> T
```

### `segment(name:baggage:metadata:body:)`

```swift
public func segment<T>(name: String, baggage: BaggageContext, metadata: XRayRecorder.Segment.Metadata? = nil,
                       body: (Segment) throws -> T)
    rethrows -> T
```

### `flush(on:)`

```swift
public func flush(on eventLoop: EventLoop) -> EventLoopFuture<Void>
```

### `segment(name:context:metadata:body:)`

```swift
public func segment<T>(name: String, context: TraceContext, metadata: Segment.Metadata? = nil,
                       body: () -> EventLoopFuture<T>) -> EventLoopFuture<T>
```
