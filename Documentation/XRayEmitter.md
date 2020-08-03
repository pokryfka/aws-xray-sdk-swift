# XRayEmitter

A type representing the ability to emit `XRayRecorder.Segment`.

``` swift
public protocol XRayEmitter
```

## Requirements

## send(\_:​)

Sends `XRayRecorder.Segment`.
Should **NOT** be blocking.

``` swift
func send(_ segment:​ XRayRecorder.Segment)
```

Emitter may choose to postpone the operation and send `XRayRecorder.Segment`s in batches.

### Parameters

  - segment:​ - segment:​ segment

## flush(\_:​)

Sends pending `XRayRecorder.Segment`s,
May be blocking.

``` swift
func flush(_ callback:​ @escaping (Error?) -> Void)
```

### Parameters

  - callback:​ - callback:​ callback with error if the operation failed.
