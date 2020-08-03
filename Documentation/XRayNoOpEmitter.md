# XRayNoOpEmitter

Implements `XRayEmitter` which does not do anything.

``` swift
public struct XRayNoOpEmitter:​ XRayEmitter
```

## Inheritance

[`XRayEmitter`](/XRayEmitter)

## Initializers

### `init()`

``` swift
public init()
```

## Methods

### `send(_:​)`

``` swift
public func send(_:​ XRayRecorder.Segment)
```

### `flush(_:​)`

``` swift
public func flush(_:​ @escaping (Error?) -> Void)
```
