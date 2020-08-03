# XRayUDPEmitter

Send `XRayRecorder.Segment`s to the X-Ray daemon, which will buffer them and upload to the X-Ray API in batches.
The X-Ray SDK sends segment documents to the daemon to avoid making calls to AWS directly.

``` swift
public class XRayUDPEmitter:​ XRayNIOEmitter
```

The IP address and port of the X-Ray daemon is configured using `AWS_XRAY_DAEMON_ADDRESS` environment variable, `127.0.0.1:​2000` by default.

# References

  - [Sending segment documents to the X-Ray daemon](https:​//docs.aws.amazon.com/xray/latest/devguide/xray-api-sendingdata.html#xray-api-daemon)

## Inheritance

[`XRayNIOEmitter`](/XRayNIOEmitter)

## Initializers

### `init(encoding:​eventLoopGroupProvider:​config:​)`

Creates an instance of `XRayUDPEmitter`.

``` swift
public convenience init(encoding:​ XRayRecorder.Segment.Encoding, eventLoopGroupProvider:​ EventLoopGroupProvider = .createNew, config:​ Config = Config()) throws
```

#### Parameters

  - encoding:​ - encoding:​ Contains encoder used to encode `XRayRecorder.Segment` to JSON string.
  - eventLoopGroupProvider:​ - eventLoopGroupProvider:​ Specifies how `EventLoopGroup` will be created and establishes lifecycle ownership.
  - config:​ - config:​ configuration, **overrides** enviromental variables.

#### Throws

may throw if the UDP Daemon endpoint cannot be parsed.

## Methods

### `send(_:​)`

``` swift
public func send(_ segment:​ XRayRecorder.Segment)
```

### `flush(_:​)`

``` swift
public func flush(_ callback:​ @escaping (Error?) -> Void)
```

### `flush(on:​)`

``` swift
public func flush(on eventLoop:​ EventLoop? = nil) -> EventLoopFuture<Void>
```
