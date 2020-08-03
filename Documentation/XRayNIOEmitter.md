# XRayNIOEmitter

A `SwiftNIO` `XRayEmitter`.

``` swift
public protocol XRayNIOEmitter:​ XRayEmitter
```

## Inheritance

[`XRayEmitter`](/XRayEmitter)

## Requirements

## flush(on:​)

Sends pending `XRayRecorder.Segment`s in `SwiftNIO` future.

``` swift
func flush(on eventLoop:​ EventLoop?) -> EventLoopFuture<Void>
```

### Parameters

  - eventLoop:​ - eventLoop:​ `EventLoop` used to "do the flushing".
