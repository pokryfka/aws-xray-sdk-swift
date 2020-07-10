**EXTENSION**

# `XRayRecorder.Segment`
```swift
extension XRayRecorder.Segment
```

## Methods
### `subsegment(name:metadata:body:)`

```swift
public func subsegment<T>(name: String, metadata: XRayRecorder.Segment.Metadata? = nil,
                          body: (XRayRecorder.Segment) throws -> T) rethrows -> T
```

### `subsegment(name:metadata:body:)`

```swift
public func subsegment<T>(name: String, metadata: XRayRecorder.Segment.Metadata? = nil,
                          body: () -> EventLoopFuture<T>) -> EventLoopFuture<T>
```

### `setAWS(_:)`

```swift
public func setAWS(_ aws: AWS)
```

### `setHTTP(_:)`

```swift
public func setHTTP(_ http: HTTP)
```

### `JSONString()`

```swift
public func JSONString() throws -> String
```

### `end()`

```swift
public func end()
```

Updates `endTime` of the Segment.

### `beginSubsegment(name:metadata:)`

```swift
public func beginSubsegment(name: String, metadata: XRayRecorder.Segment.Metadata? = nil) -> XRayRecorder.Segment
```

### `setError(_:)`

```swift
public func setError(_ error: Error)
```

### `setAnnotation(_:value:)`

```swift
public func setAnnotation(_ key: String, value: Bool)
```

### `setAnnotation(_:value:)`

```swift
public func setAnnotation(_ key: String, value: Int)
```

### `setAnnotation(_:value:)`

```swift
public func setAnnotation(_ key: String, value: Float)
```

### `setAnnotation(_:value:)`

```swift
public func setAnnotation(_ key: String, value: String)
```

### `setMetadata(_:)`

```swift
public func setMetadata(_ newElements: Metadata)
```

### `encode(to:)`

```swift
public func encode(to encoder: Encoder) throws
```

#### Parameters

| Name | Description |
| ---- | ----------- |
| encoder | The encoder to write data to. |