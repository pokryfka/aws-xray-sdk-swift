**EXTENSION**

# `XRayRecorder`
```swift
extension XRayRecorder
```

## Methods
### `segment(name:parentId:metadata:body:)`

```swift
public func segment<T>(name: String, parentId: String? = nil, metadata: XRayRecorder.Segment.Metadata? = nil,
                       body: (Segment) throws -> T)
    rethrows -> T
```

### `init(config:eventLoopGroup:)`

```swift
public convenience init(config: Config = Config(), eventLoopGroup: EventLoopGroup? = nil)
```

### `segment(name:parentId:metadata:body:)`

```swift
public func segment<T>(name: String, parentId: String? = nil, metadata: Segment.Metadata? = nil,
                       body: () -> EventLoopFuture<T>) -> EventLoopFuture<T>
```

### `beginSegment(name:parentId:metadata:body:)`

```swift
public func beginSegment<T>(name: String, parentId: String? = nil, metadata: Segment.Metadata? = nil,
                            body: (Segment) -> EventLoopFuture<T>) -> EventLoopFuture<(Segment, T)>
```
