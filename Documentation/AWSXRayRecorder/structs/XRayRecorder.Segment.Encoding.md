**STRUCT**

# `XRayRecorder.Segment.Encoding`

```swift
public struct Encoding
```

## Properties
### `encode`

```swift
public let encode: (XRayRecorder.Segment) throws -> String
```

How to encode a segment to JSON string.

## Methods
### `init(encode:)`

```swift
public init(encode: @escaping (XRayRecorder.Segment) throws -> String)
```
