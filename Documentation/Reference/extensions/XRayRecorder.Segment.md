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

### `end()`

```swift
public func end()
```

Updates `endTime` of the Segment.

### `beginSubsegment(name:metadata:)`

```swift
public func beginSubsegment(name: String, metadata: XRayRecorder.Segment.Metadata? = nil) -> XRayRecorder.Segment
```

### `setException(message:type:)`

```swift
public func setException(message: String, type: String? = nil)
```

### `setError(_:)`

```swift
public func setError(_ error: Error)
```

### `setAnnotation(_:forKey:)`

```swift
public func setAnnotation(_ value: String, forKey key: String)
```

### `setAnnotation(_:forKey:)`

```swift
public func setAnnotation(_ value: Bool, forKey key: String)
```

### `setAnnotation(_:forKey:)`

```swift
public func setAnnotation(_ value: Int, forKey key: String)
```

### `setAnnotation(_:forKey:)`

```swift
public func setAnnotation(_ value: Double, forKey key: String)
```

### `setMetadata(_:)`

```swift
public func setMetadata(_ newElements: Metadata)
```

### `setMetadata(_:forKey:)`

```swift
public func setMetadata(_ value: AnyEncodable, forKey key: String)
```

### `appendMetadata(_:forKey:)`

```swift
public func appendMetadata(_ value: AnyEncodable, forKey key: String)
```

### `encode(to:)`

```swift
public func encode(to encoder: Encoder) throws
```

#### Parameters

| Name | Description |
| ---- | ----------- |
| encoder | The encoder to write data to. |