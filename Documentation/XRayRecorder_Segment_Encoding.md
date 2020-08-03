# XRayRecorder.Segment.Encoding

``` swift
public struct Encoding
```

## Initializers

### `init(encode:​)`

``` swift
public init(encode:​ @escaping (XRayRecorder.Segment) throws -> String)
```

## Properties

### `encode`

How to encode a segment to JSON string.

``` swift
let encode:​ (XRayRecorder.Segment) throws -> String
```
