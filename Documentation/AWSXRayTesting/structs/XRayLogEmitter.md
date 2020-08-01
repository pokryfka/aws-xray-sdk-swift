**STRUCT**

# `XRayLogEmitter`

```swift
public struct XRayLogEmitter: XRayEmitter
```

"Emits" segments by logging them using provided logger instance.

## Methods
### `init(logger:encoding:)`

```swift
public init(logger: Logger, encoding: XRayRecorder.Segment.Encoding? = nil)
```

### `init(label:encoding:)`

```swift
public init(label: String? = nil, encoding: XRayRecorder.Segment.Encoding? = nil)
```

### `send(_:)`

```swift
public func send(_ segment: XRayRecorder.Segment)
```

### `flush(_:)`

```swift
public func flush(_: @escaping (Error?) -> Void)
```
