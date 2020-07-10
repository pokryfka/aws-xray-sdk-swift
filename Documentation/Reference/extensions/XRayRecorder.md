**EXTENSION**

# `XRayRecorder`
```swift
extension XRayRecorder
```

## Methods
### `beginSegment(name:context:)`

```swift
public func beginSegment(name: String, context: Lambda.Context) -> Segment
```

### `segment(name:context:body:)`

```swift
public func segment<T>(name: String, context: Lambda.Context, body: (Segment) throws -> T) rethrows -> T
```

### `segment(name:context:body:)`

```swift
public func segment<T>(name: String, context: Lambda.Context, body: () -> EventLoopFuture<T>) -> EventLoopFuture<T>
```
