# XRayLogEmitter

"Emits" segments by logging them using provided logger instance.

``` swift
public struct XRayLogEmitter:​ XRayEmitter
```

## Inheritance

[`XRayEmitter`](/XRayEmitter)

## Initializers

### `init(logger:​encoding:​)`

``` swift
public init(logger:​ Logger, encoding:​ XRayRecorder.Segment.Encoding? = nil)
```

### `init(label:​encoding:​)`

``` swift
public init(label:​ String? = nil, encoding:​ XRayRecorder.Segment.Encoding? = nil)
```

## Methods

### `send(_:​)`

``` swift
public func send(_ segment:​ XRayRecorder.Segment)
```

### `flush(_:​)`

``` swift
public func flush(_:​ @escaping (Error?) -> Void)
```
