**PROTOCOL**

# `XRayEmitter`

```swift
public protocol XRayEmitter
```

## Methods
### `send(_:)`

```swift
func send(_ segment: XRayRecorder.Segment)
```

### `flush(_:)`

```swift
func flush(_ callback: @escaping (Error?) -> Void)
```
