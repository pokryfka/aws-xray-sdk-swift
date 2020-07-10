**STRUCT**

# `XRayLogEmitter`

```swift
public struct XRayLogEmitter: XRayEmitter
```

## Methods
### `init(label:)`

```swift
public init(label: String? = nil)
```

### `send(_:)`

```swift
public func send(_ segment: XRayRecorder.Segment)
```

### `flush(_:)`

```swift
public func flush(_: @escaping (Error?) -> Void)
```
