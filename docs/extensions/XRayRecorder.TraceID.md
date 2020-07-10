**EXTENSION**

# `XRayRecorder.TraceID`
```swift
extension XRayRecorder.TraceID: Hashable
```

## Methods
### `hash(into:)`

```swift
public func hash(into hasher: inout Hasher)
```

#### Parameters

| Name | Description |
| ---- | ----------- |
| hasher | The hasher to use when combining the components of this instance. |

### `encode(to:)`

```swift
public func encode(to encoder: Encoder) throws
```

#### Parameters

| Name | Description |
| ---- | ----------- |
| encoder | The encoder to write data to. |

### `init()`

```swift
public init()
```

Creates new Trace ID.
